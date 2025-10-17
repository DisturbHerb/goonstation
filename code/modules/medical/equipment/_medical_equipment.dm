/**
 * # /datum/medical_equipment
 *
 * Adding this datum to an `/obj` allows it to (dis)connect and manage patients, applying any effects tied to `src.functions` on a
 * `src.effect()` call if the patient is withing interaction range of the object.
 *
 * This datum handles:
 * - Connection and disconnection of patients to medical equipment, either by a user or (forcefully disconnecting) when the patient is out of
 *   interaction range.
 * - Application of effects to a connected patient based off of `src.function`.
 * - Harmonization of subordinate and superior `/datum/medical_equipment` instances.
 * 		- Primary use-case is for attaching pieces of medical equipment which can normally be used independently to another piece of medical
 * 		  equipment so that the subordinate's patient and effects can be handled by a superior. See IV stands and IV drips for an example.
 * - Chat log feedback to the user for patient connection interactions.
 *
 * This was created to unify the shared behaviours between the dialysis machine, IV stands, and IV drips; subsequently allowing for the easy creation
 * of future medical objects sharing similar behaviour.
 */
/datum/medical_equipment
	/// The object using this datum to manage patient connections and effects.
	var/tmp/obj/equipment_obj = null
	/// Determines the effects applied by this equipment on the patient. Can be null if adding subordinate equipment instances.
	/// TBD: Convert to allowing multiple different functions which may be able to operate independently of each other.
	var/tmp/datum/medical_equipment_function/function = null
	/// The `/mob/living/carbon` that this equipment is effecting. Must stay within range.
	var/tmp/mob/living/carbon/patient = null
	/// If `FALSE`, don't add this to `global.processing_items`.
	var/tmp/use_processing_items = TRUE
	/// Is this equipment currently effecting a patient?
	var/tmp/active = FALSE
	/// Is `src.equipment_obj` able to draw enough power?
	var/tmp/powered = FALSE
	/// Is this equipment broken and unusable?
	var/tmp/broken = FALSE
	/// Is this EMAG'd?
	var/tmp/hacked = FALSE
	/// If `TRUE` and `src.check_effect_fail()` returns a failure reason, refuse to connect.
	var/tmp/check_can_effect_before_connect = FALSE
	/// Connection actionbar length.
	var/tmp/connect_time = 3 SECONDS
	/// `/datum/statusEffect/medical_equipment` ID associated with this equipment.
	var/tmp/connect_status_effect = "medical_equipment"
	/// If subordinate to another `/datum/medical_equipment/`, `src` will hand over patient management and effect application.
	var/tmp/datum/medical_equipment/superior = null
	/// If superior to another `/datum/medical_equipment/`, `src` will take over patient management and effect application.
	var/tmp/list/subordinates = null

/*
 * Initialisation and boilerplate
 */
/datum/medical_equipment/New(obj/equipment_obj, connect_time, function, function_params, use_processing_items = TRUE)
	..()
	src.equipment_obj = equipment_obj
	if (!isobj(src.equipment_obj))
		CRASH("[src] tried to instantiate with a equipment_obj ([equipment_obj]) that wasn't an object!")
	if (isnum_safe(connect_time) && (connect_time >= 0))
		src.connect_time = connect_time
	if (length(function))
		var/datum/medical_equipment_function/function_instance = new function(src, function_params)
		if (!istype(function_instance, /datum/medical_equipment_function))
			CRASH("[src] tried to instantiate an invalid /datum/medical_equipment_function/ type ([function], params: [english_list(function_params)])!")
		src.function = function_instance
	if (!use_processing_items)
		src.use_processing_items = FALSE

	RegisterSignals(src.equipment_obj, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	if (isitem(src.equipment_obj))
		RegisterSignal(src.equipment_obj, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))

/datum/medical_equipment/disposing()
	src.remove_superior()
	src.clear_subordinates()
	src.equipment_obj = null
	src.patient = null
	..()

/datum/medical_equipment/proc/mouse_drop(mob/user, mob/living/carbon/target)
	if (!iscarbon(target))
		return
	if (!src.can_interact(user, target))
		return
	if (target == src.patient)
		src.remove_patient(user)
		return
	src.attempt_add_patient(user, target)

/*
 * Equipment hierarchy management
 */
/datum/medical_equipment/proc/add_subordinate(datum/medical_equipment/new_subordinate)
	if (!istype(new_subordinate, /datum/medical_equipment))
		return
	if (new_subordinate.superior)
		new_subordinate.superior.remove_subordinate(new_subordinate)
	new_subordinate.superior = src
	new_subordinate.set_inactive()

/datum/medical_equipment/proc/remove_subordinate(datum/medical_equipment/old_subordinate)
	if (!istype(old_subordinate, /datum/medical_equipment))
		return
	if (!(old_subordinate in src.subordinates))
		return
	src.subordinates -= old_subordinate
	old_subordinate.superior = null

/datum/medical_equipment/proc/clear_subordinates()
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		src.remove_subordinate(subordinate)
	src.subordinates = list()

/datum/medical_equipment/proc/add_superior(datum/medical_equipment/new_superior)
	if (!istype(new_superior, /datum/medical_equipment))
		return
	new_superior.add_subordinate(src)

/datum/medical_equipment/proc/remove_superior()
	src.superior.remove_subordinate(src)

/*
 * Interaction and connection checks
 */
/// Is a connection (to an object or patient) possible?
/datum/medical_equipment/proc/can_connect(mob/living/carbon/connectee, mob/connector)
	. = FALSE
	// Assume connectee is current patient if not given.
	if (!connectee)
		connectee = src.patient
	if (!iscarbon(connectee))
		return
	if (!src.can_interact(connectee, connector))
		return
	// If being pushed/pulled by `src.patient`, check if either the previous or current position of whatever moved is in range of whatever follows.
	if (connectee != src.patient)
		return
	if ((src.patient.pushing != src) && (src.patient.pulling != src))
		return
	if (src.can_push_or_pull())
		. = TRUE

/// Check that `src.equipment_obj` and target are in range. If there's a user, check that they're able to act and in range.
/datum/medical_equipment/proc/can_interact(atom/target, mob/user)
	. = FALSE
	if (in_interact_range(target, src.equipment_obj))
		. = TRUE
	if (!user)
		return
	. = FALSE
	if (!ismob(user) || !can_act(user))
		return
	if (in_interact_range(src.equipment_obj, user) && in_interact_range(target, user))
		. = TRUE

/// Tests for pushing and pulling. Nasty. `TRUE` if connection can be maintained during pull/push.
/datum/medical_equipment/proc/can_push_or_pull()
	. = FALSE
	if (!src.patient)
		return
	var/atom/movable/leader
	var/atom/movable/follower
	if (src.patient.pulling == src)
		leader = src.patient
		follower = src
	if (src.patient.pushing == src)
		leader = src
		follower = src.patient
	if (!ismovable(leader, follower))
		return
	// Don't bother if neither the lead or follow are within pushing/pulling distance.
	if (GET_MANHATTAN_DIST(leader, follower) > 2)
		return
	var/atom/new_leader_loc = leader.loc
	var/atom/old_leader_loc = get_step(new_leader_loc, turn(leader.last_move, 180))
	if (!BOUNDS_DIST(old_leader_loc, follower) || !BOUNDS_DIST(new_leader_loc, follower))
		. = TRUE

/// Is our connection with our current patient still good?
/datum/medical_equipment/proc/check_patient_connection()
	. = TRUE
	if (!src.patient)
		return FALSE
	if (!src.can_connect(src.patient))
		return FALSE

/*
 * Patient connection management
 */
/// When a mob attempts to connect a new patient. Applies an actionbar.
/datum/medical_equipment/proc/attempt_add_patient(mob/user, mob/living/carbon/new_patient)
	SHOULD_NOT_OVERRIDE(TRUE)
	if (!ismob(user))
		return
	if (!iscarbon(new_patient))
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] to [src.equipment_obj]!"))
		return
	if (src.patient)
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] as [src.patient] is already using [src.equipment_obj]!"))
		return
	if (src.check_can_effect_before_connect)
		var/attempt_fail_reason = src.check_effect_fail(new_patient)
		if (attempt_fail_reason)
			src.get_connect_fail_feedback(user, attempt_fail_reason)
			return
	src.attempt_message(user, new_patient)
	logTheThing(LOG_COMBAT, user, "is trying to connect [src.equipment_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	// TODO UNIQUE ACTIONBAR
	var/icon/actionbar_icon = getFlatIcon(src.equipment_obj)
	SETUP_GENERIC_ACTIONBAR(user, src, src.connect_time, PROC_REF(add_patient), list(new_patient, user), actionbar_icon, null, null, null)

/// Sets target carbon as current patient.
/datum/medical_equipment/proc/add_patient(mob/living/carbon/new_patient, mob/user)
	if (!iscarbon(new_patient))
		return
	src.patient = new_patient
	src.start_effect()
	if (ismob(user))
		src.add_message(user, new_patient)
		logTheThing(LOG_COMBAT, user, "connected [src.equipment_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	if (!length(src.patient.getStatusList(src.connect_status_effect, src)))
		src.patient.setStatus(src.connect_status_effect, INFINITE_STATUS, src)
	RegisterSignals(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	if (src.use_processing_items)
		global.processing_items |= src
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		subordinate.add_patient(new_patient)

/// Removes current patient, optionally by `mob/user`.
/datum/medical_equipment/proc/remove_patient(mob/user, force = FALSE)
	if (force)
		src.force_remove_feedback()
		src.force_remove_consequences()
	else if (ismob(user))
		src.remove_message(user)
		logTheThing(LOG_COMBAT, user, "disconnected [src] from [constructTarget(src.patient, "combat")] at [log_loc(user)].")
	src.stop_effect()
	for (var/datum/statusEffect/equipment_status_effect as anything in src.patient.getStatusList(src.connect_status_effect, src))
		src.patient.delStatus(equipment_status_effect)
	UnregisterSignal(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC))
	src.patient = null
	global.processing_items -= src
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		subordinate.remove_patient()

/// Called when `src.patient` or `src.equipment_object` moves.
/datum/medical_equipment/proc/on_move()
	if (!src.check_patient_connection() && src.patient)
		src.remove_patient(force = TRUE)

/*
 * Chat log feedback
 */
/// Feedback on (a user) attempting to connect a patient.
/datum/medical_equipment/proc/attempt_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.equipment_obj] to [new_patient]."),\
		SPAN_NOTICE("You begin connecting [src.equipment_obj] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.equipment_obj] to you."))

/// Feedback on (a user) successfully connecting a patient.
/datum/medical_equipment/proc/add_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> connects [src.equipment_obj] to [new_patient]."),\
		SPAN_NOTICE("You connect [src.equipment_obj] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> connects [src.equipment_obj] to you."))

/// Feedback on (a user) disconencting a patient.
/datum/medical_equipment/proc/remove_message(mob/user)
	user.tri_message(src.patient,\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.equipment_obj] from [src.patient]."),\
		SPAN_NOTICE("You disconnect [src.equipment_obj] from [src.patient == user ? "yourself" : src.patient]."),\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.equipment_obj] from you."))

/// Feedback on the forceful disconnection of a patient.
/datum/medical_equipment/proc/force_remove_feedback()
	src.patient.visible_message(\
		SPAN_ALERT("<b>[src.equipment_obj] is forcefully disconnected from [src.patient]!</b>"),\
		SPAN_ALERT("<b>[src.equipment_obj] is forcefully disconnected from you!</b>"))

/datum/medical_equipment/proc/get_connect_fail_feedback(mob/user, mob/living/carbon/target, reason = MED_EQUIPMENT_FAILURE)
	var/output = src.function?.connect_fail_feedback(user, target, reason)
	if (!length(output))
		return
	boutput(user, SPAN_ALERT(output))

/*
 * Function effect application
 */
/// Returns null if we can effect a patient. Returns the reason if it cannot.
/datum/medical_equipment/proc/check_effect_fail(mob/living/carbon/target)
	SHOULD_CALL_PARENT(TRUE)
	if (!iscarbon(target))
		target = src.patient
	if (!target)
		return MED_EQUIPMENT_NO_PATIENT
	if (src.broken)
		return MED_EQUIPMENT_BROKEN
	var/function_effect_fail = src.function?.check_effect_fail(target)
	if (function_effect_fail)
		return function_effect_fail
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		var/subordinate_effect_fail = subordinate.check_effect_fail(target)
		if (subordinate_effect_fail)
			return subordinate_effect_fail

/datum/medical_equipment/proc/set_active()
	if (src.active)
		return
	src.active = TRUE

/datum/medical_equipment/proc/set_inactive()
	if (!src.active)
		return
	src.active = FALSE

/datum/medical_equipment/proc/start_effect()
	if (src.superior || src.active)
		return
	var/start_fail_reason = src.check_effect_fail()
	if (start_fail_reason)
		SEND_SIGNAL(src.equipment_obj, COMSIG_MED_EQUIP_START_FAIL, list(MED_EQUIPMENT_FAIL_REASON = start_fail_reason))
		return
	src.set_active()
	SEND_SIGNAL(src.equipment_obj, COMSIG_MED_EQUIP_START)

/// **Only call this from `src.equipment_obj`!**
/datum/medical_equipment/proc/process(mult)
	if (src.superior || src.broken)
		return
	if (!src.active)
		if (src.powered)
			src.start_effect()
		return
	var/effect_fail_reason = src.check_effect_fail()
	if (effect_fail_reason)
		src.stop_effect(effect_fail_reason)
		return
	src.effect(mult)

/datum/medical_equipment/proc/effect(mult)
	if (!src.active)
		return
	src.function?.effect(mult)

/datum/medical_equipment/proc/stop_effect(reason = MED_EQUIPMENT_FAILURE)
	if (!src.active)
		return
	SEND_SIGNAL(src.equipment_obj, COMSIG_MED_EQUIP_STOP, list(MED_EQUIPMENT_FAIL_REASON = reason))
	src.set_inactive()

/datum/medical_equipment/proc/force_remove_consequences()
	src.function?.force_remove_consequence()
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		subordinate.force_remove_consequences()

/*
 * Function effect management
 */
/// Applicable if `src.equipment_obj` is an item.
/datum/medical_equipment/proc/on_attack_self(mob/user)
	if (!ismob(user))
		return
	if (!isitem(src.equipment_obj))
		return
	if (!(src.equipment_obj in user))
		return
	src.function?.on_attack_self(user)

/datum/medical_equipment/proc/hack()
	. = FALSE
	if (src.hacked)
		return
	if (src.function?.hack())
		src.hacked = TRUE
		. = TRUE

/*
 * Power management
 */
/datum/medical_equipment/proc/on_power_change()
	if (!istype(src.equipment_obj, /obj/machinery))
		return
	var/obj/machinery/machinery_obj = src.equipment_obj
	if (machinery_obj.has_no_power())
		src.on_power_loss()
		return
	src.on_power_restore()

/datum/medical_equipment/proc/on_power_loss()
	src.powered = FALSE
	src.function?.on_power_loss()
	if (src.function?.requires_power && src.active)
		src.stop_effect(MED_EQUIPMENT_NO_POWER)
	else
		SEND_SIGNAL(src.equipment_obj, COMSIG_MED_EQUIP_NO_POWER)

/datum/medical_equipment/proc/on_power_restore()
	src.powered = TRUE
	src.function?.on_power_restore()
	if (src.active)
		return
	if (!src.check_effect_fail())
		src.start_effect()

/**
 * # /datum/medical_equipment
 */
/datum/medical_equipment
	/// The object using this datum to manage patient connections and effects.
	var/tmp/obj/attached_obj = null
	/// List of `/datum/medical_equipment_function` instances tied to this equipment.
	var/tmp/list/functions = list()
	/// The `/mob/living/carbon` that this equipment is affecting. Must stay within range.
	var/tmp/mob/living/carbon/patient = null
	/// Is this equipment currently affecting a patient?
	var/tmp/active = FALSE
	/// Is `src.attached_obj` able to draw enough power?
	var/tmp/powered = FALSE
	/// Is this equipment broken and unusable?
	var/tmp/broken = FALSE
	/// Is this EMAG'd?
	var/tmp/hacked = FALSE
	/// Connection actionbar length.
	var/tmp/connect_time = 3 SECONDS
	/// `/datum/statusEffect/medical_equipment` ID associated with this equipment.
	var/tmp/connect_status_effect = "medical_equipment"
	/// If subordinate to another `/datum/medical_equipment/`, `src` will hand over patient management and effect application.
	var/tmp/datum/medical_equipment/superior = null
	/// If superior to another `/datum/medical_equipment/`, `src` will take over patient management and effect application.
	var/tmp/list/subordinates = null

/datum/medical_equipment/New(obj/attached_obj, connect_time, functions)
	..()
	src.attached_obj == attached_obj
	if (!isobj(src.attached_obj))
		CRASH("[src] tried to instantiate with a attached_obj ([attached_obj]) that wasn't an object!")
	if (isnum_safe(connect_time) && (connect_time >= 0))
		src.connect_time = connect_time
	for (var/function_type in functions)
		var/datum/medical_equipment_function/function = new function_type
		if (!istype(function, /datum/medical_equipment_function/))
			continue
		src.functions += function

/datum/medical_equipment/proc/mouse_drop(mob/user, mob/living/carbon/target)
	if (!iscarbon(target))
		return
	if (!src.can_interact(user, target))
		return
	if (target == src.patient)
		src.remove_patient(user)
		return
	src.attempt_add_patient(user, target)

/datum/medical_equipment/proc/can_interact(mob/living/user, atom/target)
	. = TRUE
	if (!isliving(user))
		return FALSE
	if (isintangible(user))
		return FALSE
	if (!can_act(user))
		return FALSE
	if (!in_interact_range(src, user))
		return FALSE
	if (!in_interact_range(target, user))
		return FALSE

/// Is a connection (to an object or patient) possible?
/datum/medical_equipment/proc/can_connect(mob/living/carbon/connectee, mob/connector)
	. = FALSE
	if (!iscarbon(connectee))
		return
	if (ismob(connector) && !in_interact_range(src, connector))
		return
	if (in_interact_range(src, connectee))
		. = TRUE
	// If being pushed/pulled by `src.patient`, check if either the previous or current position of whatever moved is in range of whatever follows.
	if (connectee != src.patient)
		return
	if ((src.patient.pushing != src) && (src.patient.pulling != src))
		return
	if (src.can_push_or_pull())
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

/// Can we actually impart an effect onto our patient?
/datum/medical_equipment/proc/can_affect()
	. = TRUE
	if (!src.patient)
		return FALSE
	if (src.broken)
		return FALSE
	for (var/datum/medical_equipment_function/function as anything in src.functions)
		if (!function.can_affect())
			return FALSE
	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
		if (!subordinate.can_affect())
			return FALSE

/// When a mob attempts to connect a new patient. Applies an actionbar.
/datum/medical_equipment/proc/attempt_add_patient(mob/user, mob/living/carbon/new_patient)
	if (!ismob(user))
		return
	if (!iscarbon(new_patient))
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] to [src.attached_obj]!"))
		return
	if (src.patient)
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] as [src.patient] is already using [src.attached_obj]!"))
		return
	if (!src.can_connect(new_patient, user))
		boutput(user, SPAN_ALERT("[src] is too far away to connect anybody!"))
		return
	src.attempt_message(user, new_patient)
	logTheThing(LOG_COMBAT, user, "is trying to connect [src.attached_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	var/icon/actionbar_icon = getFlatIcon(src.attached_obj)
	SETUP_GENERIC_ACTIONBAR(user, src.attached_obj, src.connect_time, PROC_REF(add_patient), list(new_patient, user), actionbar_icon, null, null, null)

/datum/medical_equipment/proc/add_patient(mob/living/carbon/new_patient, mob/user)
	if (!iscarbon(new_patient))
		return
	src.patient = new_patient
	src.start_affect()
	if (ismob(user))
		src.add_message(user, new_patient)
		logTheThing(LOG_COMBAT, user, "connected [src.attached_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	if (!length(src.patient.getStatusList(src.connect_status_effect, src)))
		src.patient.setStatus(src.connect_status_effect, INFINITE_STATUS, src)
	RegisterSignals(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))

/datum/medical_equipment/proc/on_move()
	if (!src.check_connection() && src.patient)
		src.remove_patient(force = TRUE)

/datum/medical_equipment/proc/remove_patient(mob/user, force = FALSE)
	if (force)
		src.force_remove_feedback()
	else if (ismob(user))
		src.remove_message(user)
		logTheThing(LOG_COMBAT, user, "disconnected [src] from [constructTarget(src.patient, "combat")] at [log_loc(user)].")
	src.stop_affect()
	for (var/datum/statusEffect/equipment_status_effect as anything in src.patient.getStatusList(src.connect_status_effect, src))
		src.patient.delStatus(equipment_status_effect)
	UnregisterSignal(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC))
	src.patient = null

/// Feedback on (a user) attempting to connect a patient.
/datum/medical_equipment/proc/attempt_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.attached_obj] to [new_patient]."),\
		SPAN_NOTICE("You begin connecting [src.attached_obj] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.attached_obj] to you."))

/// Feedback on (a user) successfully connecting a patient.
/datum/medical_equipment/proc/add_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> connects [src.attached_obj] to [new_patient]."),\
		SPAN_NOTICE("You connect [src.attached_obj] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> connects [src.attached_obj] to you."))

/// Feedback on (a user) disconencting a patient.
/datum/medical_equipment/proc/remove_message(mob/user)
	user.tri_message(src.patient,\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.attached_obj] from [src.patient]."),\
		SPAN_NOTICE("You disconnect [src.attached_obj] from [src.patient == user ? "yourself" : src.patient]."),\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.attached_obj] from you."))

/// Feedback on the forceful disconnection of a patient.
/datum/medical_equipment/proc/force_remove_feedback()
	src.patient.visible_message(\
		SPAN_ALERT("<b>[src.attached_obj] is forcefully disconnected from [src.patient]!</b>"),\
		SPAN_ALERT("<b>[src.attached_obj] is forcefully disconnected from you!</b>"))

/// For equipments that connect directly to patients: is our connection still good?
/datum/medical_equipment/proc/check_connection()
	. = TRUE
	if (!src.patient)
		return FALSE
	if (!src.can_connect())
		return FALSE

/datum/medical_equipment/proc/set_active()
	SHOULD_CALL_PARENT(TRUE)
	if (src.active)
		return
	src.active = TRUE

/datum/medical_equipment/proc/set_inactive()
	SHOULD_CALL_PARENT(TRUE)
	if (!src.active)
		return
	src.active = FALSE

/datum/medical_equipment/proc/start_affect()
	if (src.active)
		return
	if (!src.can_affect())
		return
	src.set_active()

/datum/medical_equipment/proc/affect_patient(mult)
	if (!src.active)
		return

/datum/medical_equipment/proc/stop_affect(reason = MED_equipment_FAILURE)
	if (!src.active)
		return
	if (src.patient)
		// src.stop_feedback(reason)
	src.set_inactive()

/datum/medical_equipment/proc/subordinate(/datum/medical_equipment/new_superior)
	if (!istype(new_superior, /datum/medical_equipment))
		return
	new_superior.subordinates += src
	// TODO send some signal
	src.set_inactive()

/datum/medical_equipment/proc/clear_superior()
	// TODO send some signal
	src.superior = null

/datum/medical_equipment/proc/hack()
	. = TRUE

/datum/medical_equipment/proc/power_change()
	. = TRUE

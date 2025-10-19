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
	/// If `TRUE`, failing a `src.check_effect_fail()` check will prevent you from adding the patient.
	var/tmp/check_before_attempt = FALSE
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
	/// Connection actionbar length.
	var/tmp/connect_time = 3 SECONDS
	/// `/datum/statusEffect/medical_equipment` ID associated with this equipment.
	var/tmp/connect_status_effect = "medical_equipment"
	// /// If subordinate to another `/datum/medical_equipment/`, `src` will hand over patient management and effect application.
	// var/tmp/datum/medical_equipment/superior = null
	// /// If superior to another `/datum/medical_equipment/`, `src` will take over patient management and effect application.
	// var/tmp/list/subordinates = null

/*
 * Initialisation and boilerplate
 */
/datum/medical_equipment/New(obj/equipment_obj, connect_time, function, alist/function_params, use_processing_items = TRUE, check_before_attempt = FALSE)
	..()
	src.equipment_obj = equipment_obj
	if (!isobj(src.equipment_obj))
		CRASH("[src] tried to instantiate with a equipment_obj ([equipment_obj]) that wasn't an object!")
	if (isnum_safe(connect_time) && (connect_time >= 0))
		src.connect_time = connect_time
	if (function)
		var/datum/medical_equipment_function/function_instance = new function(src, function_params)
		if (!istype(function_instance, /datum/medical_equipment_function))
			CRASH("[src] tried to instantiate an invalid /datum/medical_equipment_function/ type ([function], params: [english_list(function_params)])!")
		src.function = function_instance
	if (!use_processing_items)
		src.use_processing_items = FALSE

	RegisterSignals(src.equipment_obj, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	if (isitem(src.equipment_obj))
		RegisterSignal(src.equipment_obj, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
		RegisterSignal(src.equipment_obj, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_after_attack))

/datum/medical_equipment/disposing()
	// src.remove_superior()
	// src.clear_subordinates()
	src.equipment_obj = null
	src.patient = null
	..()

/datum/medical_equipment/proc/mouse_drop(mob/user, mob/living/carbon/target_patient)
	if (!iscarbon(target_patient))
		return
	if (!src.can_interact(user, target_patient))
		return
	if (target_patient == src.patient)
		src.remove_patient(user)
		return
	src.attempt_add_patient(user, target_patient)

/*
 * Equipment hierarchy management
 */
// /datum/medical_equipment/proc/add_subordinate(datum/medical_equipment/new_subordinate)
// 	if (!istype(new_subordinate, /datum/medical_equipment))
// 		return
// 	if (new_subordinate.superior)
// 		new_subordinate.superior.remove_subordinate(new_subordinate)
// 	new_subordinate.superior = src
// 	new_subordinate.set_inactive()

// /datum/medical_equipment/proc/remove_subordinate(datum/medical_equipment/old_subordinate)
// 	if (!istype(old_subordinate, /datum/medical_equipment))
// 		return
// 	if (!(old_subordinate in src.subordinates))
// 		return
// 	src.subordinates -= old_subordinate
// 	old_subordinate.superior = null

// /datum/medical_equipment/proc/clear_subordinates()
// 	// for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
// 	// 	src.remove_subordinate(subordinate)
// 	src.subordinates_do(clear_subordinates)
// 	src.subordinates = list()

// /datum/medical_equipment/proc/add_superior(datum/medical_equipment/new_superior)
// 	if (!istype(new_superior, /datum/medical_equipment))
// 		return
// 	new_superior.add_subordinate(src)

// /datum/medical_equipment/proc/remove_superior()
// 	src.superior.remove_subordinate(src)

// /// Make `src`'s subordinates call the same proc with the same arguments and get proc return values as alist.
// /datum/medical_equipment/proc/subordinates_do(proc_name, list/proc_arguments)
// 	if (!length(proc_name))
// 		CRASH("Cannot pass no-length proc to \ref[src]'s subordinates!")
// 	var/alist/return_values = list()
// 	var/proc_path = text2path("[src.type]/proc/[proc_name]")
// 	for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
// 		return_values["\ref[subordinate]"] = call(subordinate, proc_path)(arglist(proc_arguments))

/*
 * Interaction and connection checks
 */
/// Check that `src.equipment_obj`, `user`, and `target` are in range. `user` must also be able to act.
/datum/medical_equipment/proc/can_interact(mob/user, mob/living/carbon/target)
	. = FALSE
	if (!iscarbon(target) || !ismob(user))
		return
	if (!can_act(user))
		return
	if (global.in_interact_range(src.equipment_obj, target) && global.in_interact_range(src.equipment_obj, user) && global.in_interact_range(target, user))
		. = TRUE

/// Is the connection with our patient still good?
/datum/medical_equipment/proc/check_patient_connection()
	. = FALSE
	if (global.in_interact_range(src.patient, src.equipment_obj))
		. = TRUE
	if ((src.patient.pulling != src.equipment_obj) && (src.patient.pushing != src.equipment_obj))
		return
	if (IN_RANGE(src.patient, src.equipment_obj, 2))
		. = TRUE

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
	if (!src.function)
		boutput(user, SPAN_ALERT("You can't use [src.equipment_obj] on its own!"))
		return
	if (src.check_before_attempt)
		var/attempt_fail_reason = src.check_effect_fail(new_patient)
		if (attempt_fail_reason)
			src.attempt_fail_feedback(user, new_patient, attempt_fail_reason)
			return
	src.attempt_message(user, new_patient)
	logTheThing(LOG_COMBAT, user, "is trying to connect [src.equipment_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	global.actions.start(new /datum/action/bar/icon/med_equipment_add_patient(src, user, new_patient, src.connect_time), user)

/// Sets target carbon as current patient.
/datum/medical_equipment/proc/add_patient(mob/living/carbon/new_patient, mob/user)
	if (!iscarbon(new_patient))
		return
	src.patient = new_patient
	src.function?.patient = src.patient
	src.start_effect()
	if (ismob(user))
		src.add_message(user, new_patient)
		logTheThing(LOG_COMBAT, user, "connected [src.equipment_obj] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	if (!length(src.patient.getStatusList(src.connect_status_effect, src)))
		src.patient.setStatus(src.connect_status_effect, INFINITE_STATUS, src)
	RegisterSignals(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	if (src.use_processing_items)
		global.processing_items |= src
	// for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
	// 	subordinate.add_patient(new_patient)


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
	src.function?.patient = null
	global.processing_items -= src
	// for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
	// 	subordinate.remove_patient()

/// Called when `src.patient` or `src.equipment_object` moves.
/datum/medical_equipment/proc/on_move()
	if (!src.patient)
		return
	if (!src.check_patient_connection())
		src.remove_patient(force = TRUE)

/// Applicable if `src.equipment_obj` is an item. Called on `src.equipment_obj.AfterAttack()`.
/datum/medical_equipment/proc/on_after_attack(obj/item/equipment_obj, mob/living/carbon/target, mob/user)
	if (!ismob(user) || !iscarbon(target))
		return
	if (!isitem(src.equipment_obj))
		return
	if (!(src.equipment_obj in user))
		return
	if (src.patient == target)
		src.remove_patient(user)
		return
	src.attempt_add_patient(target, user)

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

/datum/medical_equipment/proc/attempt_fail_feedback(mob/user, mob/living/carbon/target, reason = MED_EQUIPMENT_FAILURE)
	var/output = ""
	// Check equipment failure first.
	switch (reason)
		if (MED_EQUIPMENT_BROKEN)
			output = "[src.equipment_obj] is broken and can't accept a patient!"
		if (MED_EQUIPMENT_NO_POWER)
			output = "[src.equipment_obj] can't draw any power and can't accept a patient!"
	// Then check function failure.
	output = src.function?.attempt_fail_feedback(user, target, reason) || output
	if (!length(output))
		output = "[src.equipment_obj] can't accept a patient right now!"
	boutput(user, SPAN_ALERT(output))

/*
 * Function effect application
 */
/// Returns null if we can effect a patient. Returns the reason if it cannot.
/datum/medical_equipment/proc/check_effect_fail(mob/living/carbon/target_patient)
	SHOULD_CALL_PARENT(TRUE)
	if (!iscarbon(target_patient))
		target_patient = src.patient
	if (!target_patient)
		return MED_EQUIPMENT_NO_PATIENT
	if (src.broken)
		return MED_EQUIPMENT_BROKEN
	var/function_effect_fail = src.function?.check_effect_fail(target_patient)
	if (function_effect_fail)
		return function_effect_fail
	// for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
	// 	var/subordinate_effect_fail = subordinate.check_effect_fail(target_patient)
	// 	if (subordinate_effect_fail)
	// 		return subordinate_effect_fail

/datum/medical_equipment/proc/set_active()
	if (src.active)
		return
	src.active = TRUE

/datum/medical_equipment/proc/set_inactive()
	if (!src.active)
		return
	src.active = FALSE

/datum/medical_equipment/proc/start_effect()
	// if (src.superior || src.active)
	if (src.active)
		return
	var/start_fail_reason = src.check_effect_fail()
	if (start_fail_reason)
		SEND_SIGNAL(src, COMSIG_MED_EQUIP_START_FAIL, start_fail_reason)
		return
	src.set_active()
	src.function?.start_effect()
	src.effect()
	SEND_SIGNAL(src, COMSIG_MED_EQUIP_START)

/// **Only call this from `src.equipment_obj`!**
/datum/medical_equipment/proc/process(mult = 1)
	// if (src.superior || src.broken)
	if (src.broken)
		return
	if (!src.active)
		if ((src.powered && src.function?.requires_power) || src.function?.requires_power)
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
	src.set_inactive()
	src.function?.stop_effect()
	SEND_SIGNAL(src, COMSIG_MED_EQUIP_STOP, reason)

/datum/medical_equipment/proc/force_remove_consequences()
	src.function?.force_remove_consequence()
	// for (var/datum/medical_equipment/subordinate as anything in src.subordinates)
	// 	subordinate.force_remove_consequences()

/*
 * Function effect management
 */
/// Applicable if `src.equipment_obj` is an item.
/datum/medical_equipment/proc/on_attack_self(obj/item/equipment_obj, mob/user)
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
		SEND_SIGNAL(src, COMSIG_MED_EQUIP_NO_POWER)

/datum/medical_equipment/proc/on_power_restore()
	src.powered = TRUE
	src.function?.on_power_restore()
	if (src.active)
		return
	if (!src.check_effect_fail())
		src.start_effect()

/**
 * # /datum/component/medical_device
 *
 * Adding this component to an `/atom` allows it to (dis)connect and manage patients, applying any effects on a `src.effect()` call if the patient is
 * withing interaction range of the object.
 *
 * This datum handles:
 * - Connection and disconnection of patients to medical device, either by a user or (forcefully disconnecting) when the patient is out of
 *   interaction range.
 * - Application of effects to a connected patient.
 * - Chat log feedback to the user for patient connection interactions.
 *
 * This was created to unify the shared behaviours between the dialysis machine, IV stands, and IV drips; subsequently allowing for the easy creation
 * of future medical objects sharing similar behaviour.
 */
/datum/component/medical_device
	/// The `/mob/living/carbon` that this device is affecting. Must stay within range.
	var/tmp/mob/living/carbon/patient = null
	/// If `TRUE`, failing a `src.check_effect_fail()` check will prevent you from adding the patient.
	var/tmp/check_before_attempt = FALSE
	/// If `FALSE`, don't add this to `global.processing_items`.
	var/tmp/use_processing_items = TRUE
	/// For `/obj/machinery` parent: if `TRUE`, can only operate when parent `/obj/machinery/proc/powered()` returns true.
	var/tmp/requires_power = FALSE
	/// Is this device currently affecting a patient?
	var/tmp/active = FALSE
	/// Is `src.parent` able to draw enough power?
	var/tmp/powered = FALSE
	/// Is this device broken and unusable?
	var/tmp/broken = FALSE
	/// Is this EMAG'd?
	var/tmp/hacked = FALSE
	/// Connection actionbar length.
	var/tmp/connect_time = 3 SECONDS
	/// `/datum/statusEffect/medical_device` ID associated with this device.
	var/tmp/connect_status_effect = "medical_device"

/*
 * Initialisation and boilerplate
 */
/datum/component/medical_device/Initialize(connect_time, use_processing_items = TRUE, check_before_attempt = FALSE)
	..()
	if (!isatom(src.parent))
		return COMPONENT_INCOMPATIBLE
	src.connect_time = (isnum_safe(connect_time) && connect_time >= 0) && connect_time
	src.use_processing_items = use_processing_items
	src.check_before_attempt = check_before_attempt
	RegisterSignals(src.parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	RegisterSignal(src.parent, COMSIG_ATOM_MOUSEDROP, PROC_REF(mouse_drop))
	if (isitem(src.parent))
		RegisterSignal(src.parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
		RegisterSignal(src.parent, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_after_attack))

/datum/component/medical_device/UnregisterFromParent()
	src.patient = null
	..()

/datum/component/medical_device/proc/mouse_drop(atom/parent, mob/user, mob/living/carbon/target_patient)
	if (!iscarbon(target_patient))
		return
	if (!src.can_interact(user, target_patient))
		return
	if (target_patient == src.patient)
		src.remove_patient(user)
		return
	src.attempt_add_patient(user, target_patient)

/// Applicable if `src.parent` is an item.
/datum/component/medical_device/proc/on_attack_self(obj/item/parent, mob/user)
	if (!ismob(user))
		return
	if (!isitem(src.parent))
		return
	if (!(src.parent in user))
		return

/// Applicable if `src.parent` is an item.
/datum/component/medical_device/proc/on_after_attack(obj/item/parent, mob/living/carbon/target, mob/user)
	if (!ismob(user) || !iscarbon(target))
		return
	if (!isitem(src.parent))
		return
	if (user.equipped() != src.parent)
		return
	if (src.patient == target)
		src.remove_patient(user)
		return
	src.attempt_add_patient(target, user)

/datum/component/medical_device/proc/hack()
	. = FALSE
	if (src.hacked)
		return
	src.hacked = TRUE
	. = TRUE

/*
 * Interaction and connection checks
 */
/// Check that `src.parent`, `user`, and `target` are in range. `user` must also be able to act.
/datum/component/medical_device/proc/can_interact(mob/user, mob/living/carbon/target)
	. = FALSE
	if (!iscarbon(target) || !ismob(user))
		return
	if (!can_act(user))
		return
	if (global.in_interact_range(src.parent, target) && global.in_interact_range(src.parent, user) && global.in_interact_range(target, user))
		. = TRUE

/// Is the connection with our patient still good?
/datum/component/medical_device/proc/check_patient_connection()
	. = FALSE
	if (global.in_interact_range(src.patient, src.parent))
		. = TRUE
	if ((src.patient.pulling != src.parent) && (src.patient.pushing != src.parent))
		return
	if (IN_RANGE(src.patient, src.parent, 2))
		. = TRUE

/*
 * Patient connection management
 */
/// When a mob attempts to connect a new patient. Applies an actionbar.
/datum/component/medical_device/proc/attempt_add_patient(mob/user, mob/living/carbon/new_patient)
	SHOULD_NOT_OVERRIDE(TRUE)
	if (!ismob(user))
		return
	if (!iscarbon(new_patient))
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] to [src.parent]!"))
		return
	if (src.patient)
		boutput(user, SPAN_ALERT("Unable to connect [new_patient] as [src.patient] is already using [src.parent]!"))
		return
	if (src.check_before_attempt)
		var/attempt_fail_reason = src.check_effect_fail(new_patient)
		if (attempt_fail_reason)
			src.attempt_fail_feedback(user, new_patient, attempt_fail_reason)
			return
	src.attempt_message(user, new_patient)
	logTheThing(LOG_COMBAT, user, "is trying to connect [src.parent] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	global.actions.start(new /datum/action/bar/icon/med_device_add_patient(src, user, new_patient, src.connect_time), user)

/// Sets target carbon as current patient.
/datum/component/medical_device/proc/add_patient(mob/living/carbon/new_patient, mob/user)
	if (!iscarbon(new_patient))
		return
	src.patient = new_patient
	src.start_effect()
	if (ismob(user))
		src.add_message(user, new_patient)
		logTheThing(LOG_COMBAT, user, "connected [src.parent] to [constructTarget(new_patient, "combat")] at [log_loc(user)].")
	if (!length(src.patient.getStatusList(src.connect_status_effect, src)))
		src.patient.setStatus(src.connect_status_effect, INFINITE_STATUS, src)
	RegisterSignals(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC), PROC_REF(on_move))
	if (src.use_processing_items)
		global.processing_items |= src


/// Removes current patient, optionally by `mob/user`.
/datum/component/medical_device/proc/remove_patient(mob/user, force = FALSE)
	if (force)
		src.force_remove_feedback()
		src.force_remove_consequences()
	if (ismob(user))
		src.remove_message(user)
		logTheThing(LOG_COMBAT, user, "disconnected [src] from [constructTarget(src.patient, "combat")] at [log_loc(user)].")
	src.stop_effect()
	for (var/datum/statusEffect/device_status_effect as anything in src.patient.getStatusList(src.connect_status_effect, src))
		src.patient.delStatus(device_status_effect)
	UnregisterSignal(src.patient, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_SET_LOC))
	src.patient = null
	global.processing_items -= src

/// Called when `src.patient` or `src.parentect` moves.
/datum/component/medical_device/proc/on_move()
	if (!src.patient)
		return
	if (!src.check_patient_connection())
		src.remove_patient(force = TRUE)

/*
 * Chat log feedback
 */
/// Feedback on (a user) attempting to connect a patient.
/datum/component/medical_device/proc/attempt_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.parent] to [new_patient]."),\
		SPAN_NOTICE("You begin connecting [src.parent] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> begins connecting [src.parent] to you."))

/// Feedback on (a user) successfully connecting a patient.
/datum/component/medical_device/proc/add_message(mob/user, mob/living/carbon/new_patient)
	user.tri_message(new_patient,\
		SPAN_NOTICE("<b>[user]</b> connects [src.parent] to [new_patient]."),\
		SPAN_NOTICE("You connect [src.parent] to [new_patient == user ? "yourself" : new_patient]."),\
		SPAN_NOTICE("<b>[user]</b> connects [src.parent] to you."))

/// Feedback on (a user) disconencting a patient.
/datum/component/medical_device/proc/remove_message(mob/user)
	user.tri_message(src.patient,\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.parent] from [src.patient]."),\
		SPAN_NOTICE("You disconnect [src.parent] from [src.patient == user ? "yourself" : src.patient]."),\
		SPAN_NOTICE("<b>[user]</b> disconnects [src.parent] from you."))

/// Feedback on the forceful disconnection of a patient.
/datum/component/medical_device/proc/force_remove_feedback()
	src.patient.visible_message(\
		SPAN_ALERT("<b>[src.parent] is forcefully disconnected from [src.patient]!</b>"),\
		SPAN_ALERT("<b>[src.parent] is forcefully disconnected from you!</b>"))

/// Currently used exclusively by IV bags to maintain parity.
/datum/component/medical_device/proc/attempt_fail_feedback(mob/user, mob/living/carbon/target, reason = MED_DEVICE_FAILURE)
	return

/// Currently used exclusively by IV bags to maintain parity.
/datum/component/medical_device/proc/stop_effect_feedback(reason = MED_DEVICE_FAILURE)
	return

/*
 * Effect application
 */
/// Returns null if we can effect a patient. Returns the reason if it cannot.
/datum/component/medical_device/proc/check_effect_fail(mob/living/carbon/target_patient)
	SHOULD_CALL_PARENT(TRUE)
	if (!iscarbon(target_patient))
		target_patient = src.patient
	if (!target_patient)
		return MED_DEVICE_NO_PATIENT
	if (src.broken)
		return MED_DEVICE_BROKEN

/datum/component/medical_device/proc/set_active()
	if (src.active)
		return
	src.active = TRUE

/datum/component/medical_device/proc/set_inactive()
	if (!src.active)
		return
	src.active = FALSE

/datum/component/medical_device/proc/start_effect()
	if (src.active)
		return
	var/start_fail_reason = src.check_effect_fail()
	if (start_fail_reason)
		SEND_SIGNAL(src, COMSIG_MED_DEVICE_START_FAIL, start_fail_reason)
		return
	src.set_active()
	SEND_SIGNAL(src, COMSIG_MED_DEVICE_START)

/// On `src.parent` process tick.
/datum/component/medical_device/proc/process(mult = 1)
	if (src.broken)
		return
	if (!src.active)
		if (src.powered && src.requires_power)
			src.start_effect()
		return
	var/effect_fail_reason = src.check_effect_fail()
	if (effect_fail_reason)
		src.stop_effect(effect_fail_reason)
		return
	src.effect(mult)

/datum/component/medical_device/proc/effect(mult)
	SHOULD_CALL_PARENT(TRUE)
	if (!src.active)
		return

/datum/component/medical_device/proc/stop_effect(reason = MED_DEVICE_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	if (!src.active)
		return
	src.set_inactive()
	src.stop_effect_feedback(reason)
	SEND_SIGNAL(src, COMSIG_MED_DEVICE_STOP, reason)

/datum/component/medical_device/proc/force_remove_consequences()
	return

/*
 * Power management
 */
/datum/component/medical_device/proc/on_power_change()
	if (!istype(src.parent, /obj/machinery))
		return
	var/obj/machinery/machinery_obj = src.parent
	if (machinery_obj.has_no_power())
		src.on_power_loss()
		return
	src.on_power_restore()

/datum/component/medical_device/proc/on_power_loss()
	src.powered = FALSE
	if (src.requires_power && src.active)
		src.stop_effect(MED_DEVICE_NO_POWER)
	SEND_SIGNAL(src, COMSIG_MED_DEVICE_NO_POWER)

/datum/component/medical_device/proc/on_power_restore()
	src.powered = TRUE
	if (src.active)
		return
	if (!src.check_effect_fail())
		src.start_effect()

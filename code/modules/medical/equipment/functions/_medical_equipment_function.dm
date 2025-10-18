ABSTRACT_TYPE(/datum/medical_equipment_function)
/datum/medical_equipment_function
	var/datum/medical_equipment/parent = null
	var/mob/living/carbon/patient = null
	var/requires_power = FALSE

/datum/medical_equipment_function/New(datum/medical_equipment/parent, alist/params)
	SHOULD_CALL_PARENT(TRUE)
	..()
	if (!istype(parent, /datum/medical_equipment))
		CRASH("Tried to instantiate /datum/medical_equipment/function ([src]) without a valid parent ([parent])!")
	src.parent = parent

/// Returns null if we can affect a patient. Returns the reason if it cannot.
/datum/medical_equipment_function/proc/check_effect_fail(mob/living/carbon/target_patient)
	SHOULD_CALL_PARENT(TRUE)
	if (src.requires_power && !src.parent.powered)
		return MED_EQUIPMENT_NO_POWER

/// Returns feedback string on failure to connect patient.
/datum/medical_equipment_function/proc/attempt_fail_feedback(mob/user, mob/living/carbon/target_patient, reason = MED_FUNCTION_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	. = null
	if (!iscarbon(target_patient))
		return

/// Visible message feedback on ending effect.
/datum/medical_equipment_function/proc/stop_effect_feedback(reason = MED_FUNCTION_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	. = TRUE
	if (!iscarbon(src.patient))
		return FALSE

/datum/medical_equipment_function/proc/on_power_loss()
	return

/datum/medical_equipment_function/proc/on_power_restore()
	return

/// Called once when starting effect.
/datum/medical_equipment_function/proc/start_effect()
	SHOULD_CALL_PARENT(TRUE)
	. = TRUE
	if (!iscarbon(src.patient))
		return FALSE

/// Called on `src.parent.process()`.
/datum/medical_equipment_function/proc/effect(mult)
	. = TRUE
	if (!src.patient)
		return FALSE
	boutput(world, SPAN_ADMIN("[src.parent.equipment_obj] does a thing ([src.type]) to [src.patient]."))

/// Called once when ending effect.
/datum/medical_equipment_function/proc/stop_effect()
	SHOULD_CALL_PARENT(TRUE)
	src.stop_effect_feedback()

/datum/medical_equipment_function/proc/force_remove_consequence()
	SHOULD_CALL_PARENT(TRUE)
	. = TRUE
	if (!src.patient)
		return FALSE

/datum/medical_equipment_function/proc/on_attack_self(mob/user)
	return

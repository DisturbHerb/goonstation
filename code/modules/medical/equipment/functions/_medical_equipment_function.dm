ABSTRACT_TYPE(/datum/medical_equipment_function)
/datum/medical_equipment_function
	var/datum/medical_equipment/parent = null
	var/requires_power = FALSE

/datum/medical_equipment_function/New(parent, params)
	SHOULD_CALL_PARENT(TRUE)
	..()
	if (!istype(parent, /datum/medical_equipment))
		CRASH("Tried to instantiate /datum/medical_equipment/function ([src]) without a valid parent ([parent])!")
	src.parent = parent

/// Returns null if we can affect a patient. Returns the reason if it cannot.
/datum/medical_equipment_function/proc/check_effect_fail(mob/living/carbon/target)
	SHOULD_CALL_PARENT(TRUE)
	if (src.requires_power && !src.parent.powered)
		return MED_EQUIPMENT_NO_POWER

/// Returns feedback string on failure to connect patient.
/datum/medical_equipment_function/proc/connect_fail_feedback(mob/user, mob/living/carbon/target, reason = MED_FUNCTION_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	if (!iscarbon(target))
		return

/// Visible message feedback on ending effect.
/datum/medical_equipment_function/proc/end_effect_feedback(mob/living/carbon/target, reason = MED_FUNCTION_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	if (!target)
		target = src.parent.patient
	if (!iscarbon(target))
		return

/datum/medical_equipment_function/proc/on_power_loss()
	return

/datum/medical_equipment_function/proc/on_power_restore()
	return

/datum/medical_equipment_function/proc/effect(mult)
	SHOULD_CALL_PARENT(TRUE)
	. = TRUE
	if (src.check_effect_fail())
		return FALSE
	var/mob/living/carbon/patient = src.parent.patient
	boutput(world, SPAN_ADMIN("[src.parent.equipment_obj] does a thing ([src.type]) to [patient]."))

/datum/medical_equipment_function/proc/hack()
	. = FALSE

/datum/medical_equipment_function/proc/force_remove_consequence()
	SHOULD_CALL_PARENT(TRUE)
	var/mob/living/carbon/patient = src.parent.patient
	if (!patient)
		return

/datum/medical_equipment_function/proc/on_attack_self(mob/user)
	. = list()

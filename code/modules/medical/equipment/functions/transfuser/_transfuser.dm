ABSTRACT_TYPE(/datum/medical_equipment_function/transfuser)
/**
 * # `/datum/medical_equipment_function`
 *
 * Transfusing blood/reagents between a patient and a target reagent container. Contains some relevant helper procs.
 */
/datum/medical_equipment_function/transfuser
	var/datum/reagents/reservoir = null
	/// Units of fluid transferred each tick. Currently for both in and out.
	var/transfer_volume = 5

/datum/medical_equipment_function/transfuser/New(datum/reagents/reservoir)
	..()
	if (istype(reservoir, /datum/reagents))
		src.reservoir = reservoir
	else
		src.reservoir = new /datum/reagents(src.transfer_volume)

/// Draws patient blood into internal reagent container.
/datum/medical_equipment_function/transfuser/proc/handle_draw(volume, mult)
	var/mob/living/carbon/patient = src.parent.patient
	if (!patient)
		return
	if (!src.get_fluid_volume())
		return
	if (!isnum(volume))
		return
	transfer_blood(patient, src.reservoir, src.calculate_transfer_volume(src.transfer_volume, mult))

/// Infuses internal reagent container contents to patient.
/datum/medical_equipment_function/transfuser/proc/handle_infusion(volume, mult)
	var/mob/living/carbon/patient = src.parent.patient
	if (!patient)
		return
	if (!src.reservoir.total_volume)
		return
	if (!isnum(volume))
		return
	if (patient.reagents.is_full())
		return
	var/infusion_volume = src.calculate_transfer_volume(volume, mult)
	src.reservoir.trans_to(patient, infusion_volume)
	patient.reagents.reaction(patient, INGEST, infusion_volume)

/// Returns total patient blood volume in units.
/datum/medical_equipment_function/transfuser/proc/get_blood_volume(mob/living/carbon/target)
	. = 0
	if (!target)
		target = src.parent.patient
	if (!iscarbon(target))
		return
	var/datum/reagent/target_blood_reagent = target.reagents.reagent_list["blood"]
	var/target_blood_reagent_volume = target_blood_reagent?.volume || 0
	. = target.blood_volume + target_blood_reagent_volume

/// Returns total target fluid volume (blood + all reagents) in units.
/datum/medical_equipment_function/transfuser/proc/get_fluid_volume(mob/living/carbon/target)
	. = 0
	if (!target)
		target = src.parent.patient
	if (!iscarbon(target))
		return
	. = target.blood_volume + target.reagents.total_volume

/// As `mult` is given in deciseconds, it needs to be converted to seconds for transfer volume calculations.
/datum/medical_equipment_function/transfuser/proc/calculate_transfer_volume(volume, mult)
	. = volume * (mult / 10)

/**
 * # `/datum/medical_equipment_function`
 *
 * Transfusing blood/reagents between a patient and a target reagent container. Contains some relevant helper procs.
 */
/datum/medical_equipment_function/transfuser
	var/datum/reagents/reservoir = null
	/// Units of fluid transferred each tick. Currently for both in and out.
	var/transfer_volume = 16

/datum/medical_equipment_function/transfuser/New(datum/reagents/reservoir)
	..()
	if (istype(reservoir, /datum/reagents))
		src.reservoir = reservoir
	else
		src.reservoir = new /datum/reagents(src.transfer_volume)

/// Draws patient blood into internal reagent container.
/datum/medical_equipment_function/transfuser/proc/handle_draw(volume, mult)
	if (!src.parent.patient)
		return
	if (!src.get_patient_fluid_volume())
		return
	if (!isnum(volume))
		return
	transfer_blood(src.parent.patient, src.reservoir, src.calculate_transfer_volume(src.transfer_volume, mult))

/// Infuses internal reagent container contents to patient.
/datum/medical_equipment_function/transfuser/proc/handle_infusion(volume, mult)
	if (!src.parent.patient)
		return
	if (!src.reservoir.total_volume)
		return
	if (!isnum(volume))
		return
	if (src.parent.patient.reagents.is_full())
		return
	var/infusion_volume = src.calculate_transfer_volume(volume, mult)
	src.reservoir.trans_to(src.parent.patient, infusion_volume)
	src.parent.patient.reagents.reaction(src.parent.patient, INGEST, infusion_volume)

/// Returns total patient blood volume in units.
/datum/medical_equipment_function/transfuser/proc/get_patient_blood_volume()
	. = 0
	if (!iscarbon(src.parent.patient))
		return
	var/datum/reagent/patient_blood_reagent = src.parent.patient.reagents.reagent_list["blood"]
	var/patient_blood_reagent_volume = patient_blood_reagent?.volume || 0
	. = src.parent.patient.blood_volume + patient_blood_reagent_volume

/// Returns total patient fluid volume (blood + all reagents) in units.
/datum/medical_equipment_function/transfuser/proc/get_patient_fluid_volume()
	. = 0
	if (!iscarbon(src.parent.patient))
		return
	. = src.parent.patient.blood_volume + src.parent.patient.reagents.total_volume

/// As `mult` is given in deciseconds, it needs to be converted to seconds for transfer volume calculations.
/datum/medical_equipment_function/transfuser/proc/calculate_transfer_volume(volume, mult)
	. = volume * (mult / 10)

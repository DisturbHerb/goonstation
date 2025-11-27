ABSTRACT_TYPE(/datum/component/medical_device/transfuser)
/**
 * # `/datum/component/medical_device/transfuser`
 *
 * Transfusing blood/reagents between a patient and a target reagent container. Contains some relevant helper procs.
 */
/datum/component/medical_device/transfuser
	var/datum/reagents/reservoir = null
	/// Units of fluid transferred each tick. Currently for both in and out.
	var/transfer_volume = 5

/datum/component/medical_device/transfuser/Initialize(connect_time, use_processing_items = TRUE, check_before_attempt = FALSE, datum/reagents/reservoir)
	..()
	if (.)
		return
	src.reservoir = istype(reservoir, /datum/reagents) ? reservoir : new /datum/reagents(src.transfer_volume)

/// Draws patient blood into internal reagent container.
/datum/component/medical_device/transfuser/proc/handle_draw(volume, mult)
	if (!src.patient)
		return
	if (!src.get_fluid_volume())
		return
	if (!isnum(volume))
		return
	transfer_blood(patient, src.reservoir, src.calculate_transfer_volume(src.transfer_volume, mult))
	SEND_SIGNAL(src.parent, COMSIG_INFUSER_DRAW, src.reservoir)

/// Infuses internal reagent container contents to patient.
/datum/component/medical_device/transfuser/proc/handle_infusion(volume, mult)
	if (!src.patient)
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
/datum/component/medical_device/transfuser/proc/get_blood_volume(mob/living/carbon/target_patient)
	. = 0
	if (!target_patient)
		target_patient = src.patient
	if (!iscarbon(target_patient))
		return
	var/datum/reagent/target_blood_reagent = target_patient.reagents.reagent_list["blood"]
	var/target_blood_reagent_volume = target_blood_reagent?.volume || 0
	. = target_patient.blood_volume + target_blood_reagent_volume

/// Returns total target_patient fluid volume (blood + all reagents) in units.
/datum/component/medical_device/transfuser/proc/get_fluid_volume(mob/living/carbon/target_patient)
	. = 0
	if (!target_patient)
		target_patient = src.patient
	if (!iscarbon(target_patient))
		return
	. = target_patient.blood_volume + target_patient.reagents.total_volume

/// Accounts for `mult` on process loops where it's supported.
/datum/component/medical_device/transfuser/proc/calculate_transfer_volume(volume, mult)
	. = volume * mult

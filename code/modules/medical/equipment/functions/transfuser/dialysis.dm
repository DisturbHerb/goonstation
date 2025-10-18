/datum/medical_equipment_function/transfuser/dialysis
	transfer_volume = 16
	requires_power = TRUE
	/// Reagent ID of the current patient's blood.
	var/patient_blood_id = null

/datum/medical_equipment_function/transfuser/dialysis/check_effect_fail(mob/living/carbon/target_patient)
	. = ..()
	if (.)
		return
	if (!src.get_fluid_volume(target_patient))
		return MED_DIALYSIS_PT_EMPTY

/datum/medical_equipment_function/transfuser/dialysis/start_effect()
	. = ..()
	APPLY_ATOM_PROPERTY(src.patient, PROP_MOB_BLOOD_ABSORPTION_RATE, src, 3)

/datum/medical_equipment_function/transfuser/dialysis/effect(mult)
	. = ..()
	src.handle_draw(src.transfer_volume, mult)
	src.screen_blood()
	src.handle_infusion(src.transfer_volume, mult)
	if (!src.patient.hasStatus("dialysis"))
		src.patient.setStatus("dialysis", INFINITE_STATUS)

/datum/medical_equipment_function/transfuser/dialysis/stop_effect()
	. = ..()
	if (!src.patient.reagents.is_full())
		src.handle_infusion()
	REMOVE_ATOM_PROPERTY(src.patient, PROP_MOB_BLOOD_ABSORPTION_RATE, src)
	src.patient.delStatus("dialysis")

/datum/medical_equipment_function/transfuser/dialysis/handle_infusion(volume, mult)
	if (!src.patient)
		return
	// Don't wanna stuff too much blood back in.
	var/patient_blood = src.get_blood_volume()
	var/patient_blood_max = initial(src.patient.blood_volume)
	if (patient_blood > patient_blood_max)
		src.reservoir.remove_reagent("blood", (patient_blood - patient_blood_max))
		volume = src.reservoir.total_volume
	SEND_SIGNAL(src.parent, COMSIG_DIALYSIS_PRE_INFUSION, src.reservoir)
	..()
	src.reservoir.clear_reagents()

/// Re-implemented here due to all the got dang boutputs.
/datum/medical_equipment_function/transfuser/dialysis/proc/screen_blood()
	var/list/whitelist_buffer = global.chem_whitelist + src.patient_blood_id
	for (var/reagent_id in src.reservoir.reagent_list)
		var/purge_reagent = FALSE
		if (src.parent.hacked)
			purge_reagent = !purge_reagent
		if (!(reagent_id in whitelist_buffer))
			purge_reagent = !purge_reagent
		if (!purge_reagent)
			continue
		src.reservoir.del_reagent(reagent_id)

/datum/statusEffect/medical_equipment/dialysis
	id = "dialysis-machine"
	name = "Dialysis Machine"
	desc = "You are connected to a dialysis machine."

/datum/statusEffect/dialysis
	id = "dialysis"
	name = "Dialysis"
	desc = "Your blood is being filtered by a dialysis machine."
	icon_state = "dialysis"
	// Usually positive unless EMAG'd.
	effect_quality = STATUS_QUALITY_POSITIVE
	unique = TRUE

/datum/statusEffect/dialysis/getTooltip()
	. = "A dialysis machine is filtering your blood, removing toxins and treating the symptoms of liver and kidney failure."

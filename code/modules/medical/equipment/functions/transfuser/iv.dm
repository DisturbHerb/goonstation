/datum/medical_equipment_function/transfuser/iv
	requires_power = FALSE
	var/mode = MED_IV_DRAW
	var/transfer_volume_unpowered = 5
	var/transfer_volume_powered = 5

/datum/medical_equipment_function/transfuser/iv/New(datum/medical_equipment/parent, alist/params)
	..()
	if (src.reservoir.total_volume)
		src.change_mode(mode = MED_IV_INJECT)
	RegisterSignal(src.parent, COMSIG_IV_GET_MODE, PROC_REF(return_mode))

/datum/medical_equipment_function/transfuser/iv/check_effect_fail(mob/living/carbon/target_patient)
	. = ..()
	if (.)
		return
	if (src.mode == MED_IV_INJECT)
		if (target_patient.reagents.is_full())
			return MED_IV_PT_FULL
		if (!src.reservoir.total_volume)
			return MED_IV_EMPTY
		return
	if (isvampire(target_patient) && !target_patient.get_vampire_blood())
		return MED_IV_PT_EMPTY
	if (!src.get_fluid_volume(target_patient))
		return MED_IV_PT_EMPTY
	if (src.reservoir.total_volume >= src.reservoir.maximum_volume)
		return MED_IV_FULL

/datum/medical_equipment_function/transfuser/iv/attempt_fail_feedback(mob/user, mob/living/carbon/target_patient, reason = MED_EQUIPMENT_FAILURE)
	. = ..()
	if (length(.))
		return
	var/obj/equipment_obj = src.parent.equipment_obj
	switch (reason)
		if (MED_IV_PT_FULL)
			. = "[target_patient]'s blood pressure seems dangerously high as it is, there's probably no room for anything else!"
		if (MED_IV_EMPTY)
			. = "There's nothing left in [equipment_obj]!"
		if (MED_IV_PT_EMPTY)
			. = "[target_patient] doesn't have anything left to give!"
		if (MED_IV_FULL)
			. = "[equipment_obj] is full!"

/datum/medical_equipment_function/transfuser/iv/stop_effect_feedback(reason = MED_EQUIPMENT_FAILURE)
	. = ..()
	if (!.)
		return
	var/obj/equipment_obj = src.parent.equipment_obj
	switch (reason)
		if (MED_IV_PT_FULL)
			src.patient.visible_message(\
				SPAN_NOTICE("<b>[src.patient]</b>'s transfusion finishes."),\
				SPAN_NOTICE("Your transfusion finishes."))
		if (MED_IV_EMPTY)
			src.patient.visible_message(SPAN_ALERT("[equipment_obj] runs out of fluid!"))
		if (MED_IV_PT_EMPTY)
			src.patient.visible_message(\
				SPAN_ALERT("[equipment_obj] can't seem to draw anything more out of [src.patient]!"),\
				SPAN_ALERT("Your veins feel utterly empty!"))
		if (MED_IV_FULL)
			src.patient.visible_message(\
				SPAN_NOTICE("[equipment_obj] fills up and stops drawing blood from [src.patient]."),\
				SPAN_NOTICE("[equipment_obj] fills up and stops drawing blood from you."))

/datum/medical_equipment_function/transfuser/iv/effect(mult)
	. = ..()
	if (src.mode == MED_IV_INJECT)
		src.handle_infusion(src.transfer_volume, mult)
		return
	src.handle_draw(src.transfer_volume, mult)

/datum/medical_equipment_function/transfuser/iv/on_power_loss()
	..()
	src.transfer_volume = transfer_volume_unpowered

/datum/medical_equipment_function/transfuser/iv/on_power_restore()
	..()
	src.transfer_volume = transfer_volume_powered

/datum/medical_equipment_function/transfuser/iv/on_attack_self(mob/user)
	src.change_mode(user)

/datum/medical_equipment_function/transfuser/iv/proc/return_mode()
	SEND_SIGNAL(src.parent, COMSIG_IV_RETURN_MODE, list(MED_IV_MODE = src.mode))

/datum/medical_equipment_function/transfuser/iv/proc/change_mode(mob/user, mode)
	if (mode)
		src.mode = mode
	else
		src.mode = !src.mode
	if (user)
		user.show_text("You switch [src.parent.equipment_obj] to [src.mode ? "inject" : "draw"].")
	src.return_mode()

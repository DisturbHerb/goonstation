/datum/component/medical_device/transfuser/iv
	requires_power = FALSE
	var/mode = MED_IV_DRAW
	var/transfer_volume_unpowered = 5
	var/transfer_volume_powered = 5

/datum/component/medical_device/transfuser/iv/Initialize(connect_time, use_processing_items, check_before_attempt, datum/reagents/reservoir)
	..()
	if (src.reservoir.total_volume)
		src.change_mode(mode = MED_IV_INJECT)

/datum/component/medical_device/transfuser/iv/check_effect_fail(mob/living/carbon/target_patient)
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

/datum/component/medical_device/transfuser/iv/attempt_fail_feedback(mob/user, mob/living/carbon/target_patient, reason = MED_DEVICEFAILURE)
	switch (reason)
		if (MED_IV_PT_FULL)
			boutput(user, SPAN_ALERT("[target_patient]'s blood pressure seems dangerously high as it is, there's probably no room for anything else!"))
		if (MED_IV_EMPTY)
			boutput(user, SPAN_ALERT("There's nothing left in [src.parent]!"))
		if (MED_IV_PT_EMPTY)
			boutput(user, SPAN_ALERT("[target_patient] doesn't have anything left to give!"))
		if (MED_IV_FULL)
			boutput(user, SPAN_ALERT("[src.parent] is full!"))

/datum/component/medical_device/transfuser/iv/stop_effect_feedback(reason = MED_DEVICEFAILURE)
	switch (reason)
		if (MED_IV_PT_FULL)
			src.patient.visible_message(\
				SPAN_NOTICE("<b>[src.patient]</b>'s transfusion finishes."),\
				SPAN_NOTICE("Your transfusion finishes."))
		if (MED_IV_EMPTY)
			src.patient.visible_message(SPAN_ALERT("[src.parent] runs out of fluid!"))
		if (MED_IV_PT_EMPTY)
			src.patient.visible_message(\
				SPAN_ALERT("[src.parent] can't seem to draw anything more out of [src.patient]!"),\
				SPAN_ALERT("Your veins feel utterly empty!"))
		if (MED_IV_FULL)
			src.patient.visible_message(\
				SPAN_NOTICE("[src.parent] fills up and stops drawing blood from [src.patient]."),\
				SPAN_NOTICE("[src.parent] fills up and stops drawing blood from you."))

/datum/component/medical_device/transfuser/iv/effect(mult)
	. = ..()
	if (src.mode == MED_IV_INJECT)
		src.handle_infusion(src.transfer_volume, mult)
		return
	src.handle_draw(src.transfer_volume, mult)

/datum/component/medical_device/transfuser/iv/on_power_loss()
	..()
	src.transfer_volume = transfer_volume_unpowered

/datum/component/medical_device/transfuser/iv/on_power_restore()
	..()
	src.transfer_volume = transfer_volume_powered

/datum/component/medical_device/transfuser/iv/on_attack_self(mob/user)
	src.change_mode(user)

/datum/component/medical_device/transfuser/iv/proc/return_mode()
	SEND_SIGNAL(src.parent, COMSIG_IV_RETURN_MODE, src.mode)

/datum/component/medical_device/transfuser/iv/proc/change_mode(mob/user, mode)
	if (mode)
		src.mode = mode
	else
		src.mode = !src.mode
	if (user)
		user.show_text("You switch [src.parent] to [src.mode ? "inject" : "draw"].")
	src.return_mode()

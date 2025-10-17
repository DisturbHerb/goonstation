/datum/medical_equipment_function/transfuser/iv
	requires_power = FALSE
	var/mode = MED_IV_DRAW
	var/transfer_volume_unpowered = 5
	var/transfer_volume_powered = 5

/datum/medical_equipment_function/transfuser/iv/New(datum/reagents/reservoir)
	..()
	if (src.reservoir.total_volume)
		src.mode = MED_IV_INJECT

/datum/medical_equipment_function/transfuser/iv/check_effect_fail(mob/living/carbon/target)
	. = ..()
	if (src.mode == MED_IV_INJECT)
		if (!target.reagents.is_full())
			return MED_IV_PT_FULL
		if (!src.reservoir.total_volume)
			return MED_IV_EMPTY
		return
	if (isvampire(target) && !target.get_vampire_blood())
		return MED_IV_PT_EMPTY
	if (!src.get_fluid_volume(target))
		return MED_IV_PT_EMPTY
	if (src.reservoir.total_volume == src.reservoir.maximum_volume)
		return MED_IV_FULL

/datum/medical_equipment_function/transfuser/iv/connect_fail_feedback(mob/user, mob/living/carbon/target, reason = MED_EQUIPMENT_FAILURE)
	..()
	var/obj/equipment_obj = src.parent.equipment_obj
	switch (reason)
		if (MED_IV_PT_FULL)
			. = "[target]'s blood pressure seems dangerously high as it is, there's probably no room for anything else!"
		if (MED_IV_EMPTY)
			. = "There's nothing left in [equipment_obj]!"
		if (MED_IV_PT_EMPTY)
			. = "[target] doesn't have anything left to give!"
		if (MED_IV_FULL)
			. = "[equipment_obj] is full!"

/datum/medical_equipment_function/transfuser/iv/end_effect_feedback(mob/living/carbon/target, reason = MED_EQUIPMENT_FAILURE)
	..()
	var/obj/equipment_obj = src.parent.equipment_obj
	switch (reason)
		if (MED_IV_PT_FULL)
			target.visible_message(\
				SPAN_NOTICE("<b>[target]</b>'s transfusion finishes."),\
				SPAN_NOTICE("Your transfusion finishes."))
		if (MED_IV_EMPTY)
			target.visible_message(SPAN_ALERT("[equipment_obj] runs out of fluid!"))
		if (MED_IV_PT_EMPTY)
			target.visible_message(\
				SPAN_ALERT("[equipment_obj] can't seem to draw anything more out of [target]!"),\
				SPAN_ALERT("Your veins feel utterly empty!"))
		if (MED_IV_FULL)
			target.visible_message(\
				SPAN_NOTICE("[equipment_obj] fills up and stops drawing blood from [target]."),\
				SPAN_NOTICE("[equipment_obj] fills up and stops drawing blood from you."))

/datum/medical_equipment_function/transfuser/iv/on_power_loss()
	..()
	src.transfer_volume = transfer_volume_unpowered

/datum/medical_equipment_function/transfuser/iv/on_power_restore()
	..()
	src.transfer_volume = transfer_volume_powered

/datum/medical_equipment_function/transfuser/iv/on_attack_self(mob/user)
	src.mode = !src.mode
	user.show_text("You switch [src.parent.equipment_obj] to [src.mode ? "inject" : "draw"].")

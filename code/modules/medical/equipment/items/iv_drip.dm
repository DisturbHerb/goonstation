/**
 * # IV drip
 */
/obj/item/reagent_containers/glass/iv_drip
	name = "\improper IV drip"
	desc = "A bag with a fine needle attached at the end, for injecting patients with fluids."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "IV"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "IV"
	w_class = W_CLASS_TINY
	flags = TABLEPASS | ACCEPTS_MOUSEDROP_REAGENTS | SUPPRESSATTACK
	rc_flags = RC_VISIBLE | RC_FULLNESS | RC_SPECTRO
	amount_per_transfer_from_this = 5
	initial_volume = 250
	incompatible_with_chem_dispensers = TRUE
	can_recycle = FALSE
	shatter_immune = TRUE
	container_icon = 'icons/obj/surgery.dmi'
	container_style = "IV"
	fluid_overlay_states = 9
	fluid_overlay_scaling = RC_REAGENT_OVERLAY_SCALING_LINEAR
	var/obj/machinery/medical/attached_machine = null
	var/obj/overlay/mode_overlay = null

/obj/item/reagent_containers/glass/iv_drip/New()
	..()
	src.mode_overlay = new()
	src.mode_overlay.icon = src.icon
	src.mode_overlay.invisibility = INVIS_ALWAYS
	src.mode_overlay.plane = PLANE_HUD
	src.mode_overlay.layer = HUD_LAYER_3
	src.mode_overlay.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | PIXEL_SCALE
	src.vis_contents += src.mode_overlay

	src.medical_equipment = new /datum/medical_equipment(\
		equipment_obj = src,\
		function = /datum/medical_equipment_function/transfuser/iv,\
		function_params = list(MED_TRANSFUSER_RESERVOIR = src.reagents),\
		check_before_attempt = TRUE,\
	)
	src.UpdateOverlays(image(src.icon, "IVlabel[src.reagents.get_master_reagent_name() == "blood" ? "-blood" : ""]"), "label")
	src.update_name()
	RegisterSignal(src.medical_equipment, COMSIG_IV_RETURN_MODE, PROC_REF(update_mode_overlay))
	SEND_SIGNAL(src.medical_equipment, COMSIG_IV_GET_MODE)

/obj/item/reagent_containers/glass/iv_drip/on_reagent_change()
	..()
	src.update_name()
	if (src.attached_machine)
		src.attached_machine.UpdateIcon()

/obj/item/reagent_containers/glass/iv_drip/attack_self(mob/user)
	return

/// Suppress splashing if we're trying to interact with a patient.
/obj/item/reagent_containers/glass/iv_drip/afterattack(obj/target, mob/user, flag)
	if (iscarbon(target))
		return
	. = ..()

/obj/item/reagent_containers/glass/iv_drip/attackby(obj/A, mob/user)
	if (!iscuttingtool(A))
		return ..()
	if (src.is_open_container())
		boutput(user, "[src] has already been sliced open.")
		return ..()
	src.set_open_container(TRUE)
	src.desc = "[src.desc] It has been sliced open."
	boutput(user, "You carefully slice [src] open.")

/obj/item/reagent_containers/glass/iv_drip/dropped(mob/user)
	. = ..()
	src.mode_overlay.invisibility = INVIS_ALWAYS

/obj/item/reagent_containers/glass/iv_drip/pickup(mob/user)
	. = ..()
	if (!src.mode_overlay.icon_state)
		SEND_SIGNAL(src.medical_equipment, COMSIG_IV_GET_MODE)
	src.mode_overlay.invisibility = INVIS_NONE

// /obj/item/reagent_containers/glass/iv_drip/mouse_drop(atom/over_object)
// 	if (!isatom(over_object))
// 		. = ..()
// 		return
// 	var/mob/living/user = usr
// 	if (!isliving(user) || isintangible(user) || !can_act(user) || !in_interact_range(src, user) || !in_interact_range(over_object, user))
// 		. = ..()
// 		return
// 	if (!istype(over_object, /obj/machinery/medical/blood/iv_stand))
// 		. = ..()
// 		return
// 	var/obj/machinery/medical/blood/iv_stand/iv_stand = over_object
// 	iv_stand.add_iv_drip(src, user)

/obj/item/reagent_containers/glass/iv_drip/proc/update_name()
	if (src.reagents?.total_volume)
		src.name = src.reagents.get_master_reagent_name() == "blood" ? "blood pack" : "[src.reagents.get_master_reagent_name()] drip"
	else
		src.name = "\improper IV drip"

/obj/item/reagent_containers/glass/iv_drip/proc/update_mode_overlay(datum/medical_equipment/equipment, alist/params)
	if (!length(params))
		return
	var/mode = params[MED_IV_MODE] || MED_IV_DRAW
	src.mode_overlay.icon_state = mode ? "inject" : "draw"

/*
 * IV drip types
 */
/obj/item/reagent_containers/glass/iv_drip/blood
	desc = "A bag filled with some odd, synthetic blood. There's a fine needle at the end that can be used to transfer it to someone."
	initial_reagents = "blood"

/obj/item/reagent_containers/glass/iv_drip/blood/vr
	icon = 'icons/effects/VR.dmi'

/obj/item/reagent_containers/glass/iv_drip/saline
	desc = "A bag filled with saline. There's a fine needle at the end that can be used to transfer it to someone."
	initial_reagents = "saline"

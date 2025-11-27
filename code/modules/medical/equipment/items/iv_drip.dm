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

/obj/item/reagent_containers/glass/iv_drip/New()
	..()
	AddComponent(/datum/component/medical_device/transfuser/iv, reservoir = src)
	src.UpdateOverlays(image(src.icon, "IVlabel[src.reagents.get_master_reagent_name() == "blood" ? "-blood" : ""]"), "label")
	src.update_name()

/obj/item/reagent_containers/glass/iv_drip/on_reagent_change()
	..()
	src.update_name()

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

/obj/item/reagent_containers/glass/iv_drip/mouse_drop(atom/over_object)
	if (!isatom(over_object))
		. = ..()
		return
	var/mob/living/user = usr
	if (!isliving(user) || isintangible(user) || !can_act(user) || !in_interact_range(src, user) || !in_interact_range(over_object, user))
		. = ..()
		return
	if (!istype(over_object, /obj/machinery/medical/iv_stand))
		. = ..()
		return
	var/obj/machinery/medical/iv_stand/iv_stand = over_object
	iv_stand.add_iv(src, user)

/obj/item/reagent_containers/glass/iv_drip/proc/update_name()
	if (src.reagents?.total_volume)
		src.name = src.reagents.get_master_reagent_name() == "blood" ? "blood pack" : "[src.reagents.get_master_reagent_name()] drip"
	else
		src.name = "\improper IV drip"

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

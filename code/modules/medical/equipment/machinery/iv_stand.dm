/**
 * # IV stand
 *
 * N.B. The lights on the IV pump will flash red when these conditions are true:
 * 	- An IV bag is attached
 * 	- The area containing the IV stand is powered
 * 	- The IV bag is not connected to a patient
 * This is intended behaviour; aiming to emulate the error state on real-world IV pumps which would flash and beep if the line was occluded among
 * other error conditions - DisturbHerb
 */
/obj/machinery/medical/iv_stand
	name = "\improper IV stand"
	desc = {"A metal pole that you can hang IV bags on, which is useful since we aren't animals that go leaving our sanitized medical equipment all
			over the ground or anything!"}
	icon = 'icons/obj/machines/medical/iv_stand.dmi'
	icon_state = "IV_stand"
	/// IV stands cannot operate without an `iv_drip` attached.
	var/obj/item/reagent_containers/glass/iv_drip/iv_drip = null

/obj/machinery/medical/iv_stand/start_feedback()
	..()
	// src.say("[src.iv_drip?.mode ? "Infusing" : "Drawing from"] patient at [src.transfer_volume]u per tick.")

/obj/machinery/medical/iv_stand/stop_feedback(reason)
	..()
	// src.say("Stopped [src.iv_drip?.mode ? "infusing" : "drawing from"] patient.")

/obj/machinery/medical/iv_stand/low_power_alert()
	..()
	src.say("IV pump unable to draw power. Check bag.")

/obj/machinery/medical/iv_stand/New()
	..()
	src.UpdateIcon()

/obj/machinery/medical/iv_stand/disposing()
	if (src.iv_drip)
		src.remove_iv_drip()
	..()

/obj/machinery/medical/iv_stand/get_desc(dist, mob/user)
	. = ..()
	if (!src.iv_drip)
		return
	. += " [src.iv_drip] is attached to it."
	if (!src.iv_drip.reagents.total_volume)
		return
	. += "<br>[SPAN_NOTICE("[src.iv_drip.reagents.get_description(user, src.iv_drip.rc_flags)]")]"

/obj/machinery/medical/iv_stand/update_icon()
	if (!src.iv_drip)
		src.ClearSpecificOverlays("fluid", "bag", "lights")
		src.UpdateOverlays(image(src.icon, icon_state = "IV_pump-lid"), "lid")
		return
	src.handle_iv_bag_image()
	src.ClearSpecificOverlays("lid")
	if (!src.equipment_datum.patient || src.is_disabled())
		src.ClearSpecificOverlays("lights")
		return
	src.UpdateOverlays(image(src.icon, icon_state = "IV_pump-lights"), "lights")

/obj/machinery/medical/iv_stand/proc/handle_iv_bag_image()
	src.UpdateOverlays(image(src.icon, icon_state = "IV"), "bag")
	if (!src.iv_drip.reagents.total_volume)
		src.ClearSpecificOverlays("fluid")
		return
	var/image/fluid_image = image(src.icon, icon_state = "IV-fluid")
	fluid_image.icon_state = "IV-fluid"
	fluid_image.color = src.iv_drip.reagents.get_average_color().to_rgba()
	src.UpdateOverlays(fluid_image, "fluid")

/obj/machinery/medical/iv_stand/proc/update_name()
	if (src.iv_drip)
		src.name = "[initial(src.name)] ([src.iv_drip])"
		return
	src.name = initial(src.name)

/obj/machinery/medical/iv_stand/mouse_drop_interactions(atom/over_object, user)
	..()
	if (isturf(over_object) && src.iv_drip)
		src.remove_iv_drip(user, get_turf(over_object))

/obj/machinery/medical/iv_stand/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		actions.start(new /datum/action/bar/icon/furniture_deconstruct(src, W, 2 SECONDS), user)
		return
	if (!istype(W, /obj/item/reagent_containers/glass/iv_drip))
		return ..()
	if (isrobot(user)) // are they a borg? it's probably a mediborg's IV then, don't take that!
		return

	// TODO this definitely needs to be a proc
	if (src.iv_drip)
		return
	if (W.loc == user)
		user.u_equip(W)
	src.iv_drip = W
	src.iv_drip.set_loc(src)
	src.iv_drip.subordinate(src.equipment_datum)
	user.visible_message(SPAN_NOTICE("[user] hangs [src.iv_drip] on [src]."), SPAN_NOTICE("You hang [src.iv_drip] on [src]."))

	src.UpdateIcon()
	src.update_name()

/obj/machinery/medical/iv_stand/attack_hand(mob/user)
	if (!src.iv_drip)
		return ..()
	if (isrobot(user))
		return ..()
	src.remove_iv_drip(user)

/obj/machinery/medical/iv_stand/deconstruct()
	if (src.iv_drip)
		src.remove_iv_drip()
	var/obj/item/furniture_parts/IVstand/P = new /obj/item/furniture_parts/IVstand(src.loc)
	if (P && src.material)
		P.setMaterial(src.material)
	qdel(src)

/obj/machinery/medical/iv_stand/proc/remove_iv_drip(mob/user, turf/new_loc)
	var/obj/item/reagent_containers/glass/iv_drip/old_iv = src.iv_drip
	src.iv_drip.equipment_datum.clear_superior()
	src.iv_drip = null
	src.UpdateIcon()
	src.update_name()
	if (isturf(new_loc))
		old_iv.set_loc(new_loc)
		return
	if (ismob(user))
		user.visible_message(SPAN_NOTICE("[user] takes [old_iv] down from [src]."), SPAN_NOTICE("You take [old_iv] down from [src]."))
		user.put_in_hand_or_drop(old_iv)
		return
	old_iv.set_loc(get_turf(new_loc))

/obj/item/furniture_parts/IVstand
	name = "\improper IV stand parts"
	desc = "A collection of parts that can be used to make an IV stand."
	icon = 'icons/obj/machines/medical/iv_stand.dmi'
	icon_state = "IV_stand_parts"
	force = 2
	stamina_damage = 10
	stamina_cost = 8
	furniture_type = /obj/machinery/medical/iv_stand
	furniture_name = "\improper IV stand"
	build_duration = 25

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

/obj/machinery/medical/iv_stand/start_feedback(datum/medical_equipment/equipment, list/params)
	..()
	if (!length(params))
		return
	if (!length(params[MED_IV_MODE]))
		return
	var/mode = params[MED_IV_MODE]
	if (!length(params[MED_TRANSFUSER_VOLUME]))
		return
	var/transfer_volume = params[MED_TRANSFUSER_VOLUME]
	src.say("[mode ? "Infusing" : "Drawing from"] patient at [transfer_volume]u per tick.")

/obj/machinery/medical/iv_stand/stop_feedback(datum/medical_equipment/equipment, list/params)
	..()
	if (!length(params))
		return
	if (!length(params[MED_IV_MODE]))
		return
	var/mode = params[MED_IV_MODE]
	src.say("Stopped [mode ? "infusing" : "drawing from"] patient.")

/obj/machinery/medical/iv_stand/low_power_alert(datum/medical_equipment/equipment, list/params)
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
	if (!src.medical_equipment.patient || src.is_disabled())
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
		src.remove_iv_drip(get_turf(over_object), user)

/obj/machinery/medical/iv_stand/attackby(obj/item/I, mob/user)
	if (!istype(I, /obj/item/reagent_containers/glass/iv_drip))
		return ..()
	// are they a borg? it's probably a mediborg's IV then, don't take that!
	if (isrobot(user))
		return
	src.add_iv_drip(I, user)

/obj/machinery/medical/iv_stand/attack_hand(mob/user)
	if (!src.iv_drip)
		return ..()
	if (isrobot(user))
		return ..()
	src.remove_iv_drip(user = user)

/obj/machinery/medical/iv_stand/attempt_deconstruct(obj/item/I, mob/user)
	. = ..()
	if (iswrenchingtool(I))
		return TRUE

/obj/machinery/medical/iv_stand/deconstruct()
	if (src.iv_drip)
		src.remove_iv_drip()
	var/obj/item/furniture_parts/IVstand/P = new /obj/item/furniture_parts/IVstand(src.loc)
	if (P && src.material)
		P.setMaterial(src.material)
	..()

/obj/machinery/medical/iv_stand/proc/add_iv_drip(obj/item/reagent_containers/glass/iv_drip/new_iv, mob/user)
	if (src.iv_drip)
		return
	if (!istype(new_iv, /obj/item/reagent_containers/glass/iv_drip))
		return
	src.iv_drip = src.add_equipment(new_iv, user)
	user.visible_message(SPAN_NOTICE("[user] hangs [src.iv_drip] on [src]."), SPAN_NOTICE("You hang [src.iv_drip] on [src]."))
	src.UpdateIcon()
	src.update_name()

/obj/machinery/medical/iv_stand/proc/remove_iv_drip(atom/new_loc, mob/user)
	src.remove_equipment(src.iv_drip, user, new_loc)
	if (user)
		user.visible_message(SPAN_NOTICE("[user] takes [src.iv_drip] down from [src]."), SPAN_NOTICE("You take [src.iv_drip] down from [src]."))
	src.iv_drip = null
	src.UpdateIcon()
	src.update_name()

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

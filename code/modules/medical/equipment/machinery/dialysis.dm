TYPEINFO(/obj/machinery/medical/dialysis)
	mats = list(
		"metal" = 20,
		"crystal" = 5,
		"conductive_high" = 5
	)

/**
 * # Dialysis Machine
 */
/obj/machinery/medical/dialysis
	name = "dialysis machine"
	desc = "A machine which continuously draws blood from a patient, removes excess chemicals from it, and re-infuses it into the patient."
	icon = 'icons/obj/machines/medical/dialysis.dmi'
	density = 1
	icon_state = "dialysis"
	power_consumption = 1.5 KILO WATTS
	function = /datum/medical_equipment_function/transfuser/dialysis

/obj/machinery/medical/dialysis/New()
	. = ..()
	RegisterSignal(src.medical_equipment, COMSIG_INFUSER_DRAW, PROC_REF(on_draw))
	RegisterSignal(src.medical_equipment, COMSIG_DIALYSIS_PRE_INFUSION, PROC_REF(on_infusion))
	src.UpdateIcon()

/obj/machinery/medical/dialysis/emag_feedback(mob/user, obj/item/card/emag/emag)
	. = ..()
	if (!.)
		return
	src.say("Dialysis protocols inversed.")

/obj/machinery/medical/dialysis/start_failure_feedback()
	. = ..()
	if (!.)
		return
	src.say("Failure to start dialysis. Check patient.")

/obj/machinery/medical/dialysis/start_feedback()
	src.UpdateIcon()
	. = ..()
	if (!.)
		return
	src.say("Dialysing patient.")

/obj/machinery/medical/dialysis/stop_feedback(reason)
	src.UpdateIcon()
	. = ..()
	if (!.)
		return
	if (reason == MED_DIALYSIS_PT_EMPTY)
		src.say("Nil fluid pressure. Patient may be deceased.")
		return
	src.say("Stopping dialysis.")

/obj/machinery/medical/dialysis/low_power_alert()
	src.UpdateIcon()
	. = ..()
	if (!.)
		return
	src.say("Unable to draw power, stopping dialysis.")

/obj/machinery/medical/dialysis/update_icon(...)
	..()
	if (!src.medical_equipment.active || src.is_disabled() || !src.medical_equipment.patient)
		src.ClearSpecificOverlays("pump", "screen", "tubing-good", "tubing-bad")
		return
	src.UpdateOverlays(image(src.icon, "pump"), "pump")
	src.UpdateOverlays(image(src.icon, "screen"), "screen")

/obj/machinery/medical/dialysis/proc/on_draw(datum/medical_equipment/equipment, datum/reagents/reservoir)
	src.update_tubing(reservoir, "tubing-bad")

/obj/machinery/medical/dialysis/proc/on_infusion(datum/medical_equipment/equipment, datum/reagents/reservoir)
	src.update_tubing(reservoir, "tubing-good")

/obj/machinery/medical/dialysis/proc/update_tubing(datum/reagents/reservoir, tube = "tubing-bad")
	var/image/tubing_image = image(src.icon, tube)
	if (reservoir.total_volume)
		tubing_image.color = reservoir.get_average_color().to_rgba()
		src.UpdateOverlays(tubing_image, tube)
	else
		src.ClearSpecificOverlays(tube)

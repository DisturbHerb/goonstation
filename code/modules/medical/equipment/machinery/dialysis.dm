// MUST BE IDENTICAL TO ICONSTATE NAMES IN 'icons/obj/machines/medical/dialysis.dmi'.
#define DIALYSIS_TUBING_BAD "tubing-bad"
#define DIALYSIS_TUBING_GOOD "tubing-good"

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

/obj/machinery/medical/dialysis/handle_emag(mob/user, obj/item/card/emag/E)
	. = ..()
	src.say("Dialysis protocols inversed.")

/obj/machinery/medical/dialysis/start_failure_feedback()
	. = ..()
	src.say("Failure to start dialysis. Check patient.")

/obj/machinery/medical/dialysis/start_feedback()
	. = ..()
	src.say("Dialysing patient.")

/obj/machinery/medical/dialysis/stop_feedback(reason)
	. = ..()
	src.say("Stopping dialysis.")

/obj/machinery/medical/dialysis/low_power_alert()
	. = ..()
	src.say("Unable to draw power, stopping dialysis.")

/obj/machinery/medical/dialysis/New()
	..()
	src.UpdateIcon()

/obj/machinery/medical/dialysis/update_icon(...)
	..()
	if (!src.equipment_datum.active || !src.equipment_datum.patient)
		src.ClearSpecificOverlays("pump", "screen", DIALYSIS_TUBING_GOOD, DIALYSIS_TUBING_BAD)
		return
	src.UpdateOverlays(image(src.icon, "pump"), "pump")
	src.UpdateOverlays(image(src.icon, "screen"), "screen")

/obj/machinery/medical/dialysis/proc/update_tubing(tube = DIALYSIS_TUBING_BAD)
	var/image/tubing_image = image(src.icon, tube)
	if (src.reagents.total_volume)
		tubing_image.color = src.reagents.get_average_color().to_rgba()
	src.UpdateOverlays(tubing_image, tube)

#undef DIALYSIS_TUBING_BAD
#undef DIALYSIS_TUBING_GOOD

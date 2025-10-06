TYPEINFO(/obj/machinery/medical/anesthesia)
	mats = list("metal" = 25,
				"crystal" = 10,
				"conductive_high" = 5)

/**
 * # Anesthesia machine
 *
 * Utilizing the American spelling. God help us all. - DisturbHerb
 */
/obj/machinery/medical/anesthesia
	name = "anesthesia machine"
	desc = "A machine which provides a gaseous and vaporised anesthetic drug supply to sedate and ameliorate the pain of surgical patients."
	icon = 'icons/obj/machines/medical/anesthesia.dmi'
	density = 1
	icon_state = "anesthesia"
	power_consumption = 1.5 KILO WATTS

	attempt_msg_viewer = "<b>$USR</b> begins hooking up $TRG to $SRC's gas supply."
	attempt_msg_user = "You begin hooking up $TRG to $SRC's gas supply."
	attempt_msg_patient = "<b>$USR</b> begin hooking you up to $SRC's gas supply."

	add_msg_viewer = "<b>$USR</b> hooks up $TRG to $SRC's gas supply."
	add_msg_user = "You hook up $TRG to $SRC's gas supply."
	add_msg_patient = "<b>$USR</b> hooks you up to $SRC's gas supply."

	remove_msg_viewer = "<b>$USR</b> disconnects $TRG from $SRC's gas supply."
	remove_msg_user = "You disconnect $TRG from $SRC's gas supply."
	remove_msg_patient = "<b>$USR</b> disconnects you from $SRC's gas supply."

	remove_forceful_msg_viewer = "<b>$TRG is forcefully disconnected from $SRC's gas supply!</b>"
	remove_forceful_msg_patient = "<b>You are forcefully disconnected from $SRC's gas supply!</b>"

	var/obj/item/tank/gas_tank

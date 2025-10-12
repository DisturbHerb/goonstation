TYPEINFO(/obj/machinery/medical/anesthesia)
	mats = list(
		"metal" = 25,
		"crystal" = 10,
		"conductive_high" = 5
	)

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
	var/obj/item/tank/gas_tank

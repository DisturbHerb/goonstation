/datum/medical_equipment_function/transfuser/iv
	var/mode = MED_IV_DRAW

/datum/medical_equipment_function/transfuser/iv/New(datum/reagents/reservoir)
	..()
	if (src.reservoir.total_volume)
		src.mode = MED_IV_INJECT

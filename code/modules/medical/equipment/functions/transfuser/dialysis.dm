/datum/medical_equipment_function/transfuser/dialysis
	transfer_volume = 16

/datum/statusEffect/medical_equipment/dialysis
	id = "dialysis-machine"
	name = "Dialysis Machine"
	desc = "You are connected to a dialysis machine."

/datum/statusEffect/dialysis
	id = "dialysis"
	name = "Dialysis"
	desc = "Your blood is being filtered by a dialysis machine."
	icon_state = "dialysis"
	// Usually positive unless EMAG'd.
	effect_quality = STATUS_QUALITY_POSITIVE
	unique = TRUE

/datum/statusEffect/dialysed/getTooltip()
	. = "A dialysis machine is filtering your blood, removing toxins and treating the symptoms of liver and kidney failure."

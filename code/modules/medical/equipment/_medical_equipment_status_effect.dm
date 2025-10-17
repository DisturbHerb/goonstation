/**
 * # /datum/statusEffect/medical_equipment
 *
 * Non-unique. Added to patient on connection to a medical equipment. Mostly serves as a visual indicator that you're connected.
 */
/datum/statusEffect/medical_equipment
	id = "medical_equipment"
	name = "Medical Equipment"
	desc = "You are connected to some medical equipment."
	icon_state = "+"
	unique = FALSE
	effect_quality = STATUS_QUALITY_NEUTRAL
	var/datum/medical_equipment/equipment = null

/datum/statusEffect/medical_equipment/getTooltip()
	. = "You are physically connected to \a [src.equipment.equipment_obj.name]. Moving too far from it may forcefully disconnect you."

/datum/statusEffect/medical_equipment/onAdd(datum/medical_equipment/optional)
	..()
	src.equipment = optional

/datum/statusEffect/medical_equipment/onCheck(optional)
	return src.equipment == optional

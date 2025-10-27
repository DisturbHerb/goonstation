/**
 * # /datum/statusEffect/medical_device
 *
 * Non-unique. Added to patient on connection to a medical device component to serve as a visual indicator.
 */
/datum/statusEffect/medical_device
	id = "medical_device"
	name = "Medical device"
	desc = "You are connected to some medical device."
	icon_state = "+"
	unique = FALSE
	effect_quality = STATUS_QUALITY_NEUTRAL
	var/datum/component/medical_device/device = null

/datum/statusEffect/medical_device/getTooltip()
	. = "You are physically connected to \a [src.device.parent]. Moving too far from it may forcefully disconnect you."

/datum/statusEffect/medical_device/onAdd(datum/component/medical_device/optional)
	..()
	src.device = optional

/datum/statusEffect/medical_device/onCheck(optional)
	return src.device == optional

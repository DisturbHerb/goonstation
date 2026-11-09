/// `/datum/customization_slot`
/// Holds all the customization information.
ABSTRACT_TYPE(/datum/customization_slot)
/datum/customization_slot
	/// Restricts the `/datum/customization_style`s which can be applied to it. Required variable. See `CUSTOMIZATION::SLOT` namespace.
	var/slot_type = CUSTOMIZATION::SLOT::HAIR

	/// Type path of the `/datum/customization_style` whose static data is applied to this slot. Do not override manually.
	var/datum/customization_style/style = /datum/customization_style/hair/short/short
	/// Type path of the `/datum/customization_style` that was set in player preferences. Do not override manually.
	var/datum/customization_style/style_original = /datum/customization_style/none

	/// Determines the color of the final image.
	var/color = "#101010"
	/// The color that was originally set in player preferences.
	var/color_original = "#101010"
	/// The Y offset to apply when displaying this image.
	var/offset_y = 0

/datum/customization_slot/New()
	if (!src.slot_type)
		CRASH("[src] instantiated without a valid slot_type!")
	. = ..()

/// Checks if its input corresponds to the `name` or `id` of a valid `/datum/customization_style` type.
/datum/customization_slot/proc/check_style_validity(style_input, style_filter = null, pref_blacklist = TRUE, bypass_lock = FALSE)
	. = null

	if (!style_input)
		return

	// Return a valid style, if found.
	for (var/datum/customization_style/style_type as anything in global.get_available_custom_style_types(style_filter = null, pref_blacklist = pref_blacklist, bypass_lock = TRUE))
		if ((style_type::id != style_input) && (style_type::name != style_input))
			continue

		// Check slot compatibility.
		var/typeinfo/datum/customization_style/style_type_typeinfo = get_type_typeinfo(style_type)
		if (style_type_typeinfo.style_slot != src.slot_type)
			continue

		return style_type

/// For changing this slot's current style.
/datum/customization_slot/proc/set_style(style_input, style_filter = null, pref_blacklist = TRUE, bypass_lock = FALSE)
	. = FALSE

	var/datum/customization_style/style_type = src.check_style_validity(style_input, style_filter, pref_blacklist, bypass_lock)
	if (!style_type)
		return

	src.style = style_input
	. = TRUE

/// For styles originally applied in a player's character preferences.
/datum/customization_slot/proc/set_style_original(style_input, style_filter = null, pref_blacklist = TRUE, bypass_lock = FALSE)
	. = FALSE

	var/datum/customization_style/style_type = src.check_style_validity(style_input, style_filter, pref_blacklist, bypass_lock)
	if (!style_type)
		return

	src.style = style_input
	. = TRUE

/datum/customization_slot/proc/clear_style()
	src.style = /datum/customization_style/none

/datum/customization_slot/proc/clear_style_original()
	src.style_original = /datum/customization_style/none

/datum/customization_slot/proc/is_empty()
	return src.style::id == CUSTOMIZATION::NONE ? TRUE : FALSE

ABSTRACT_TYPE(/datum/customization_slot/hair)
/datum/customization_slot/hair
	slot_type = CUSTOMIZATION::SLOT::HAIR

/datum/customization_slot/hair/bottom
	style =  /datum/customization_style/hair/short/short

/datum/customization_slot/hair/middle
	style =  /datum/customization_style/none

/datum/customization_slot/hair/top
	style =  /datum/customization_style/none

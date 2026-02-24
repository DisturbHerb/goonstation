/**
 * # `/datum/component/clothing_style_cycle`
 *
 * Allows for the cycling of clothing item styles. Provides visual and chat feedback. Unifies the functionality of several pre-existing DCS components
 * to standardise behaviour, increase ease of use, and lower future maintenance burden.
 *
 * Styles may include:
 * 	- Changes to the icon of a clothing item's `icon_state`, `wear_state`, and `item_state`.
 * 	- Stat changes, such as reducing coldprot when unbuttoning a jacket.
 * 	- Specific clothing item proc calls when switching styles.
 */
/datum/component/clothing_style_cycle
	dupe_mode = COMPONENT_DUPE_UNIQUE

	/**
	 * n-dimensional list of available styles to cycle between.
	 *
	 * When cycling between clothing styles in-hand, the lowest level list of styles will be cycled by list index first. At the end, the next highest
	 * level will cycle forward, repeating all the way up to the highest level list.
	 *
	 * FORMAT
	 * list/styles = list(
	 *
	 * )
	 */
	var/list/styles = list()
	/// `src.style` list indexed by string.
	var/list/current_style_index = list(1)
	/// `icon_state` base name to append style modifiers to.
	var/base_name = ""
	/// List of ability button instances for cycling individual style elements as opposed to all the available styles.
	var/list/obj/ability_button/ability_buttons = null
	var/obj/item/clothing/clothing_item = null

/**
 * # `/datum/component/clothing_style_cycle/Initialize`
 *
 * Args:
 * 	base_name				For `src.base_name`. Accepts a string.
 * 	make_ability_buttons	If `FALSE`, don't create ability buttons. Will require manually cycling styles by using the clothing item in-hand.
 * 	list/styles				For `src.styles`. Accepts either a list of type paths for instances of `/datum/clothing_style_element` or, alternatively,
 * 							a simple list of styles to cycle between.
 */
/datum/component/clothing_style_cycle/Initialize(base_name = "", make_ability_buttons = FALSE, list/styles = list())
	. = ..()
	if (!istype(src.parent, /obj/item/clothing))
		return COMPONENT_INCOMPATIBLE
	if (!length(styles))
		return COMPONENT_INCOMPATIBLE

	// Validate `list/styles`.
	var/is_simple = TRUE


	src.clothing_item = src.parent
	src.base_name = base_name || src.parent.name

	if (!is_simple)
		var/list/index_buffer = list(1)
		for (var/element_instance in src.styles)


	src.clothing_item.ability_buttons += src.toggle
	src.toggle.the_item = clothing_item
	src.toggle.name = src.toggle.name + " ([clothing_item.name])"
	RegisterSignal(src.parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(cycle_style))
	RegisterSignal(src.parent, COMSIG_ATOM_POST_UPDATE_ICON, PROC_REF(clothing_item_icon))

	if (!length(ability_buttons_to_make))
		return
	for (var/list/ability_button in ability_buttons_to_make)
		var/obj/ability_button/new_ability_button = new ()
		LAZYLISTADD(src.clothing_item.ability_buttons, src.parent)

/datum/component/clothing_style_cycle/proc/cycle_style(atom/movable/thing, mob/user)
	// src.current_style_index = src.current_style_index >= length(src.styles) ? 1 : src.current_style_index + 1
	if (ismob(src.clothing_item.loc))
		var/mob/M = src.clothing_item.loc
		M.set_clothing_icon_dirty()
	src.clothing_item.UpdateIcon()

	// switch (src.styles[src.current_style_index])
	// 	if (UNTUCK)
	// 		user.visible_message("[user] untucks [his_or_her(user)] [src.clothing_item.name] from [his_or_her(user)] trousers.",\
	// 		"You untuck your [src.clothing_item.name] from your trousers.")
	// 	if (HALF_TUCK)
	// 		user.visible_message("[user] half-tucks [his_or_her(user)] [src.clothing_item.name] into [his_or_her(user)] trousers.",\
	// 		"You half-tuck your [src.clothing_item.name] into your trousers.")
	// 	if (FULL_TUCK)
	// 		user.visible_message("[user] fully tucks [his_or_her(user)] [src.clothing_item.name] into [his_or_her(user)] trousers.",\
	// 		"You fully tuck your [src.clothing_item.name] into your trousers.")

/datum/component/clothing_style_cycle/proc/clothing_item_icon()
	src.clothing_item.wear_state = "[src.base_name][src.styles[src.current_style_index] ? "-[src.styles[src.current_style_index]]" : ""]"
	var/next_style = src.styles[(src.current_style_index >= length(src.styles) ? 1 : src.current_style_index + 1)]
	src.toggle.icon_state = "clothing_item[next_style ? "-[next_style]" : ""]"

/datum/component/clothing_style_cycle/UnregisterFromParent()
	UnregisterSignal(src.parent, COMSIG_ITEM_ATTACK_SELF)
	UnregisterSignal(src.parent, COMSIG_ATOM_POST_UPDATE_ICON)
	src.clothing_item.ability_buttons -= src.toggle
	src.clothing_item = null
	qdel(src.toggle)
	src.toggle = null
	. = ..()

ABSTRACT_TYPE(/datum/clothing_style_element)
/datum/clothing_style_element
	var/name = "buttons"
	var/list/states = list()

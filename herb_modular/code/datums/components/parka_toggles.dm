/// Allows for the toggling of a hood and buttoning of a /obj/item/clothing/suit
/datum/component/toggle_hood_coat
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/item/clothing/suit/suit = null
	// Pertaining to the hood.
	var/hooded = FALSE
	var/hood_style = null
	var/obj/ability_button/herb/hood_toggle/hood_toggle = new
	// Pertaining to the buttoned/unbuttoned states.
	var/buttoned = null
	var/coat_style = null
	var/obj/ability_button/herb/coat_toggle/coat_toggle = new

/datum/component/toggle_hood_coat/Initialize(hooded, buttoned, hood_style, coat_style)
	. = ..()
	if(!istype(parent, /obj/item/clothing/suit))
		return COMPONENT_INCOMPATIBLE
	src.hooded = hooded
	src.hood_style = hood_style
	src.buttoned = buttoned
	src.coat_style = coat_style
	src.suit = parent
	LAZYLISTADD(suit.ability_buttons, parent)
	suit.ability_buttons += hood_toggle
	hood_toggle.the_item = suit
	hood_toggle.name = hood_toggle.name + " ([suit.name])"
	suit.ability_buttons += coat_toggle
	coat_toggle.the_item = suit
	coat_toggle.name = coat_toggle.name + " ([suit.name])"
	// ATTACK_SELF can (and should) only do one thing, so it'll toggle coat buttoning.
	RegisterSignals(parent, list(COMSIG_ITEM_ATTACK_SELF, COMSIG_SUIT_BUTTON), .proc/button_coat)
	RegisterSignal(parent, COMSIG_SUIT_HOOD, .proc/flip_hood)
	RegisterSignal(parent, COMSIG_ATOM_POST_UPDATE_ICON, .proc/update_suit_icon)

/datum/component/toggle_hood_coat/proc/flip_hood(atom/movable/thing, mob/user)
	src.hooded = !src.hooded
	src.suit.over_hair = !src.suit.over_hair
	src.suit.body_parts_covered ^= HEAD
	if (ismob(src.suit.loc))
		var/mob/M = src.suit.loc
		M.set_clothing_icon_dirty()
	src.suit.UpdateIcon()
	user.visible_message("[user] flips [his_or_her(user)] [src.suit.name]'s hood.")

/datum/component/toggle_hood_coat/proc/button_coat(atom/movable/thing, mob/user)
	src.buttoned = !src.buttoned
	if (ismob(src.suit.loc))
		var/mob/M = src.suit.loc
		M.set_clothing_icon_dirty()
	src.suit.UpdateIcon()
	if (src.buttoned == TRUE)
		user.visible_message("[user] buttons [his_or_her(user)] [src.suit.name].",\
		"You button your [src.suit.name].")
	else
		user.visible_message("[user] unbuttons [his_or_her(user)] [src.suit.name].",\
		"You unbutton your [src.suit.name].")

/datum/component/toggle_hood_coat/proc/update_suit_icon()
	if(src.coat_style != suit.coat_style) //making sure this coat_style is the same as the actual object's
		src.coat_style = suit.coat_style
	hood_toggle.icon_state = "hood_[src.hooded ? "down" : "up"]"
	var/icon_state_suffix_buffer
	if (!src.buttoned)
		icon_state_suffix_buffer += "_o"
	if (src.hooded)
		icon_state_suffix_buffer += "-up"
	suit.icon_state = "[src.hood_style][icon_state_suffix_buffer]"

/datum/component/toggle_hood_coat/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ITEM_ATTACK_SELF,
		COMSIG_SUIT_HOOD,
		COMSIG_SUIT_BUTTON,
		COMSIG_ATOM_POST_UPDATE_ICON
	))
	suit.ability_buttons -= hood_toggle
	suit.ability_buttons -= coat_toggle
	suit = null
	qdel(hood_toggle)
	qdel(coat_toggle)
	hood_toggle = null
	coat_toggle = null
	. = ..()

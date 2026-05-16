/datum/mind
	/// Currently held passport, for Nations.
	var/obj/item/passport/passport = null

/datum/mind/proc/set_passport(obj/item/passport/passport)
	qdel(src.passport)
	src.passport = passport

/obj/item/passport
	name = "passport"
	desc = "An identity document confirming its owner's citizenship or lack thereof."
	icon = 'icons/obj/items/passport.dmi'
	icon_state = "passport-base"
	inhand_image_icon = 'icons/mob/inhand/hand_books.dmi'
	item_state = "book"
	w_class = W_CLASS_TINY
	layer = OBJ_LAYER
	throwforce = 0
	throw_speed = 3
	throw_range = 15

	var/datum/nation/nation_type = null
	var/datum/nation/nation = null
	var/datum/mind/owner = null
	var/custom_name = FALSE

	var/base_name = ""
	var/owner_name = ""
	var/icon/owner_icon = null

/obj/item/passport/New(newLoc, datum/mind/owner_to_assign, give_antag_role = TRUE)
	. = ..()

	if (src.nation_type)
		src.nation = global.get_singleton(src.nation_type)

	if (!src.custom_name && src.nation)
		src.base_name = "passport ([src.nation.name])"

	if (!ismind(owner_to_assign))
		return

	src.owner = owner_to_assign
	src.owner.set_passport(src)

	if (give_antag_role)
		src.owner.add_antagonist(src.nation.citizen_role, respect_mutual_exclusives = FALSE)

	src.set_owner_name()

	src.owner_icon = src.owner.current.build_flat_icon(SOUTH)

/obj/item/passport/disposing()
	if (src.owner && (src.owner.passport == src))
		src.owner.set_passport(null)

	. = ..()

/obj/item/passport/attack_self(mob/user)
	src.add_fingerprint(user)
	switch (tgui_alert(user, "What would you like to do with [src]?", "Use [src]", list("Show", "View", "Cancel")))
		if ("Cancel")
			return
		if ("Show")
			src.show_passport(user)
		if ("View")
			src.examine(user)

/obj/item/passport/examine(mob/user)
	. = ..()
	src.ui_interact(user)

/obj/item/passport/ui_interact(mob/user, datum/tgui/ui)
  ui = tgui_process.try_update_ui(user, src, ui)
  if (!ui)
    ui = new(user, src, "Passport")
    ui.open()

/obj/item/passport/ui_data(mob/user)
	. = list(
		"isLeader" = src.nation?.leader == user.mind ? TRUE : FALSE,
		"isOwner" = src.owner == user.mind ? TRUE : FALSE,
		"nationColor" = src.nation?.passport_color,
		"nationName" = src.nation?.name,
		"nationShortName" = src.nation?.short_name,
		"ownerRoleType" = src.get_owner_role_type(),
	)

/obj/item/passport/ui_static_data(mob/user)
	. = list(
		"name" = src.name,
		"ownerName" = src.owner_name,
		"ownerIcon" = icon2base64(src.owner_icon),
	)

/obj/item/passport/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return
	// switch (action)

/obj/item/passport/proc/show_passport(mob/user)
	if (ON_COOLDOWN(user, "showoff_item", SHOWOFF_COOLDOWN))
		return

	user.visible_message("[user] shows you [his_or_her(user)] [bicon(src)] [src.name].", "You show off your passport. [bicon(src)]")
	src.add_fingerprint(user)
	actions.start(new /datum/action/show_item(user, src, "passport", 5, 3), user)

/obj/item/passport/proc/set_owner_name()
	if (!src.owner)
		return
	src.owner_name = src.owner.current?.real_name
	src.name = "[src.owner_name]’s [src.base_name]"

// todo: extract the role type from /datum/antagonist/nation/var/role_type
/obj/item/passport/proc/get_owner_role_type()
	. = ""

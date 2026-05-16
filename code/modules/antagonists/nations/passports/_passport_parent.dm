/datum/mind
	/// Currently held passport, for Nations.
	var/obj/item/passport/passport = null

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
	var/datum/mind/owner = null
	var/minimap_type = 0
	var/minimap_marker = null
	var/custom_name = FALSE

	var/base_name = ""
	var/owner_name = ""
	var/icon/owner_icon = null

/obj/item/passport/New(newLoc, datum/mind/owner_to_assign)
	. = ..()

	if (src.minimap_marker)
		src.AddComponent(/datum/component/minimap_marker/minimap, (MAP_NATIONS_UN | src.minimap_type), src.minimap_marker, list_on_ui = FALSE)

	if (!src.custom_name && src.nation_type)
		src.base_name = "passport ([src.nation_type::name])"

	if (!ismind(owner_to_assign))
		return

	src.owner = owner_to_assign
	src.owner.passport = src

	src.set_owner_name()

	src.owner_icon = src.owner.current.build_flat_icon(SOUTH)

/obj/item/passport/disposing()
	src.owner?.passport = null
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
		"isLeader" = src.nation_type?.leader == user.mind ? TRUE : FALSE, // todo: doesn't presently work as src.nation_type is a type path not instance
		"isOwner" = src.owner == user.mind ? TRUE : FALSE,
		"nationColor" = src.nation_type?.passport_color,
		"nationName" = src.nation_type?.name,
		"nationShortName" = src.nation_type?.short_name,
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

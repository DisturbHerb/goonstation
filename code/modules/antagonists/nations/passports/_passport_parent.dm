/datum/mind
	/// Currently held passport, for Nations.
	var/obj/item/passport/passport = null

/datum/mind/proc/set_passport(obj/item/passport/passport)
	if (src.passport)
		astype(src.passport.loc, /mob)?.u_equip(src.passport)
		src.passport.set_loc(null)
		qdel(src.passport)

	src.passport = passport


ABSTRACT_TYPE(/obj/item/passport)
/obj/item/passport
	name = "passport"
	desc = "An identity document confirming its owner's citizenship."
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

	var/minimap_type = 0
	var/minimap_marker = null

	var/custom_name = FALSE
	var/document_type = "Passport"
	var/base_name = ""

	var/owner_name = ""
	var/icon/owner_icon = null

/obj/item/passport/New(newLoc, datum/mind/owner_to_assign, give_antag_role = TRUE)
	. = ..()

	if (!ispath(src.nation_type))
		qdel(src)
		CRASH("Cannot instantiate a nationless passport.")

	if (!istype(owner_to_assign))
		qdel(src)
		CRASH("Cannot instantiate passport without an owner.")

	src.nation = global.get_singleton(src.nation_type)

	if (src.minimap_marker)
		src.AddComponent(/datum/component/minimap_marker/minimap, (MAP_NATIONS_UN | src.minimap_type), src.minimap_marker, list_on_ui = FALSE)

	if (src.custom_name)
		src.base_name = src.name
	else
		src.base_name = "passport ([src.nation.name])"

	src.owner = owner_to_assign
	src.owner.set_passport(src)
	src.set_owner_name()
	src.owner_icon = src.owner.current.build_flat_icon(SOUTH)

	if (give_antag_role)
		src.owner.add_antagonist(src.nation.citizen_role, respect_mutual_exclusives = FALSE)

/obj/item/passport/disposing()
	if (src.owner.passport == src)
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
		"isLeader" = src.nation.is_leader(user.mind),
	)

/obj/item/passport/ui_static_data(mob/user)
	. = list(
		"documentType" = src.document_type,
		"isOwner" = (src.owner == user.mind),
		"name" = src.name,
		"nationColor" = src.nation.nation_color,
		"nationName" = src.nation.name,
		"nationShortName" = src.nation.get_short_name(),
		"ownerIcon" = icon2base64(src.owner_icon),
		"ownerName" = src.owner_name,
		"ownerRoleType" = src.nation.get_role_type(owner),
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
	src.owner_name = src.owner.current?.real_name
	src.name = "[src.owner_name]’s [src.base_name]"

// don't forget to implement support for variants having different prices bestie <3

/// A verbose list containing every single parent item and its variants and detail types.
var/list/list/clothingbooth_stock_item_list = list()
/// Condensed information on the essential information concerning a given parent item.
var/list/list/clothingbooth_stock_information_list = list()

/proc/build_clothingbooth_caches()
	var/list/list/list/list/item_list_buffer = list()
	var/list/list/information_list_buffer = list()

	// Generate the verbose list of all the `clothingbooth_item` types, indexed by the
	for(var/clothingbooth_list_entry in concrete_typesof(/datum/clothingbooth_item))
		var/datum/clothingbooth_item/current_item = new clothingbooth_list_entry
		if (!istype(current_item, /datum/clothingbooth_item))
			continue

		if (!item_list_buffer[current_item.name])
			item_list_buffer[current_item.name] += list(
				"name" = current_item.name,
				"season" = current_item.season,
				"slot" = current_item.slot,
				"slot_name" = slot_macro_to_string(current_item.slot),
				"variants" = list(),
			)
		var/list/list/item_list_buffer_entry = item_list_buffer[current_item.name]
		if (!item_list_buffer_entry["variants"][current_item.variant_name])
			item_list_buffer_entry["variants"][current_item.variant_name] += list(
				"variant_name" = current_item.variant_name,
				"variant_color" = current_item.variant_color,
				"variant_color_hsl" = current_item.variant_color_hsl,
				"variant_list_place" = current_item.variant_list_place,
				"details" = list(),
				"cost" = current_item.cost,
			)
		if (current_item.initial_variant || !item_list_buffer_entry["initial_variant"])
			item_list_buffer_entry["initial_variant"] = current_item.variant_name
		if (current_item.detail_name)
			item_list_buffer_entry["variants"][current_item.variant_name]["details"][current_item.detail_name] += list(
				"detail_name" = current_item.detail_name,
				"detail_color" = current_item.detail_color,
				"detail_color_hsl" = current_item.detail_color_hsl,
				"detail_list_place" = current_item.detail_list_place,
				"item_path_name" = "[current_item.item_path]",
			)
			if (current_item.initial_detail)
				item_list_buffer_entry["variants"][current_item.variant_name]["initial_detail"] = current_item.detail_name
		else
			item_list_buffer_entry["variants"][current_item.variant_name]["item_path_name"] = "[current_item.item_path]"

	global.clothingbooth_stock_item_list = item_list_buffer

	// Generate a significantly smaller list of
	for (var/item_list_key in item_list_buffer)
		var/list/current_item_list_entry = global.clothingbooth_stock_item_list[item_list_key]
		if (!current_item_list_entry)
			continue

		// Determine the price range for a given stocklist entry.
		var/current_entry_cost_min
		var/current_entry_cost_max
		for (var/variant_list_key in current_item_list_entry["variants"])
			var/current_variant_cost = current_item_list_entry["variants"][variant_list_key]["cost"]
			if (!current_entry_cost_min || (current_entry_cost_min && current_variant_cost < current_entry_cost_min))
				current_entry_cost_min = current_variant_cost
			if (!current_entry_cost_max || (current_entry_cost_max && current_variant_cost > current_entry_cost_max))
				current_entry_cost_max = current_variant_cost

		// Get an image for the entry. Will draw from the initial variant and the initial detail if applicable.
		var/current_entry_atom_path = /obj/item/clothing/under/color/white
		var/current_entry_initial_variant = current_item_list_entry["variants"][current_item_list_entry["initial_variant"]]
		var/detail_index = current_entry_initial_variant["initial_detail"] ? current_entry_initial_variant["initial_detail"] : 1
		if (length(current_entry_initial_variant["details"]))
			current_entry_atom_path = current_entry_initial_variant["details"][detail_index]["item_path"]
		else
			current_entry_atom_path = current_entry_initial_variant["item_path"]
		var/atom/dummy_atom = current_entry_atom_path
		var/icon/dummy_icon = icon(initial(dummy_atom.icon), initial(dummy_atom.icon_state), frame = 1)
		var/current_entry_image = icon2base64(dummy_icon)

		information_list_buffer[current_item_list_entry["name"]] += list(
			"image" = current_entry_image,
			"season" = current_item_list_entry["season"],
			"slot_name" = current_item_list_entry["slot_name"],
			"initial_variant" = current_item_list_entry["initial_variant"],
			"variant_count" = length(current_item_list_entry["variants"]),
			"cost_min" = current_entry_cost_min,
			"cost_max" = current_entry_cost_max,
		)

	global.clothingbooth_stock_information_list = information_list_buffer

/proc/slot_macro_to_string(slot_macro)
	switch (slot_macro)
		if (SLOT_BACK)
			. = "Back"
		if (SLOT_WEAR_MASK)
			. = "Mask"
		if (SLOT_BELT)
			. = "Belt"
		if (SLOT_WEAR_ID)
			. = "ID"
		if (SLOT_EARS)
			. = "Ears"
		if (SLOT_GLASSES)
			. = "Glasses"
		if (SLOT_GLOVES)
			. = "Gloves"
		if (SLOT_HEAD)
			. = "Headwear"
		if (SLOT_SHOES)
			. = "Shoes"
		if (SLOT_WEAR_SUIT)
			. = "Suit"
		if (SLOT_W_UNIFORM)
			. = "Uniform"

// clothing booth stuffs <3
/obj/machinery/clothingbooth
	name = "Clothing Booth"
	desc = "Contains a sophisticated autoloom system capable of manufacturing a variety of clothing items on demand."
	icon = 'icons/obj/vending.dmi'
	icon_state = "clothingbooth-open"
	flags = FPRINT | TGUI_INTERACTIVE
	anchored = ANCHORED
	density = 1
	var/datum/light/ambient_light

	// Preview and purchase-related.
	var/datum/clothingbooth_item/item_to_purchase = null
	var/datum/movable_preview/character/multiclient/preview
	var/mob/living/carbon/human/occupant
	var/obj/item/preview_item = null
	var/preview_direction_default = SOUTH
	/// This is set to `src.preview_direction_default` on New() and whenever a new occupant is added. This can be rotated in the UI.
	var/current_preview_direction

	/// Amount of inserted cash; presently, only cash is accepted.
	var/money = 0
	/// `src` can only be entered if `src.open` is TRUE.
	var/open = TRUE

	New()
		..()
		UnsubscribeProcess()
		src.ambient_light = new /datum/light/point
		src.ambient_light.attach(src)
		src.ambient_light.set_brightness(0.6)
		src.ambient_light.set_height(1.5)
		src.ambient_light.enable()
		src.preview = new()
		src.preview.add_background()
		src.current_preview_direction = src.preview_direction_default

	attackby(obj/item/W, mob/user)
		if(istype(W, /obj/item/currency/spacecash))
			if(!(locate(/mob) in src))
				src.money += W.amount
				W.amount = 0
				user.visible_message("<span class='notice'>[user.name] inserts credits into [src]")
				playsound(user, 'sound/machines/capsulebuy.ogg', 80, TRUE)
				user.u_equip(W)
				W.dropped(user)
				qdel(W)
			else
				boutput(user,"<span style=\"color:red\">It seems the clothing booth is currently occupied. Maybe it's better to just wait.</span>")

		else if (istype(W, /obj/item/grab))
			var/obj/item/grab/G = W
			if (ismob(G.affecting))
				var/mob/GM = G.affecting
				if (src.open)
					GM.set_loc(src)
					src.occupant = GM
					src.preview.add_client(GM.client)
					src.update_preview()
					ui_interact(GM)
					user.visible_message("<span class='alert'><b>[user] stuffs [GM.name] into [src]!</b></span>","<span class='alert'><b>You stuff [GM.name] into [src]!</b></span>")
					src.close()
					qdel(G)
					logTheThing(LOG_COMBAT, user, "places [constructTarget(GM,"combat")] into [src] at [log_loc(src)].")
		else
			..()

	attack_hand(mob/user)
		if (!ishuman(user))
			boutput(user,"<span style=\"color:red\">Human clothes don't fit you!</span>")
			return
		if (!IN_RANGE(user, src, 1))
			return
		if (!can_act(user))
			return
		if (open)
			user.set_loc(src.loc)
			SPAWN(0.5 SECONDS)
				if (!open) return
				user.set_loc(src)
				src.close()
				src.occupant = user
				src.preview.add_client(user.client)
				src.update_preview()
				ui_interact(user)
		else
			SETUP_GENERIC_ACTIONBAR(user, src, 10 SECONDS, PROC_REF(eject), null, src.icon, src.icon_state, "[user] forces open [src]!", INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ACTION)

	Click()
		if((usr in src) && (src.open == 0))
			if(istype(usr.equipped(),/obj/item/currency/spacecash))
				var/obj/item/dummycredits = usr.equipped()
				src.money += dummycredits.amount
				dummycredits.amount = 0
				qdel(dummycredits)
			src.ui_interact(usr)
		..()

	disposing()
		qdel(src.preview)
		qdel(src.preview_item)
		qdel(src.item_to_purchase)
		..()

	relaymove(mob/user as mob)
		if (!isalive(user))
			return
		eject(user)

	ui_interact(mob/user, datum/tgui/ui)
		if(!user.client)
			return
		if(!ishuman(user))
			return
		ui = tgui_process.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "ClothingBooth")
			ui.open()

	ui_close(mob/user)
		. = ..()
		if (!isnull(src.preview_item))
			qdel(src.preview_item)
			src.preview_item = null

	ui_static_data(mob/user)
		. = list(
			"name" = src.name
		)

	ui_data(mob/user)
		var/icon/preview_icon = getFlatIcon(src.preview.preview_thing, no_anim = TRUE)
		. = list(
			"money" = src.money,
			"previewIcon" = icon2base64(preview_icon),
			"previewHeight" = preview_icon.Height(),
			"previewItem" = src.preview_item,
			"selectedItemCost" = src.item_to_purchase?.cost,
			"selectedItemName" = src.item_to_purchase?.name
		)

	ui_act(action, params)
		. = ..()
		if (. || !(usr in src.contents))
			return

		switch(action)
			if("purchase")
				if(src.item_to_purchase)
					if(text2num_safe(src.item_to_purchase.cost) <= src.money)
					else
						boutput(usr, "<span class='alert'>Insufficient funds!</span>")
						animate_shake(src, 12, 3, 3)
					. = TRUE
				else
					boutput(usr, "<span class='alert'>No item selected!</span>")
			if ("rotate-cw")
				src.current_preview_direction = turn(src.current_preview_direction, -90)
				update_preview()
				. = TRUE
			if ("rotate-ccw")
				src.current_preview_direction = turn(src.current_preview_direction, 90)
				update_preview()
				. = TRUE
			if("select")
				update_preview()
				. = TRUE

	/// open the booth
	proc/open()
		flick("clothingbooth-opening", src)
		src.icon_state = "clothingbooth-open"
		src.open = TRUE

	/// close the booth
	proc/close()
		flick("clothingbooth-closing", src)
		src.icon_state = "clothingbooth-closed"
		src.open = FALSE

	/// ejects occupant if any along with any contents
	proc/eject(mob/occupant)
		if (open) return
		open()
		SPAWN(2 SECONDS)
			qdel(src.preview_item)
			qdel(src.item_to_purchase)
			src.preview.remove_all_clients()
			src.current_preview_direction = src.preview_direction_default
			src.item_to_purchase = null
			tgui_process.close_uis(src)
			var/turf/T = get_turf(src)
			if (!occupant)
				occupant = locate(/mob/living/carbon/human) in src
			if (occupant?.loc == src) //ensure mob wasn't otherwise removed during out spawn call
				occupant.set_loc(T)
				if(src.money > 0)
					occupant.put_in_hand_or_drop(new /obj/item/currency/spacecash(T, src.money))
				src.money = 0
				for (var/obj/item/I in src.contents)
					occupant.put_in_hand_or_drop(I)
				for (var/atom/movable/AM in contents)
					AM.set_loc(T) //dump anything that's left in there on out
			else
				if(src.money > 0)
					new /obj/item/currency/spacecash(T, src.money)
				src.money = 0
				for (var/atom/movable/AM in contents)
					AM.set_loc(T)

	/// generates a preview of the current occupant
	proc/update_preview()
		src.preview.update_appearance(src.occupant.bioHolder.mobAppearance, src.occupant.mutantrace, src.current_preview_direction, src.occupant.real_name)

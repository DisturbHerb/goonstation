/// A verbose list containing every single parent item and its variants and detail types.
var/list/list/clothingbooth_stock_item_list = list()
/// Condensed information on the essential information concerning a given parent item.
var/list/list/clothingbooth_stock_information_list = list()

/proc/build_clothingbooth_caches()
	// Generate the verbose list of all the `clothingbooth_item` types, indexed by the name of the item.
	var/list/list/list/list/item_list_buffer = list()
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

	// Generate an abridged list for displaying the clothingbooth stock on the player-facing list.
	var/list/list/information_list_buffer = list()
	for (var/item_list_key in global.clothingbooth_stock_item_list)
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
			"name" = current_item_list_entry["name"],
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

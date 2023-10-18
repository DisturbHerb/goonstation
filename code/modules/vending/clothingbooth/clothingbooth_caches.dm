/// A verbose list containing every single parent item and its variants and detail types.
var/list/list/clothingbooth_stock_list = list()
/// Condensed information on the essential information concerning a given parent item.
var/list/list/clothingbooth_stock_information = list()

/// Executed at runtime to generate the global lists `clothingbooth_stock_list` and `clothingbooth_stock_information`.
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
				"variants" = list(),
			)
		var/list/list/item_list_buffer_entry = item_list_buffer[current_item.name]
		if (!item_list_buffer_entry["variants"][current_item.variant_name])
			item_list_buffer_entry["variants"][current_item.variant_name] += list(
				"variantName" = current_item.variant_name,
				"variantColor" = current_item.variant_color,
				"details" = list(),
				"cost" = current_item.cost,
			)
		if (current_item.detail_name)
			item_list_buffer_entry["variants"][current_item.variant_name]["details"][current_item.detail_name] += list(
				"detailName" = current_item.detail_name,
				"detailColor" = current_item.detail_color,
				"itemPath" = current_item.item_path,
			)
		else
			item_list_buffer_entry["variants"][current_item.variant_name]["itemPath"] = current_item.item_path

	global.clothingbooth_stock_list = item_list_buffer

	// Generate an abridged list for displaying the clothingbooth stock on the player-facing list.
	var/list/list/information_list_buffer = list()
	for (var/item_list_key in global.clothingbooth_stock_list)
		var/list/current_item_list_entry = global.clothingbooth_stock_list[item_list_key]
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
		var/current_entry_initial_variant = current_item_list_entry["variants"][1]
		if (length(current_entry_initial_variant["details"]))
			current_entry_atom_path = current_entry_initial_variant["details"][detail_index]["itemPath"]
		else
			current_entry_atom_path = current_entry_initial_variant["itemPath"]
		var/atom/dummy_atom = current_entry_atom_path
		var/icon/dummy_icon = icon(initial(dummy_atom.icon), initial(dummy_atom.icon_state), frame = 1)
		var/current_entry_image = icon2base64(dummy_icon)

		information_list_buffer[current_item_list_entry["name"]] += list(
			"name" = current_item_list_entry["name"],
			"image" = current_entry_image,
			"season" = current_item_list_entry["season"],
			"slot" = current_item_list_entry["slot"],
			"variantCount" = length(current_item_list_entry["variants"]),
			"costMin" = current_entry_cost_min,
			"costMax" = current_entry_cost_max,
		)

	global.clothingbooth_stock_information = information_list_buffer

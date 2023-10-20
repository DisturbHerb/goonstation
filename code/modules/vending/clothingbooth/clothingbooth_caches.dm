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
				"overrideDisplayOrder" = current_item.override_display_order,
				"variants" = list(),
			)
		var/list/list/item_list_buffer_entry = item_list_buffer[current_item.name]
		if (!item_list_buffer_entry["variants"][current_item.variant_name])
			item_list_buffer_entry["variants"][current_item.variant_name] += list(
				"variantName" = current_item.variant_name,
				"variantBackgroundColor" = current_item.variant_background_color,
				"variantForegroundColor" = current_item.variant_foreground_color,
				"cost" = current_item.cost,
				"itemPath" = current_item.item_path,
			)

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

		// Get an image for the entry.
		var/list/current_entry_initial_variant = current_item_list_entry["variants"][current_item_list_entry["variants"][1]]
		if (!current_item_list_entry["overrideDisplayOrder"])
			// Iterate over all the variants to find the one with the lowest hue. Use the item_path for that one instead.
			// Actually sorting by hue is gonna be handled on the jsx/inferno side because I just can't anymore.
			// HSL is a scalar from 0 to 255, right?
			var/lowest_hue = 255
			for (var/variant_list_key in current_item_list_entry["variants"])
				// Get the hue of the the variant.
				var/list/current_entry_hsl = rgb2num(current_item_list_entry["variants"][variant_list_key]["variantBackgroundColor"], COLORSPACE_HSL)
				if (current_entry_hsl[1] >= lowest_hue)
					continue
				lowest_hue = current_entry_hsl[1]
				current_entry_initial_variant = current_item_list_entry["variants"][variant_list_key]
		var/current_entry_atom_path = current_entry_initial_variant["itemPath"] ? current_entry_initial_variant["itemPath"] : /obj/item/clothing/under/color/white
		var/atom/dummy_atom = current_entry_atom_path
		var/icon/dummy_icon = icon(initial(dummy_atom.icon), initial(dummy_atom.icon_state), frame = 1)
		var/current_entry_image = icon2base64(dummy_icon)

		information_list_buffer[current_item_list_entry["name"]] += list(
			"name" = current_item_list_entry["name"],
			"image" = current_entry_image,
			"season" = current_item_list_entry["season"],
			"slot" = current_item_list_entry["slot"],
			"initialVariant" = current_entry_initial_variant["variantName"],
			"variantCount" = length(current_item_list_entry["variants"]),
			"costMin" = current_entry_cost_min,
			"costMax" = current_entry_cost_max,
		)

	global.clothingbooth_stock_information = information_list_buffer

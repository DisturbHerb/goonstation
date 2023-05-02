//the random offset applied to square coordinates, causes intermingling at biome borders
//#define BIOME_RANDOM_SQUARE_DRIFT 2

// Used to select "zoom" level into the perlin noise, higher numbers result in slower transitions
#define PERLIN_ZOOM 130

// Turfs with a height value above this but below ICE_THRESHOLD will be rough snow tiles.
#define ROUGH_SNOW_THRESHOLD 0.4
// Turfs with a height value above this but below MOUNTAIN_THRESHOLD will be ice tiles.
#define ICE_THRESHOLD 0.5
// Turfs with a height value above this will become mountain turfs.
#define MOUNTAIN_THRESHOLD 0.55
// -38C and lowest breathable temperature with standard atmos
#define PLANET_TEMPERATURE 235

/datum/map_generator/snow_crater_generator
	///2D list of all biomes based on heat and humidity combos.
	var/list/possible_biomes = list(
	BIOME_LOW_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/mudlands,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/snow,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/snow/rocky,
		BIOME_HIGH_HUMIDITY = /datum/biome/snow/rough,
		),

	BIOME_LOWMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/snow/rocky,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/snow,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/snow/rough,
		BIOME_HIGH_HUMIDITY = /datum/biome/snow/forest
		),
	BIOME_HIGHMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/snow,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/snow/rough,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/snow/forest,
		BIOME_HIGH_HUMIDITY = /datum/biome/snow/forest/thick
		),
	// Hah! High heat? Surely you must be joking!
	BIOME_HIGH_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/snow/rough,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/snow/forest,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/snow/forest,
		BIOME_HIGH_HUMIDITY = /datum/biome/snow/forest/thick
		)
	)
	///Used to select "zoom" level into the perlin noise, higher numbers result in slower transitions
	var/perlin_zoom = PERLIN_ZOOM
	var/icon/height_map = icon('herb_module/icons/misc/crater_heightmap.dmi')
	wall_turf_type	= /turf/simulated/wall/auto/asteroid/mountain
	floor_turf_type = /turf/simulated/floor/plating/airless/asteroid/mountain

///Seeds the rust-g perlin noise with a random number.
/datum/map_generator/snow_crater_generator/generate_terrain(list/turfs, reuse_seed, flags)
	. = ..()
	var/humidity_seed = seeds[2]
	var/heat_seed = seeds[3]

	for(var/t in turfs) //Go through all the turfs and generate them
		var/turf/gen_turf = t
		var/drift_x = (gen_turf.x + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom
		var/drift_y = (gen_turf.y + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom

		// Fetches the rgb value of a pixel on the heightmap icon_state at the given turf co-ordinates, then uses that value as the height.
		// All of this extra guff is to ensure that the image is in greyscale by checking that the average of all the channels is equal to some
		// arbitrarily chosen channel and to fail the terrain generation if it isn't.
		var/list/heightmap_colours = rgb2num(src.height_map.GetPixel(gen_turf.x, gen_turf.y, "heightmap"))
		var/sum_of_colour_channels = null
		for(var/channel in heightmap_colours)
			sum_of_colour_channels += channel
		var/average_channel_value = sum_of_colour_channels / length(heightmap_colours)
		if(average_channel_value != heightmap_colours[1])
			message_admins("Crater generation failed, heightmap has non-grey value.")
			return
		// Convert the colour channel from a value between 0 and 255 to a height value between 0 and 1.
		var/height = heightmap_colours[1] / 255

		var/datum/biome/selected_biome
		switch(height)
			if(0 to ROUGH_SNOW_THRESHOLD) //If height is less than ROUGH_SNOW_THRESHOLD, we generate biomes based on the heat and humidity of the area.
				var/humidity = text2num(rustg_noise_get_at_coordinates("[humidity_seed]", "[drift_x]", "[drift_y]"))
				var/heat = text2num(rustg_noise_get_at_coordinates("[heat_seed]", "[drift_x]", "[drift_y]"))
				var/heat_level //Type of heat zone we're in LOW-MEDIUM-HIGH
				var/humidity_level  //Type of humidity zone we're in LOW-MEDIUM-HIGH

				switch(heat)
					if(0 to 0.35)
						heat_level = BIOME_LOW_HEAT
					if(0.35 to 0.65)
						heat_level = BIOME_LOWMEDIUM_HEAT
					if(0.65 to 0.9)
						heat_level = BIOME_HIGHMEDIUM_HEAT
					if(0.9 to 1)
						heat_level = BIOME_HIGH_HEAT
				switch(humidity)
					if(0 to 0.2)
						humidity_level = BIOME_LOW_HUMIDITY
					if(0.2 to 0.5)
						humidity_level = BIOME_LOWMEDIUM_HUMIDITY
					if(0.5 to 0.75)
						humidity_level = BIOME_HIGHMEDIUM_HUMIDITY
					if(0.75 to 1)
						humidity_level = BIOME_HIGH_HUMIDITY
				selected_biome = possible_biomes[heat_level][humidity_level]
			if(ROUGH_SNOW_THRESHOLD to ICE_THRESHOLD)
				selected_biome = /datum/biome/snow/rough
			if(ICE_THRESHOLD to MOUNTAIN_THRESHOLD) //Between ICE_THRESHOLD and MOUNTAIN_THRESHOLD, it's rough ice.
				selected_biome = /datum/biome/water/ice/rough
			if(MOUNTAIN_THRESHOLD to 1) //Over MOUNTAIN_THRESHOLD; It's a mountain
				selected_biome = /datum/biome/mountain
		selected_biome = biomes[selected_biome]
		selected_biome.generate_turf(gen_turf, flags)

		gen_turf.temperature = PLANET_TEMPERATURE

		if (current_state >= GAME_STATE_PLAYING)
			LAGCHECK(LAG_LOW)
		else
			LAGCHECK(LAG_HIGH)

/datum/terrainify/craterify
	name = "Crater Station"
	desc = "Turns space into a colder snowy place"
	additional_options = list("Weather"=list("Snow", "Light Snow", "None"), "Mining"=list("None","Normal","Rich"))
	additional_toggles = list("Ambient Light Obj")

	convert_station_level(params, datum/tgui/ui)
		if(..())
			var/const/ambient_light = "#222"
			station_repair.station_generator = new/datum/map_generator/snow_crater_generator

			if(params["Ambient Light Obj"])
				station_repair.ambient_obj = new /obj/ambient
				station_repair.ambient_obj.color = ambient_light
			else
				station_repair.ambient_light = new /image/ambient
				station_repair.ambient_light.color = ambient_light

			station_repair.default_air.temperature = PLANET_TEMPERATURE

			var/snow = params["Weather"]
			snow = (snow == "None") ? null : snow
			if(snow == "Light Snow")
				station_repair.weather_effect = /obj/effects/precipitation/snow/grey/tile/light
			else if(snow == "Snow")
				station_repair.weather_effect = /obj/effects/precipitation/snow/grey/tile

			var/list/space = list()
			for(var/turf/space/S in block(locate(1, 1, Z_LEVEL_STATION), locate(world.maxx, world.maxy, Z_LEVEL_STATION)))
				space += S
			convert_turfs(space)
			for (var/turf/S as anything in space)
				if(params["Ambient Light Obj"])
					S.vis_contents |= station_repair.ambient_obj
				else
					S.UpdateOverlays(station_repair.ambient_light, "ambient")
				if(snow)
					new station_repair.weather_effect(S)

			// We won't be needing THIS if I pre-bake you!
			// station_repair.clean_up_station_level(params["vehicle"] & TERRAINIFY_VEHICLE_CARS, params["vehicle"] & TERRAINIFY_VEHICLE_FABS)
			handle_mining(params, space)

			logTheThing(LOG_ADMIN, ui.user, "turned space into a cold, desolate hell.")
			logTheThing(LOG_DIARY, ui.user, "turned space into a cold, desolate hell.", "admin")
			message_admins("[key_name(ui.user)] turned space into a cold, desolate hell.")

#undef PERLIN_ZOOM
#undef ICE_THRESHOLD
#undef MOUNTAIN_THRESHOLD
#undef PLANET_TEMPERATURE

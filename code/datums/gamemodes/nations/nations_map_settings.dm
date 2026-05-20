/datum/map_settings/nations
	name = "Nations"
	display_name = "Orbital Platform Geneva"
	default_gamemode = "nations"
	goonhub_map = "/maps/nations"
	walls = /turf/simulated/wall/auto/supernorn
	rwalls = /turf/simulated/wall/auto/reinforced/supernorn
	style = "station"

	Z_LEVEL_PARALLAX_RENDER_SOURCES(1) = list(
		/atom/movable/screen/parallax_render_source/space_1,
		/atom/movable/screen/parallax_render_source/space_2,
		/atom/movable/screen/parallax_render_source/planet/fortuna,
		/atom/movable/screen/parallax_render_source/asteroids_far,
		/atom/movable/screen/parallax_render_source/asteroids_near,
		)

	arrivals_type = MAP_SPAWN_CRYO

	windows = /obj/window/auto
	windows_thin = /obj/window/pyro
	rwindows = /obj/window/auto/reinforced
	rwindows_thin = /obj/window/reinforced/pyro
	windows_crystal = /obj/window/auto/crystal
	windows_rcrystal = /obj/window/auto/crystal/reinforced
	window_layer_full = COG2_WINDOW_LAYER
	window_layer_north = GRILLE_LAYER+0.1
	window_layer_south = FLY_LAYER+1
	auto_windows = TRUE

	escape_centcom = null
	escape_transit = null
	escape_station = null
	escape_dir = NORTH

	merchant_left_centcom = null
	merchant_left_station = null
	merchant_right_centcom = null
	merchant_right_station = null

	valid_nuke_targets = list()

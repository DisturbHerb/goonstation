/datum/map_settings/breaking_ground
	name = "BREAKING_GROUND"
	display_name = "Banshee Trough"
	default_gamemode = "extended"
	walls = /turf/simulated/wall/auto/herb
	rwalls = /turf/simulated/wall/auto/reinforced/herb

	parallax_layers = list(
		/atom/movable/screen/parallax_layer/foreground/snow,
		/atom/movable/screen/parallax_layer/foreground/snow/sparse,
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

	ext_airlocks = /obj/machinery/door/airlock/pyro/classic
	airlock_style = "pyro"

	escape_centcom = null
	escape_transit = null
	escape_station = null
	escape_dir = NORTH

	merchant_left_centcom = null
	merchant_left_station = null
	merchant_right_centcom = null
	merchant_right_station = null

	valid_nuke_targets = list()

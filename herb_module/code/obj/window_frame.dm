/obj/structure/window_frame
	name = "window frame"
	desc = "A big hole in the wall that you can vault over. It could be finished with some crystal sheets to create a window, or disassembled with a wrench."
	icon = 'herb_module/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-0"
	anchored = ANCHORED // Anchored by default.
	density = 1
	flags = FPRINT | USEDELAY | ON_BORDER
	pressure_resistance = 4 * ONE_ATMOSPHERE
	/// Automatically joins with nearby window frames when true.
	var/auto = TRUE

	/// TRUE if there is a window, FALSE if not.
	var/has_window = FALSE
	/// TRUE if there is a grille, FALSE if not.
	var/has_grille = FALSE
	/// Window material, default is glass.
	var/window_material = "glass"
	/// Window reinforcement material, null by default.
	var/datum/material/window_reinforcement_material = null
	/// Grille material, default is steel.
	var/grille_material = "steel"

	Cross(atom/movable/mover)
		// mover can pass over the window frame tile if it has the TABLEPASS flag and there is no window or grille.
		if (mover?.flags & TABLEPASS)
			return TRUE
		var/obj/window_frame = locate(/obj/structrure/window_frame) in mover?.loc
		if (window_frame && !window_frame.has_window && !window_frame.has_grille)
			return TRUE
		return FALSE

	reinforced
		icon = 'herb_module/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-0"

	shuttle
		icon = 'herb_module/icons/obj/structures/shuttle_window_frames.dmi'
		icon_state = "shuttle-0"

/obj/window_frame_spawner
	name = "window frame spawner"
	icon = 'herb_module/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-wingrille"
	// Same properties as normal wingrille spawners.
	density = 1
	anchored = ANCHORED
	invisibility = INVIS_ALWAYS
	/// What's the path of the /obj/structure/window_frame is this associated with?
	var/obj/structure/window_frame/frame_type = /obj/structure/window_frame
	/// What material is the window made of?
	var/window_material = "glass"
	/// Is the window reinforced?
	var/reinforced = FALSE
	/// Window reinforcement material, null by default.
	var/datum/material/window_reinforcement_material = null

	New()
		..()
		if(current_state >= GAME_STATE_WORLD_INIT)
			SPAWN(0)
				initialize()

	initialize()
		. = ..()
		// Check that a window frame doesn't already exist on the current tile.
		if (!locate(text2path(src.frame_type)) in get_turf(src))
			new new_window_frame(src.loc)
		// Delete the spawner.
		qdel(src)

	reinforced
		name = "reinforced window frame wingrille spawner"
		icon = 'herb_module/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-wingrille"
		frame_type = /obj/structure/window_frame/reinforced
		reinforced = TRUE

		plasmaglass
			name = "reinforced plasmaglass window frame wingrille spawner"
			window_material = "plasmaglass"

		shuttle
			name = "shuttle window frame wingrille spawner"
			icon = 'herb_module/icons/obj/structures/shuttle_window_frames.dmi'
			icon_state = "shuttle-wingrille"
			frame_type = /obj/structure/window_frame/shuttle

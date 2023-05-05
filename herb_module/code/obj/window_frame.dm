/obj/structure/window_frame
	name = "window frame"
	desc = "A big hole in the wall that you can vault over. It could be finished with some crystal sheets to create a window, or disassembled with a wrench."
	icon = 'herb_module/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-0"
	anchored = ANCHORED
	flags = FPRINT | USEDELAY | ON_BORDER

	reinforced
		icon = 'herb_module/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-0"


	shuttle
		icon = 'herb_module/icons/obj/structures/shuttle_window_frames.dmi'
		icon_state = "shuttle-0"

/obj/window_frame_wingrille_spawner
	name = "window frame wingrille spawner"
	desc = "yeah dude"
	icon = 'herb_module/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-wingrille"

	reinforced
		name = "reinforced window frame wingrille spawner"
		icon = 'herb_module/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-wingrille"

		shuttle
			name = "shuttle window frame wingrille spawner"
			icon = 'herb_module/icons/obj/structures/shuttle_window_frames.dmi'
			icon_state = "shuttle-wingrille"

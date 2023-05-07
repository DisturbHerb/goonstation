// Window frame state defines.
#define WINDOW_FRAME_STATE_WHOLE 0
#define WINDOW_FRAME_STATE_UNWELDED 1
#define WINDOW_FRAME_STATE_UNSCREWED 2
#define WINDOW_FRAME_STATE_DISLODGED 3
#define WINDOW_FRAME_STATE_UNANCHORED 4

// Tool action defines.
#define WINDOW_FRAME_UNANCHOR 0
#define WINDOW_FRAME_ANCHOR 1
#define WINDOW_FRAME_DISLODGE 2
#define WINDOW_FRAME_LODGE 3
#define WINDOW_FRAME_UNSCREW 4
#define WINDOW_FRAME_SCREW 5
#define WINDOW_FRAME_WELD 6
#define WINDOW_FRAME_UNWELD 7

/**
 * #Window Frames
 * An implemntation of window frames; pretty much just windows and grilles encased by what amounts to half of a wall that you can vault and throw
 * stuff over.
 */
/obj/structure/window_frame
	name = "window frame"
	desc = "A big hole in the wall that you can vault over. It could be finished with some crystal sheets to create a window, or disassembled with a wrench."
	icon = 'herb_modular/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-0"
	layer = TURF_LAYER
	anchored = ANCHORED // Anchored by default.
	density = 1
	flags = FPRINT | USEDELAY | ON_BORDER
	pressure_resistance = 4 * ONE_ATMOSPHERE
	gas_impermeable = FALSE
	explosion_resistance = 1 // Lower default explosion resist in comparison to full walls. It's a big hole, after all.

	/// Automatically joins with nearby window frames when true.
	var/auto = TRUE
	/// Icon state prefix for the purposes of auto-connecting frames.
	var/mod = "wall-"

	/// The health of the window frame.
	var/health = 100
	/// The current state of the window frame itself, using the defines in window_frame.dm
	var/window_frame_state = WINDOW_FRAME_STATE_WHOLE

	// WINDOWS
	/// The window that's currently tied to this frame.
	var/obj/window/auto/framed/framed_window = null

	// GRILLES
	/// TRUE if there is a grille, FALSE if not.
	var/obj/grille/steel/framed/framed_grille = null

	New()
		..()
		if (!islist(src.attached_objs))
			src.attached_objs = list()
		SPAWN(0)
			if (src.auto)
				src.UpdateIcon()

	attackby(obj/item/W, mob/user)
		if (isweldingtool(W))
			/*
			   This is necessary because there's multiple different implementations of welding tools and trying to typecast them all in here seems
			   kind of lame. Sue me. - DisturbHerb
			*/
			if(!W:try_weld(user, 5, burn_eyes = 1))
				return
			else
				switch (src.window_frame_state)
					if (WINDOW_FRAME_STATE_WHOLE)
						actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_UNWELD), user)
					if (WINDOW_FRAME_STATE_UNWELDED)
						actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_WELD), user)
					else
						. = ..()
		else if (isscrewingtool(W))
			switch (src.window_frame_state)
				if (WINDOW_FRAME_STATE_UNWELDED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_UNSCREW), user)
				if (WINDOW_FRAME_STATE_UNSCREWED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_SCREW), user)
				if (WINDOW_FRAME_STATE_DISLODGED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_UNANCHOR), user)
				if (WINDOW_FRAME_STATE_UNANCHORED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_ANCHOR), user)
				else
					. = ..()
		else if (ispryingtool(W))
			switch (src.window_frame_state)
				if (WINDOW_FRAME_STATE_UNSCREWED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_DISLODGE), user)
				if (WINDOW_FRAME_STATE_DISLODGED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_LODGE), user)
				else
					. = ..()
		else
			..()

	/**
	 * All /mob/living/carbon/human types can now jump over the window frame if there isn't a grille or window.
	 * Hulks can jump through no matter what and it'll bust the grille and window open.
	*/
	Bumped(mob/bumpee)
		..()
		if (!src.framed_window || !src.framed_window)
			if (ishuman(bumpee) && isalive(bumpee))
				var/mob/living/carbon/human/human_bumpee = bumpee
				actions.start(new /datum/action/bar/icon/railing_jump/window_frame_jump(human_bumpee, src), human_bumpee)

	Cross(atom/movable/mover)
		// mover can pass over the window frame tile if it has the TABLEPASS flag.
		if (mover?.flags & TABLEPASS)
			return TRUE
		return FALSE

	update_icon()
		if (!src.anchored)
			icon_state = "[mod]0"
			return
		var/connect_dir = get_connected_directions_bitflag(list(src.type), cross_areas = TRUE, connect_diagonal = FALSE)
		icon_state = "[src.mod][connect_dir]"

	meteorhit(obj/M)
		if (src.framed_window)
			src.framed_window.meteorhit(M)
		if (src.framed_grille)
			src.framed_grille.meteorhit(M)
		src.disintegrate()

	/// Spawns some scrap metal and deletes the src when called.
	proc/disintegrate()
		var/obj/item/raw_material/scrap_metal/debris = new /obj/item/raw_material/scrap_metal
		debris.set_loc(src)
		if (src.material)
			debris.setMaterial(src.material)
		else
			debris.setMaterial(getMaterial("steel"), copy = FALSE)
		qdel(src)

	reinforced
		icon = 'herb_modular/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-0"
		mod = "rwall-"
		health = 300
		explosion_resistance = 5

	shuttle
		icon = 'herb_modular/icons/obj/structures/shuttle_window_frames.dmi'
		icon_state = "shuttle-0"
		mod = "shuttle-"

/// Ripped from /datum/action/bar/icon/table_tool_interact
/datum/action/bar/icon/window_frame_tool_interact
	id = "window_frame_tool_interact"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	duration = 5 SECONDS
	icon = 'icons/ui/actions.dmi'
	icon_state = "working"
	var/obj/structure/window_frame/the_window_frame
	var/obj/item/the_tool
	var/interaction = WINDOW_FRAME_UNANCHOR

	New(var/obj/structure/window_frame/targeted_frame, var/obj/item/tool_used, var/desired_interaction)
		..()
		if (targeted_frame)
			src.the_window_frame = targeted_frame
		if (tool_used)
			src.the_tool = tool_used
			src.icon = src.the_tool.icon
			src.icon_state = src.the_tool.icon_state
		if (desired_interaction)
			src.interaction = desired_interaction
		if (ishuman(src.owner))
			var/mob/living/carbon/human/H = src.owner
			if (H.traitHolder.hasTrait("carpenter") || H.traitHolder.hasTrait("training_engineer"))
				src.duration = round(duration / 2)

	onUpdate()
		..()
		if (src.the_window_frame == null || src.the_tool == null || src.owner == null || BOUNDS_DIST(src.owner, the_window_frame) > 0)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/source = owner
		if (istype(source) && the_tool != source.equipped())
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		var/verbing = "doing something to"
		switch (src.interaction)
			if (WINDOW_FRAME_UNWELD)
				verbing = "weakening"
			if (WINDOW_FRAME_WELD)
				verbing = "strengthening"
			if (WINDOW_FRAME_UNSCREW)
				verbing = "unscrewing"
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
			if (WINDOW_FRAME_SCREW)
				verbing = "tightening"
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
			if (WINDOW_FRAME_DISLODGE)
				verbing = "to dislodge"
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_LODGE)
				verbing = "to seat back into place"
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_UNANCHOR)
				verbing = "to unfasten from its place"
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
			if (WINDOW_FRAME_ANCHOR)
				verbing = "to fasten into place"
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
		src.owner.visible_message("<span class='notice'>[src.owner] begins [verbing] [src.the_window_frame].</span>")

	onEnd()
		..()
		var/verbens = "does something to"
		switch (src.interaction)
			if (WINDOW_FRAME_UNWELD)
				verbens = "weakens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNWELDED
			if (WINDOW_FRAME_WELD)
				verbens = "strengthens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_WHOLE
			if (WINDOW_FRAME_UNSCREW)
				verbens = "unscrews"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNSCREWED
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
			if (WINDOW_FRAME_SCREW)
				verbens = "tightens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNWELDED
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
			if (WINDOW_FRAME_DISLODGE)
				verbens = "dislodges"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_DISLODGED
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_LODGE)
				verbens = "re-seats"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNSCREWED
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_UNANCHOR)
				verbens = "unanchors"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNANCHORED
				src.the_window_frame.anchored = UNANCHORED
				src.the_window_frame.UpdateIcon()
				if (src.the_window_frame.framed_window)
					src.the_window_frame.framed_window = UNANCHORED
					src.the_window_frame.framed_window.UpdateIcon()
				if (src.the_window_frame.framed_grille)
					src.the_window_frame.framed_grille = UNANCHORED
					src.the_window_frame.framed_grille.UpdateIcon()
				playsound(src.the_window_frame, 'sound/items/Deconstruct.ogg', 50, 1)
			if (WINDOW_FRAME_ANCHOR)
				verbens = "fastens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_DISLODGED
				src.the_window_frame.anchored = ANCHORED
				src.the_window_frame.UpdateIcon()
				if (src.the_window_frame.framed_window)
					src.the_window_frame.framed_window = ANCHORED
					src.the_window_frame.framed_window.UpdateIcon()
				if (src.the_window_frame.framed_grille)
					src.the_window_frame.framed_grille = ANCHORED
					src.the_window_frame.framed_grille.UpdateIcon()
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
		src.owner.visible_message("<span class='notice'>[src.owner] [verbens] [src.the_window_frame].</span>")

/// Same jump range and number of iterations as tables for the sake of consistency.
/datum/action/bar/icon/railing_jump/window_frame_jump
	id = "window_frame_jump"

#undef WINDOW_FRAME_UNANCHOR
#undef WINDOW_FRAME_ANCHOR
#undef WINDOW_FRAME_DISLODGE
#undef WINDOW_FRAME_LODGE
#undef WINDOW_FRAME_UNSCREW
#undef WINDOW_FRAME_SCREW
#undef WINDOW_FRAME_WELD
#undef WINDOW_FRAME_UNWELD

#undef WINDOW_FRAME_STATE_WHOLE
#undef WINDOW_FRAME_STATE_UNWELDED
#undef WINDOW_FRAME_STATE_UNSCREWED
#undef WINDOW_FRAME_STATE_DISLODGED
#undef WINDOW_FRAME_STATE_UNANCHORED

/**
 * #Window Frame Spawners
 * For use in map editors. Spawns a window frame with a window and grille on the tile it's placed on at runtime.
 */
/obj/window_frame_spawner
	name = "window frame spawner"
	icon = 'herb_modular/icons/obj/structures/wall_window_frames.dmi'
	icon_state = "wall-wingrille"
	// Same properties as normal wingrille spawners.
	density = 1
	anchored = ANCHORED
	invisibility = INVIS_ALWAYS

	/// What's the path of the /obj/structure/window_frame that is this associated with?
	var/frame_type = /obj/structure/window_frame
	/// What's the path of the /obj/window that this is assocaited with?
	var/window_type = /obj/window/auto/framed
	/// Do we want a grille on this window?
	var/has_grille = TRUE
	/// Path of the window grille.
	var/grille_type = /obj/grille/steel/framed

	New()
		..()
		if(current_state >= GAME_STATE_WORLD_INIT)
			SPAWN(0)
				initialize()

	initialize()
		..()
		var/turf/spawner_turf = get_turf(src) // So we don't keep calling it.
		// It'd better be on a floor.
		if (istype(spawner_turf, /turf/simulated/floor))
			// Check that a window frame doesn't already exist on the current tile. If not, spawn a frame.
			if (!locate(src.frame_type) in spawner_turf)
				var/obj/structure/window_frame/new_window_frame = new frame_type(spawner_turf)
				if (!locate(grille_type) in spawner_turf && src.has_grille)
					var/obj/grille/steel/framed/new_grille = new grille_type(spawner_turf)
					new_window_frame.framed_grille = new_grille
					new_window_frame.attached_objs.Add(new_grille)
					new_grille.glide_size = 0 // Required for smooth movement with the frame.
					new_grille.associated_frame = new_window_frame
				if (!locate(window_type) in spawner_turf)
					var/obj/window/auto/framed/new_window = new window_type(spawner_turf)
					new_window_frame.framed_window = new_window
					new_window_frame.attached_objs.Add(new_window)
					new_window.glide_size = 0 // Required for smooth movement with the frame.
					new_window.associated_frame = new_window_frame
		// Delete the spawner.
		qdel(src)

	reinforced
		name = "reinforced window frame wingrille spawner"
		icon = 'herb_modular/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-wingrille"
		frame_type = /obj/structure/window_frame/reinforced
		window_type = /obj/window/auto/framed/reinforced

		plasmaglass
			name = "reinforced plasmaglass window frame wingrille spawner"
			window_type = /obj/window/auto/framed/crystal

		shuttle
			name = "shuttle window frame wingrille spawner"
			icon = 'herb_modular/icons/obj/structures/shuttle_window_frames.dmi'
			icon_state = "shuttle-wingrille"
			frame_type = /obj/structure/window_frame/shuttle

/obj/window/auto/framed
	name = "framed window"
	desc = "A window designed to fit within a window frame."
	icon = 'herb_modular/icons/obj/framed_windows.dmi'
	icon_state = "framed-0"
	mod = "framed-"
	// Only connects to other framed windows.
	var/static/list/framed_window_connects_to = typecacheof(list(
		/obj/window/auto/framed
	))
	/// What frame is this associated with, if any?
	var/obj/structure/window_frame/associated_frame = null

	disposing()
		if (src.associated_frame)
			src.associated_frame.framed_window = null
		..()

	// Overriding the parent window update_icon() proc so it doesn't connect to what its parents wants
	update_icon()
		if (!src.anchored)
			icon_state = "[mod]0"
			update_damage_overlay()
			return

		connectdir = get_connected_directions_bitflag(framed_window_connects_to)

		src.icon_state = "[mod][connectdir]"
		src.update_damage_overlay()

	reinforced
		icon_state = "framed-r-0"
		mod = "framed-r-"
		default_reinforcement = "steel"
		health = 50
		health_max = 50

	crystal
		icon_state = ""
		default_material = "plasmaglass"
		health = 80
		health_max = 80
		deconstruct_time = 2 SECONDS

/obj/grille/steel/framed
	icon = 'herb_modular/icons/obj/framed_grilles.dmi'
	icon_state = "grille0-0"
	// Framed grilles should only ever connect to each other.
	connects_to_turf = null
	connects_to_obj = list(/obj/grille/steel/framed)
	/// What frame is this associated with, if any?
	var/obj/structure/window_frame/associated_frame = null

	disposing()
		if (src.associated_frame)
			src.associated_frame.framed_grille = null
		..()

// Window frame state defines.
#define WINDOW_FRAME_STATE_WHOLE 1
#define WINDOW_FRAME_STATE_UNWELDED 2
#define WINDOW_FRAME_STATE_UNSCREWED 3
#define WINDOW_FRAME_STATE_DISLODGED 4

// Tool action defines.
#define WINDOW_FRAME_READJUST 1
#define WINDOW_FRAME_DISASSEMBLE 2
#define WINDOW_FRAME_DISLODGE 3
#define WINDOW_FRAME_LODGE 4
#define WINDOW_FRAME_UNSCREW 5
#define WINDOW_FRAME_SCREW 6
#define WINDOW_FRAME_WELD 7
#define WINDOW_FRAME_UNWELD 8

/**
 * #Window Frames
 * An implemntation of window frames; pretty much just windows and grilles encased by what amounts to half of a wall that you can vault and throw
 * stuff over.
 */
/obj/structure/window_frame
	name = "window frame"
	desc = "A big hole in the wall that could fit a window and a grille."
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
	/// Bitflag for autoconnect dir.
	var/connect_dir = null
	/// The bitflags for the valid connections the frame can make. Outside of these, the frame won't connect.
	var/static/list/legal_dirs = list(0, NORTH, SOUTH, (NORTH + SOUTH), EAST, WEST, (EAST + WEST))
	/// Typecache of the atoms that this window frame connects to.
	var/static/list/connects_to = typecacheof(list(/obj/structure/window_frame))

	/// The health of the window frame.
	var/health = 100
	/// The maximum health of the window frame.
	var/max_health = 100
	/// The current state of the window frame itself, using the defines in window_frame.dm
	var/window_frame_state = WINDOW_FRAME_STATE_WHOLE

	/// The window that's currently tied to this frame.
	var/obj/window/auto/framed/framed_window = null

	/// TRUE if there is a grille, FALSE if not.
	var/obj/grille/framed/framed_grille = null

	New()
		..()
		if (!islist(src.attached_objs))
			src.attached_objs = list()
		if (src.health != src.max_health)
			src.health = src.max_health
		if (src.auto)
			src.update_neighbours()
			SPAWN(0)
				src.UpdateIcon()

	get_desc(dist, mob/user)
		if (src.framed_window || src.framed_grille)
			. += " There is[src.framed_window ? " a [src.framed_window.name]" : ""][src.framed_window && src.framed_grille ? " and" : ""][src.framed_grille ? " a [src.framed_grille.name]" : ""] in the frame."
		else
			. += " There is nothing in the frame, maybe you could vault over this."
		switch (src.window_frame_state)
			if (WINDOW_FRAME_STATE_WHOLE)
				. += " You could start disassembling this by unwelding the supports, or re-adjust its appearance with a screwdriver."
			if (WINDOW_FRAME_STATE_UNWELDED)
				. += " You could unscrew [src] from the floor, or re-weld the supports back together."
			if (WINDOW_FRAME_STATE_UNSCREWED)
				. += " You could pry [src] from the floor, or screw it back in."
			if (WINDOW_FRAME_STATE_DISLODGED)
				. += " Final disassembly will require you to wrench [src] from its place, or you can wedge it back into the floor to start the repairs."

	disposing()
		if (src.framed_window)
			qdel(src.framed_window)
		if (src.framed_grille)
			qdel(src.framed_grille)
		..()

	attackby(obj/item/W, mob/user)
		// Construction/destruction of the window frame.
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
				if (WINDOW_FRAME_STATE_WHOLE)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_READJUST), user)
				if (WINDOW_FRAME_STATE_UNWELDED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_UNSCREW), user)
				if (WINDOW_FRAME_STATE_UNSCREWED)
					actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_SCREW), user)
				if (WINDOW_FRAME_STATE_DISLODGED)
					boutput(user, "<span class='alert'>It doesn't seem like you can remove [src] without disassembling it.</span>")
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
		else if (iswrenchingtool(W))
			if (src.window_frame_state == WINDOW_FRAME_STATE_DISLODGED)
				actions.start(new /datum/action/bar/icon/window_frame_tool_interact(src, W, WINDOW_FRAME_DISASSEMBLE), user)
			else
				. = ..()
		// Build windows/grilles.
		else if (istype(W, /obj/item/sheet/))
			if (src.framed_window)
				. = ..()
			var/obj/item/sheet/material_sheets = W
			if (material_sheets.material && material_sheets.material.material_flags & MATERIAL_CRYSTAL && material_sheets.amount_check(2))
				if (material_sheets.reinforcement)
					src.framed_window = new /obj/window/auto/framed/reinforced(src.loc)
				else
					src.framed_window = new /obj/window/auto/framed(src.loc)
				if (src.framed_window)
					src.attached_objs.Add(src.framed_window)
					src.framed_window.setMaterial(material_sheets.material)
					src.framed_window.glide_size = 0
					src.framed_window.associated_frame = src
					src.framed_window.set_dir(src.dir)
					material_sheets.change_stack_amount(-2)
					user.visible_message("<span class='notice'>[user] builds a [src.framed_window.name] in [src].</span>")
					logTheThing(LOG_STATION, user, {"builds a [src.framed_window.name] (<b>Material:</b> [material_sheets.material && material_sheets.material.mat_id ? "[material_sheets.material.mat_id]" : "*UNKNOWN*"]) at ([log_loc(src)])"})
					src.framed_window.add_fingerprint(user)
				else
					boutput(user, "<span class='alert'>Unable to build a window here.</span>")
		else if (istype(W, /obj/item/rods))
			if (src.framed_grille)
				. = ..()
			var/obj/item/rods/material_rods = W
			if (material_rods.amount >= 2)
				src.framed_grille = new /obj/grille/framed(src.loc)
				src.framed_grille.setMaterial(material_rods.material)
				src.framed_grille.glide_size = 0
				src.framed_grille.associated_frame = src
				src.framed_grille.set_dir(src.dir)
				material_rods.change_stack_amount(-2)
				user.visible_message("<span class='notice'>[user] builds a [src.framed_grille.name] in [src].</span>")
				logTheThing(LOG_STATION, user, "builds a grille (<b>Material:</b> [material_rods.material?.mat_id || "*UNKNOWN*"]) at [log_loc(src)].")
				src.framed_grille.add_fingerprint(user)
			else
				boutput(user, "<span class='alert'>Unable to build a grille here.</span>")
		else
			..()

	/**
	 * All /mob/living/carbon/human types can now jump over the window frame if there isn't a grille or window.
	 * Hulks can jump through no matter what and it'll bust the grille and window open.
	*/
	Bumped(mob/bumpee)
		..()
		if (!src.framed_window && !src.framed_grille)
			if (ishuman(bumpee) && isalive(bumpee))
				var/mob/living/carbon/human/human_bumpee = bumpee
				actions.start(new /datum/action/bar/icon/railing_jump/table_jump/window_frame_jump(human_bumpee, src), human_bumpee)

	Cross(atom/movable/mover)
		// mover can pass over the window frame tile if it has the TABLEPASS flag.
		if (mover?.flags & TABLEPASS)
			return TRUE
		return FALSE

	update_icon()
		if (!src.anchored)
			icon_state = "[src.mod]0"
			return
		/* No, NO corners allowed!
		 * I really wish there was a cardinal-only implementation of get_connected_directions_bitflag() but whatever
		 */
		var/connect_bitflag_buffer = get_connected_directions_bitflag(src.connects_to)
		for (var/bitflag in src.legal_dirs)
			if (connect_bitflag_buffer == bitflag)
				src.connect_dir = connect_bitflag_buffer
				break
		icon_state = "[src.mod][src.connect_dir]"
		// Update the window and grille, as a treat.
		if (src.framed_window)
			src.framed_window.UpdateIcon()
		if (src.framed_grille)
			src.framed_grille.UpdateIcon()

	meteorhit(obj/M)
		if (src.framed_window)
			src.framed_window.meteorhit(M)
		if (src.framed_grille)
			src.framed_grille.meteorhit(M)
		if (istype(M, /obj/newmeteor/massive))
			src.disintegrate()
		else
			src.damage_blunt(5)

	/// Spawns some scrap metal and deletes the src when called.
	proc/disintegrate()
		var/obj/item/raw_material/scrap_metal/debris = new /obj/item/raw_material/scrap_metal
		debris.set_loc(src.loc)
		if (src.material)
			debris.setMaterial(src.material)
		else
			debris.setMaterial(getMaterial("steel"), copy = FALSE)
		src.visible_message("<span class='alert'>[src] disintegrates into scrap!</span>")
		qdel(src)

	proc/update_neighbours()
		for (var/obj/structure/window_frame/neighbouring_frame in orange(1,src))
			neighbouring_frame.UpdateIcon()
		for (var/obj/window/auto/framed/neighboring_window in orange(1,src))
			neighboring_window.UpdateIcon()
		for (var/obj/grille/framed/G in orange(1,src))
			G.UpdateIcon()

	reinforced
		icon = 'herb_modular/icons/obj/structures/rwall_window_frames.dmi'
		icon_state = "rwall-0"
		mod = "rwall-"
		max_health = 300
		explosion_resistance = 5

	shuttle
		icon = 'herb_modular/icons/obj/structures/shuttle_window_frames.dmi'
		icon_state = "shuttle-0"
		mod = "shuttle-"

/// Ripped from /datum/action/bar/icon/table_tool_interact
/datum/action/bar/icon/window_frame_tool_interact
	id = "window_frame_tool_interact"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	duration = 2 SECONDS
	icon = 'icons/ui/actions.dmi'
	icon_state = "working"
	var/obj/structure/window_frame/the_window_frame
	var/obj/item/the_tool
	var/interaction = WINDOW_FRAME_DISASSEMBLE

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
			if (WINDOW_FRAME_READJUST)
				verbing = "re-adjusting"
				playsound(src.the_window_frame, 'sound/items/Screwdriver.ogg', 50, 1)
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
			if (WINDOW_FRAME_LODGE)
				verbing = "to seat back into place"
			if (WINDOW_FRAME_DISASSEMBLE)
				verbing = "disassembling"
				playsound(src.the_window_frame, 'sound/items/Ratchet.ogg', 50, 1)
		src.owner.visible_message("<span class='notice'>[src.owner] begins [verbing] [src.the_window_frame].</span>")

	onEnd()
		..()
		var/verbens = "does something to"
		switch (src.interaction)
			if (WINDOW_FRAME_READJUST)
				verbens = "re-adjusts"
				src.the_window_frame.set_dir(turn(src.the_window_frame.dir, 90)) // Figured it should rotate the direction. Only matters for bitflag 0.
				src.the_window_frame.UpdateIcon()
			if (WINDOW_FRAME_UNWELD)
				verbens = "weakens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNWELDED
			if (WINDOW_FRAME_WELD)
				verbens = "strengthens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_WHOLE
			if (WINDOW_FRAME_UNSCREW)
				verbens = "unscrews"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNSCREWED
			if (WINDOW_FRAME_SCREW)
				verbens = "tightens"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNWELDED
			if (WINDOW_FRAME_DISLODGE)
				verbens = "dislodges"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_DISLODGED
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_LODGE)
				verbens = "re-seats"
				src.the_window_frame.window_frame_state = WINDOW_FRAME_STATE_UNSCREWED
				playsound(src.the_window_frame, 'sound/items/Crowbar.ogg', 50, 1)
			if (WINDOW_FRAME_DISASSEMBLE)
				verbens = "disassembles"
				playsound(src.the_window_frame, 'sound/items/Deconstruct.ogg', 50, 1)
		src.owner.visible_message("<span class='notice'>[src.owner] [verbens] [src.the_window_frame].</span>")
		if (src.interaction == WINDOW_FRAME_DISASSEMBLE)
			if (src.the_window_frame.framed_window)
				src.the_window_frame.framed_window.disassemble()
			if (src.the_window_frame.framed_grille)
				src.the_window_frame.framed_grille.drop_rods(src.the_window_frame.framed_grille.amount_of_rods_when_destroyed)
				qdel(src.the_window_frame.framed_grille)
			src.the_window_frame.disintegrate()

/// Same jump range and number of iterations as tables for the sake of consistency.
/datum/action/bar/icon/railing_jump/table_jump/window_frame_jump
	id = "window_frame_jump"

	getLandingLoc()
		var/iteration = 0
		var/dir = get_dir(src.ownerMob, src.the_railing)
		var/turf/target = get_step(src.the_railing, dir)
		var/obj/structure/window_frame/maybe_window_frame = locate(/obj/structure/window_frame) in target
		while(maybe_window_frame && iteration < src.iteration_limit)
			iteration++
			target = get_step(target, dir)
			maybe_window_frame = locate(/obj/structure/window_frame) in target
			duration += 1 SECOND
		return target

#undef WINDOW_FRAME_READJUST
#undef WINDOW_FRAME_DISASSEMBLE
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
	/// What's the path of the /obj/window that this is associated with?
	var/window_type = /obj/window/auto/framed
	/// Do we want a grille on this window?
	var/has_grille = TRUE
	/// Path of the window grille.
	var/grille_type = /obj/grille/framed

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
				new_window_frame.set_dir(src.dir)
				if (!locate(grille_type) in spawner_turf && src.has_grille)
					var/obj/grille/framed/new_grille = new grille_type(spawner_turf)
					new_window_frame.framed_grille = new_grille
					new_window_frame.attached_objs.Add(new_grille)
					new_grille.glide_size = 0 // Required for smooth movement with the frame.
					new_grille.associated_frame = new_window_frame
				if (!locate(window_type) in spawner_turf)
					var/obj/window/auto/framed/new_window = new window_type(spawner_turf)
					new_window_frame.framed_window = new_window
					new_window_frame.attached_objs.Add(new_window)
					new_window.glide_size = 0
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
	var/static/list/framed_connects_to = typecacheof(list(/obj/window/auto/framed))
	/// What frame is this associated with, if any?
	var/obj/structure/window_frame/associated_frame = null

	New()
		..()
		SPAWN(0)
			if (src.associated_frame)
				src.UpdateIcon()

	disposing()
		if (src.associated_frame)
			src.associated_frame.framed_window = null
		..()

	// Instead of DISASSEMBLEing the window when it's unscrewed from the floor, have it poop out the materials it's made of.
	assembly_handler(mob/user, obj/item/W)
		// I hate how window states are handled. So, so much.
		if (isscrewingtool(W) && src.state < 1)
			src.disassemble()
			return
		..()

	// Overriding the parent window update_icon() proc so it doesn't connect to what its parents wants
	update_icon()
		if (src.associated_frame)
			src.set_dir(src.associated_frame.dir)
			src.icon_state = "[src.mod][src.associated_frame.connect_dir]"
		else
			icon_state = "[src.mod]0"
		src.update_damage_overlay()
		// src.connectdir = get_connected_directions_bitflag(framed_connects_to)

	proc/disassemble()
		var/obj/item/sheet/window_sheet = new /obj/item/sheet(get_turf(src))
		if (src.material)
			window_sheet.setMaterial(src.material)
		else
			var/datum/material/M = getMaterial("glass")
			window_sheet.setMaterial(M)
		if (!(src.dir in cardinal)) // full window takes two sheets to make
			window_sheet.amount += 1
		if (src.reinforcement)
			window_sheet.set_reinforcement(src.reinforcement)
		qdel(src)

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

/obj/grille/framed
	icon = 'herb_modular/icons/obj/framed_grilles.dmi'
	icon_state = "grille0-0"
	// Grille autoconnection implementation sucks. I'll do my own.
	connects_to_turf = null
	connects_to_obj = null

	/// What material is this made of?
	var/grille_material = "steel"

	/// Icon state prefix for the purposes of auto-connecting frames.
	var/mod = "grille"
	/// What frame is this associated with, if any?
	var/obj/structure/window_frame/associated_frame = null
	/// Typecache of the atoms that this grille connects to.
	var/static/list/connects_to = typecacheof(list(/obj/grille/framed))

	New()
		..()
		var/datum/material/M = getMaterial(src.grille_material)
		src.setMaterial(M, copy=FALSE)
		SPAWN(0)
			if (src.associated_frame)
				src.UpdateIcon()

	disposing()
		if (src.associated_frame)
			src.associated_frame.framed_grille = null
		..()

	attackby(obj/item/W, mob/user)
		if (src.can_be_unscrewed && (isscrewingtool(W) && (istype(src.loc, /turf/simulated))))
			boutput(user, "<span class='alert'>[src] is stuck in quite tight. You'll need to snip the bars off.</span>")
			return
		if (istype(W, /obj/item/sheet))
			if (src.associated_frame)
				if (src.associated_frame.framed_window)
					return
				var/obj/item/sheet/material_sheets = W
				if (material_sheets.material && material_sheets.material.material_flags & MATERIAL_CRYSTAL && material_sheets.amount_check(2))
					if (material_sheets.reinforcement)
						src.associated_frame.framed_window = new /obj/window/auto/framed/reinforced(src.loc)
					else
						src.associated_frame.framed_window = new /obj/window/auto/framed(src.loc)
					if (src.associated_frame.framed_window)
						src.associated_frame.attached_objs.Add(src.associated_frame.framed_window)
						src.associated_frame.framed_window.setMaterial(material_sheets.material)
						src.associated_frame.framed_window.glide_size = 0
						src.associated_frame.framed_window.associated_frame = src
						src.associated_frame.framed_window.set_dir(src.dir)
						material_sheets.change_stack_amount(-2)
						user.visible_message("<span class='notice'>[user] builds a [src.associated_frame.framed_window.name] in [src.associated_frame].</span>")
						logTheThing(LOG_STATION, user, {"builds a [src.associated_frame.framed_window.name] (<b>Material:</b> [material_sheets.material && material_sheets.material.mat_id ? "[material_sheets.material.mat_id]" : "*UNKNOWN*"]) at ([log_loc(src.associated_frame)])"})
						src.associated_frame.framed_window.add_fingerprint(user)
						return
					else
						boutput(user, "<span class='alert'>Unable to build a window here.</span>")
						return
			else return
		..()

	update_icon(var/special_icon_state)
		if (src.ruined)
			return

		if (istext(special_icon_state))
			src.icon_state = "[src.mod]-[special_icon_state]"
			return

		if (src.associated_frame)
			src.set_dir(src.associated_frame.dir)
			src.icon_state = "[src.mod][src.associated_frame.connect_dir]"
		else
			src.icon_state = "[src.mod]0"

		var/diff = get_fraction_of_percentage_and_whole(src.health, src.health_max)
		switch(diff)
			if(-INFINITY to 25)
				src.icon_state += "-3"
			if(26 to 50)
				src.icon_state += "-2"
			if(51 to 75)
				src.icon_state += "-1"
			if(76 to INFINITY)
				src.icon_state += "-0"

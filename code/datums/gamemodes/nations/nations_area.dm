/// Nations-specific, prevents asteroid spawns.
/area/space/asteroid_safe_zone

/**
 * Because spacing shouldn't guarantee instant death, but thing still need to go to space on occasion.
 * This was easier to do than doing a map-specific proc override for `/turf/proc/edge_step()`.
 */
/area/area_that_kills_everything_that_enters_it_except_mobs_among_others
	skip_sims = 1
	sims_score = 0
	icon_state = "death"
	requires_power = 0
	teleport_blocked = AREA_TELEPORT_BLOCKED

/area/area_that_kills_everything_that_enters_it_except_mobs_among_others/Entered(atom/movable/A, atom/oldloc)
	if (!src.check_contents_eligibility(A))
		. = ..()
		return
	#ifdef CHECK_MORE_RUNTIMES
	if (current_state <= GAME_STATE_WORLD_NEW)
		CRASH("[identify_object(A)] got deleted by area_that_kills_everything_that_enters_it_except_mobs_among_others at [A.x],[A.y],[A.z] \
			([A.loc.loc] [A.loc.type]) during world initialization")
	#endif
	qdel(A)

/// Return FALSE if any one of `atom/movable/A`'s contents or any child of its contents is ineligible to be killed.
/area/area_that_kills_everything_that_enters_it_except_mobs_among_others/proc/check_contents_eligibility(atom/movable/A)
	. = TRUE
	if (!src.is_eligible_to_kill(A))
		. = FALSE
		return
	var/list/atom/thing_contents = A.contents
	if (!length(thing_contents))
		return
	for (var/atom/thing in thing_contents)
		if (src.check_contents_eligibility(thing))
			continue
		. = FALSE
		return

/// Return TRUE if `atom/A` is allowed to die.
/area/area_that_kills_everything_that_enters_it_except_mobs_among_others/proc/is_eligible_to_kill(atom/A)
	. = FALSE
	if (ismob(A))
		return
	if (!ismovable(A))
		return
	var/atom/movable/AM = A
	if (isobj(AM) && (!istype(AM, /obj/landmark/map)) && (!istype(AM, /obj/overlay/tile_effect)) && (AM.anchored != ANCHORED_ALWAYS))
		. = TRUE

#if defined(MAP_OVERRIDE_NATIONS)
/area/radiostation
	minimaps_to_render_on = MAP_ALL
#endif

TYPEINFO(/mob/dead)
	start_listen_modifiers = null
	start_listen_inputs = list(LISTEN_INPUT_DEADCHAT, LISTEN_INPUT_EARS_GHOST, LISTEN_INPUT_GLOBAL_HEARING_GHOST, LISTEN_INPUT_GLOBAL_HEARING_LOCAL_COUNTERPART_GHOST, LISTEN_INPUT_BLOBCHAT, LISTEN_INPUT_FLOCK_GLOBAL)
	start_listen_languages = list(LANGUAGE_ALL)
	start_speech_modifiers = null
	start_speech_outputs = list(SPEECH_OUTPUT_DEADCHAT_GHOST)

/mob/dead
	stat = STAT_DEAD
	event_handler_flags =  IMMUNE_OCEAN_PUSH | IMMUNE_SINGULARITY | IMMUNE_TRENCH_WARP
	pass_unstable = FALSE
	use_speech_bubble = TRUE
	default_speech_output_channel = SAY_CHANNEL_DEAD

	///Our corpse, if one exists
	var/mob/living/corpse

// dead
/mob/dead/New()
	..()
	src.flags |= UNCRUSHABLE
	APPLY_ATOM_PROPERTY(src, PROP_ATOM_FLOATING, src)

// No log entries for unaffected mobs (Convair880).
/mob/dead/ex_act(severity)
	return

// Make sure to keep this JPS-cache safe
/mob/dead/Cross(atom/movable/mover)
	return 1

/mob/dead/can_strip()
	return 0

/mob/dead/Login()
	. = ..()

	if(client?.holder?.ghost_interaction)
		setalive(src)

	if (isadminghost(src))
		get_image_group(CLIENT_IMAGE_GROUP_ALL_ANTAGONISTS).add_client(src.client)

/mob/dead/Logout()
	. = ..()
	setdead(src)

	if (src.last_client?.holder && (rank_to_level(src.last_client.holder.rank) >= LEVEL_MOD) && (istype(src, /mob/dead/observer) || istype(src, /mob/dead/target_observer)))
		get_image_group(CLIENT_IMAGE_GROUP_ALL_ANTAGONISTS).remove_client(src.last_client)

/mob/dead/click(atom/target, params, location, control)
	if(src.client?.holder?.ghost_interaction)
		if(isitem(target))
			var/obj/item/itemtarget = target
			itemtarget.AttackSelf(src)
		else
			target.Attackhand(src, params, location, control, params)
	else if (targeting_ability)
		..()
	else
		if (GET_DIST(src, target) > 0)
			src.set_dir(get_dir(src, target))
		src.examine_verb(target)

/mob/dead/process_move(keys)
	if(keys && src.move_dir && !src.override_movement_controller && !istype(src.loc, /turf)) //Pop observers and Follow-Thingers out!!
		var/mob/dead/O = src
		O.set_loc(get_turf(src))
	. = ..()

/mob/dead/projCanHit(datum/projectile/P)
	// INVIS_ALWAYS ghosts are logged out/REALLY hidden.
	return (P.hits_ghosts && (src.invisibility != INVIS_ALWAYS))

/mob/dead/visible_message(var/message, var/self_message, var/blind_message, var/group = "")
	for (var/mob/M in viewers(src))
		if (!M.client)
			continue
		var/msg = message
		if (self_message && M == src)
			M.show_message(self_message, 1, self_message, 2, group)
		else
			M.show_message(msg, 1, blind_message, 2, group)

#ifdef HALLOWEEN
/mob/dead/proc/animate_surroundings(var/type="fart", var/range = 2)
	var/count = 0
	for (var/obj/item/I in range(src, 2))
		if (count > 5)
			return
		var/success = 0
		switch (type)
			if ("fart")
				animate_levitate(I, 1, 8)
				success = 1
			if ("dance")
				eat_twitch(I)
				success = 1
			if ("flip")
				animate_spin(src, prob(50) ? "R" : "L", 1, 0)
				success = 1
		count ++
		if (success)
			sleep(rand(1,4))
#endif

// nothing in the game currently forces dead mobs to vomit. this will probably change or end up exposed via someone fucking up (likely me) in future. - cirr
/mob/dead/vomit(var/nutrition=0, var/specialType=null, var/flavorMessage="[src] vomits!", var/selfMessage = null)
	. = ..(0, /obj/item/reagent_containers/food/snacks/ectoplasm)
	if(.)
		playsound(src.loc, 'sound/effects/ghost2.ogg', 50, 1)
		src.visible_message(SPAN_ALERT("Ectoplasm splats onto the ground from nowhere!"),
			SPAN_ALERT("Even dead, you're nauseated enough to vomit![pick("", "Oh god!")]"),
			SPAN_ALERT("You hear something strangely insubstantial land on the floor with a wet splat!"))

proc/can_ghost_be_here(mob/dead/ghost, var/turf/T)
	if(isnull(T))
		return FALSE
	if(isghostrestrictedz(T.z) && !restricted_z_allowed(ghost, T) && !(ghost.client && ghost.client.holder && !ghost.client.holder.tempmin))
		return FALSE
	return TRUE

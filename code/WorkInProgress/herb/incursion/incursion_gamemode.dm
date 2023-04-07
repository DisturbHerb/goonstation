/datum/game_mode/incursion
	name = "Syndicate Incursion"
	config_tag = "incursion"
	shuttle_available = SHUTTLE_CALL_FULLY_DISABLED
	var/list/datum/mind/syndicates = list()
	var/nt_employee_count = 0 // Updates on every process tick dependong on length(TR_CAT_NTEMPLOYEE)
	var/employee_count_indicator = FALSE // Is the body count indicator showing up?
	var/employee_count_threshold = 30 // How many people have to remain before the HUD element shows up?
	var/can_finish = FALSE // The game isn't over yet!
	var/finished = 0
	var/agent_radiofreq = 0 //:h for syndies, randomized per round
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)
	var/datum/hud/incursion_employee_count/employee_count_hud = null // the body count maptext woo

	do_antag_random_spawns = 0
	antag_token_support = TRUE
	escape_possible = 0

/datum/game_mode/incursion/announce()
	boutput(world, "<B>The current game mode is - Syndicate Incursion!</B>")
	boutput(world, "<B>[syndicate_name()] operatives have been tasked with neutralising all personnel aboard [station_name(1)]!</B>")

/datum/game_mode/incursion/pre_setup()
	var/list/possible_syndicates = list()

	if (!landmarks[LANDMARK_SYNDICATE])
		boutput(world, "<span class='alert'><b>ERROR: couldn't find Syndicate spawn landmark, aborting nuke round pre-setup.</b></span>")
		return 0

	var/num_players = 0
	for(var/client/C)
		var/mob/new_player/player = C.mob
		if (!istype(player)) continue

		if (player.ready)
			num_players++
	var/num_synds = num_players
	possible_syndicates = get_possible_enemies(ROLE_INCURSION, num_players)

	if (!islist(possible_syndicates) || possible_syndicates.len < 1)
		boutput(world, "<span class='alert'><b>ERROR: couldn't assign any players as Syndicate operatives, aborting incursion round pre-setup.</b></span>")
		return 0

	// now that we've done everything that could cause the round to fail to start (in this proc, at least), we can deal with antag tokens
	token_players = antag_token_list()
	for (var/datum/mind/tplayer in token_players)
		if (!token_players.len)
			break
		syndicates += tplayer
		token_players.Remove(tplayer)
		num_synds--
		num_synds = max(num_synds, 0)
		logTheThing(LOG_ADMIN, tplayer.current, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")

	var/list/chosen_syndicates = antagWeighter.choose(pool = possible_syndicates, role = ROLE_INCURSION, amount = num_synds, recordChosen = 1)
	syndicates |= chosen_syndicates
	for (var/datum/mind/syndicate in syndicates)
		syndicate.assigned_role = "MODE" //So they aren't chosen for other jobs.
		possible_syndicates.Remove(syndicate)

	agent_radiofreq = random_radio_frequency()

	return 1

/datum/game_mode/incursion/proc/pick_leader()
	RETURN_TYPE(/datum/mind)
	var/list/datum/mind/possible_leaders = list()
	for(var/datum/mind/mind in syndicates)
		if(mind.current.client.preferences.be_syndicate_commander)
			possible_leaders += mind
	if(length(possible_leaders))
		return pick(possible_leaders)
	return pick(syndicates)

/datum/game_mode/incursion/post_setup()
	var/datum/mind/leader_mind

	// Check that a leader doesn't already exist since you like to spawn one pre-round.
	for(var/client/C)
		var/mob/client_mob = C.mob
		if (!istype(client_mob)) continue
		if(client_mob.mind.get_antagonist(ROLE_INCURSION_COMMANDER))
			leader_mind = client_mob.mind
			syndicates += leader_mind
			break

	if(!leader_mind)
		leader_mind = src.pick_leader()

	for(var/datum/mind/synd_mind in syndicates)
		var/obj_count = 1
		boutput(synd_mind.current, "<span class='notice'>You are a [syndicate_name()] agent!</span>")
		for(var/datum/objective/objective in synd_mind.objectives)
			boutput(synd_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			obj_count++

		if(synd_mind == leader_mind)
			synd_mind.add_antagonist(ROLE_INCURSION_COMMANDER)
		else
			synd_mind.add_antagonist(ROLE_INCURSION)

		synd_mind.current.antagonist_overlay_refresh(1, 0)

	for(var/turf/T in landmarks[LANDMARK_SYNDICATE_GEAR_CLOSET])
		new /obj/storage/closet/syndicate/personal(T)
	for(var/turf/T in landmarks[LANDMARK_SYNDICATE_BREACHING_CHARGES])
		for(var/i = 1 to 5)
			new /obj/item/breaching_charge/thermite(T)

	for(var/datum/job/J in job_controls.staple_jobs + job_controls.special_jobs)
		J.limit = 0

	for(var/obj/machinery/power/apc/current_apc in by_type[/obj/machinery/power/apc])
		if(istype(get_area(current_apc), /area/station))
			// current_apc.equipment = 0
			current_apc.lighting = 0
			current_apc.UpdateIcon()
			current_apc.update()

	for(var/obj/machinery/door/airlock/the_airlock in by_type[/obj/machinery/door/airlock])
		if((istype(the_airlock, /obj/machinery/door/airlock/external) || istype(the_airlock, /obj/machinery/door/airlock/pyro/external)) && istype(get_area(the_airlock), /area/station))
			the_airlock.locked = 1
			the_airlock.UpdateIcon()

	SPAWN(rand(waittime_l, waittime_h))
		send_intercept()

	return

/datum/game_mode/incursion/check_finished()
	if (!src.can_finish)
		return 0

	if (src.finished)
		return 1

	if (no_automatic_ending)
		return 0

	if (src.all_operatives_dead())
		finished = 1
		return 1

	if (src.nt_eliminated())
		finished = -1
		return 1

	return 0

/datum/game_mode/incursion/proc/nt_eliminated()
	var/list/nt_employees = by_cat[TR_CAT_NTEMPLOYEES]
	if (length(nt_employees))
		return FALSE
	else return TRUE

/datum/game_mode/incursion/proc/all_operatives_dead()
	var/opcount = 0
	var/opdeathcount = 0
	for(var/datum/mind/M in syndicates)
		opcount++
		if(!M.current || isdead(M.current) || inafterlife(M.current) || isVRghost(M.current) || issilicon(M.current) || isghostcritter(M.current))
			opdeathcount++ // If they're dead
			continue

		var/turf/T = get_turf(M.current)
		if (!T)
			continue
		if (istype(T.loc, /area/station/security/brig))
			if(M.current.hasStatus("handcuffed"))
				opdeathcount++
				// If they're in a brig cell and cuffed

	if (opcount == opdeathcount) return 1
	else return 0

/datum/game_mode/incursion/victory_msg()
	switch(finished)
		if(-1) // Syndicate victory; all NT employees eliminated. Does not include any emergency response forces.
			return "<FONT size = 3><B>Syndicate Victory</B></FONT><br>\
					The crew of [station_name(1)] have all been eliminated by the Syndicate incursion! For the Syndicate!"
		if(0) // Uhhhhhh
			return "<FONT size = 3><B>Stalemate</B></FONT><br>\
					Everybody loses!"
		if(1) // Crew victory; all Syndicate operatives eliminated.
			return "<FONT size = 3><B>Crew Victory</B></FONT><br>\
					The crew of [station_name(1)] survived the assault on their [station_or_ship()]! NanoTrasen prevails!"

/datum/game_mode/incursion/declare_completion()
	boutput(world, src.victory_msg())

	for(var/datum/mind/M in syndicates)
		var/syndtext = ""
		if(M.current) syndtext += "<B>[M.key] played [M.current.real_name].</B> "
		else syndtext += "<B>[M.key] played an operative.</B> "
		if (!M.current) syndtext += "(Destroyed)"
		else if (isdead(M.current)) syndtext += "(Killed)"
		else if (M.current.z != 1) syndtext += "(Missing)"
		else syndtext += "(Survived)"
		boutput(world, syndtext)

		for (var/datum/objective/objective in M.objectives)
#ifdef CREW_OBJECTIVES
			if (istype(objective, /datum/objective/crew)) continue
#endif
			if (objective.check_completion())
				if (!isnull(objective.medal_name) && !isnull(M.current))
					M.current.unlock_medal(objective.medal_name, objective.medal_announce)

	..() //Listing custom antagonists.

/datum/game_mode/incursion/send_intercept()
	..(ticker.minds)
/datum/game_mode/incursion/proc/random_radio_frequency()
	. = 0
	var/list/blacklisted = list(0, 1451, 1457) // The old blacklist was rather incomplete and thus ineffective (Convair880).
	blacklisted.Add(R_FREQ_BLACKLIST)

	do
		. = rand(1352, 1439)

	while (. in blacklisted)
/datum/game_mode/incursion/process()
	set background = 1

	if(!src.employee_count_hud && src.can_finish && src.nt_employee_count < src.employee_count_threshold)
		src.employee_count_hud = new()
		for (var/client/C in clients)
			src.employee_count_hud.add_client(C)

	if(src.employee_count_hud)
		src.nt_employee_count = length(by_cat[TR_CAT_NTEMPLOYEES])
		if(src.nt_employee_count < src.employee_count_threshold)
			src.employee_count_hud.update_employee_count(src.nt_employee_count)
		else
			src.employee_count_hud = null

	..()
	return

/datum/hud/incursion_employee_count
	click_check = 0
	var/atom/movable/screen/employee_count_hud
	New()

		src.employee_count_hud = create_screen("nt_employee_count", "NT Employee Count", null, "", "NORTH,CENTER", HUD_LAYER_3)
		employee_count_hud.maptext = ""
		employee_count_hud.maptext_width = 480
		employee_count_hud.maptext_x = -(480 / 2) + 16
		employee_count_hud.maptext_y = -320
		employee_count_hud.maptext_height = 320
		employee_count_hud.plane = 100
		..()

	proc/update_employee_count(var/employee_count)
		employee_count_hud.maptext = "<span class='c ol vga vt' style='background: #00000080;'>NT Employees Remaining<br><span style='font-size: 24px;'>[employee_count]</span></span>"


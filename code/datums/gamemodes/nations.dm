/// Initially populated with the default nation types.
var/list/roundstart_nation_types = list(
	/datum/nation/engineering,
	/datum/nation/medical,
	/datum/nation/research,
	/datum/nation/service,
	/datum/nation/supply,
)

/datum/game_mode/nations
	name = "Nations"
	config_tag = "nations"
	regular = FALSE
	do_antag_random_spawns = 0
	latejoin_antag_compatible = 0

	var/list/datum/nation/nations = list()

/datum/game_mode/nations/announce()
	boutput(world, "<B>The current game mode is - Nations!</B>")
	boutput(world, "<B>Guide your nation's destiny among the stars!</B>")

/datum/game_mode/nations/pre_setup()
	. = TRUE
	if (global.map_setting != "NATIONS")
		logTheThing(LOG_DEBUG, src, "Nations gamemode is being started without the Nations map! Careful!")
		message_admins("Nations gamemode is being started without the Nations map! Careful!")

/datum/game_mode/nations/post_setup()
	var/list/datum/mind/client_minds = list()
	for (var/client/client)
		if (!isliving(client.mob))
			continue
		client_minds += client?.mob.mind

	for (var/nation_type in roundstart_nation_types)
		src.nations += global.get_singleton(nation_type)

	client_minds = src.populate_nations(client_minds)

	var/list/nation_populations = list()
	for (var/datum/nation/nation in src.nations)
		if (!length(nation.citizens))
			continue
		if (!nation.leader)
			nation.add_leader(pick(nation.citizens))
		nation_populations += "[nation.name] ([length(nation.citizens)])"
	if (length(nation_populations))
		logTheThing(LOG_GAMEMODE, src, "set up the following nations: [english_list(nation_populations)]")
		message_admins("Nations: Set up the following nations: [english_list(nation_populations)]")

	if (length(client_minds))
		var/list/remaining_client_minds = list()
		for (var/datum/mind/candidate in client_minds)
			remaining_client_minds += "[key_name(candidate)]"
		logTheThing(LOG_GAMEMODE, src, "has rendered [length(client_minds)] players ([english_list(remaining_client_minds)]) stateless!")
		message_admins("Nations: rendered [length(client_minds)] players stateless!")

/datum/game_mode/nations/send_intercept(badguy_list)
	return

/datum/game_mode/nations/proc/populate_nations(list/datum/mind/client_minds)
	logTheThing(LOG_GAMEMODE, src, "attempting to populate each nation.")
	message_admins("Nations: Attempting to populate each nation.")
	if (!length(src.nations))
		logTheThing(LOG_GAMEMODE, src, "was unable to populate the nations as they don't seem to exist! Aborting!")
		message_admins("Nations: Unable to populate the nations as they don't seem to exist! Aborting!")
		return
	if (!length(client_minds))
		logTheThing(LOG_GAMEMODE, src, "was unable to populate the nations as no valid candidates were found!")
		message_admins("Nations: Unable to populate the nations as no valid candidates were found!")
		return
	shuffle_list(client_minds)
	for (var/datum/mind/candidate_mind in client_minds)
		if (!src.assign_to_a_nation(candidate_mind))
			continue
		if (!iscarbon(candidate_mind.current))
			continue
		client_minds -= candidate_mind
	return client_minds

/datum/game_mode/nations/proc/assign_to_a_nation(datum/mind/candidate_mind, candidate_job)
	. = TRUE
	if (!ismind(candidate_mind))
		return FALSE
	var/datum/job/mind_job
	if (istype(candidate_job, /datum/job))
		mind_job = candidate_job
	else
		mind_job = find_job_in_controller_by_string(candidate_mind.assigned_role)
	for (var/datum/nation/nation in src.nations)
		if ((mind_job.type in nation.leader_jobs) && !nation.leader)
			nation.add_leader(candidate_mind.current.mind)
			return
		if ((mind_job.type) in nation.citizen_jobs)
			nation.add_citizen(candidate_mind.current.mind)
			return
		if (mind_job.job_category in nation.citizen_job_categories)
			nation.add_citizen(candidate_mind.current.mind)
			return
	. = FALSE

/datum/game_mode/nations/proc/handle_latejoin(datum/mind/new_mind, datum/job/new_mind_job)
	var/turf/spawn_turf = pick_landmark(LANDMARK_LATEJOIN, locate(1, 1, 1))
	var/obj/cryotron/latejoin_cryotron = locate(/obj/cryotron) in spawn_turf
	if (istype(latejoin_cryotron, /obj/cryotron))
		latejoin_cryotron.add_person_to_queue(new_mind.current, new_mind_job)
	else
		new_mind.current?.set_loc(spawn_turf)
	if (src.assign_to_a_nation(new_mind, new_mind_job))
		return
	logTheThing(LOG_GAMEMODE, new_mind.current, "attempted to latejoin and was not assigned to the UN or any nation!")
	message_admins("Nations: [key_name(new_mind)] attempted to latejoin and was not assigned to the UN or any nation!")

/datum/game_mode/nations/proc/get_nation(mob/living/carbon/target)
	RETURN_TYPE(/datum/nation)

	. = null
	if (!iscarbon(target))
		return
	for (var/datum/nation/nation in src.nations)
		if (!(target.mind in nation.citizens))
			continue
		return nation

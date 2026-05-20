/datum/nation
	var/name = ""
	/// For displaying the short-form on Passports.
	var/short_name = ""

	/// The passport type that this nation should use.
	var/passport_type = /obj/item/passport
	/// For custom-generated passports as well as the UI.
	var/passport_color = "#1a378d"

	var/citizen_role = null

	/// List of jobs which provide the highest priority candidates for the nation's leader at roundstart.
	var/list/leader_jobs = list()
	/// List of jobs which are assigned regular citizenship to this nation at roundstart. Checked FIRST. As /datum/job types.
	var/list/citizen_jobs = list()
	/// List of jobs categories which are assigned regular citizenship to this nation at roundstart. Checked SECOND. See `_std/defines/job.dm`.
	var/list/citizen_job_categories = list()

	var/datum/mind/leader = null
	var/list/datum/mind/citizens = list()

/datum/nation/proc/add_leader(datum/mind/new_leader)
	if (src.leader == new_leader)
		return
	if (src.leader)
		var/datum/mind/old_leader = src.leader
		logTheThing(LOG_GAMEMODE, src, "removed [key_name(old_leader)] as leader of [src.name]!")
	src.leader = new_leader
	src.add_citizen(new_leader)
	logTheThing(LOG_GAMEMODE, src, "installed [key_name(new_leader)] as leader of [src.name]!")

/datum/nation/proc/remove_leader(datum/mind/leader)
	src.remove_citizen(leader)
	if (src.leader != leader)
		return
	src.leader = null
	logTheThing(LOG_GAMEMODE, src, "removed [key_name(leader)] as leader of [src.name]!")

/datum/nation/proc/add_citizen(datum/mind/new_citizen)
	if (new_citizen in src.citizens)
		return
	src.citizens += new_citizen
	logTheThing(LOG_GAMEMODE, src, "assigned [key_name(new_citizen)] to the nation of [src.name]!")

/datum/nation/proc/remove_citizen(datum/mind/citizen)
	if (!(citizen in src.citizens))
		return
	src.citizens -= citizen
	logTheThing(LOG_GAMEMODE, src, "removed [key_name(citizen)] from the nation of [src.name]!")

/datum/nation/un
	name = "United Nations"
	passport_type = /obj/item/passport/un
	passport_color = "#24639a"
	citizen_role = ROLE_UN
	leader_jobs = list(/datum/job/command/captain)
	citizen_jobs = list(
		/datum/job/civilian/AI,
		/datum/job/civilian/cyborg,
		/datum/job/command/head_of_security,
	)
	citizen_job_categories = list(JOB_SECURITY)

/datum/nation/engineering
	name = "Engistan"
	passport_type = /obj/item/passport/engineering
	passport_color = "#d37610"
	citizen_role = ROLE_NATION_ENG
	leader_jobs = list(/datum/job/command/chief_engineer)
	citizen_job_categories = list(JOB_ENGINEERING)

/datum/nation/medical
	name = "Asclepius"
	passport_type = /obj/item/passport/medical
	passport_color = "#c9294e"
	citizen_role = ROLE_NATION_MED
	leader_jobs = list(/datum/job/command/medical_director)
	citizen_job_categories = list(JOB_MEDICAL)

/datum/nation/research
	name = "Erudite"
	passport_type = /obj/item/passport/research
	passport_color = "#5a1d8a"
	citizen_role = ROLE_NATION_SCI
	leader_jobs = list(/datum/job/command/research_director)
	citizen_job_categories = list(JOB_RESEARCH)

/datum/nation/service
	name = "\the Grey Horde"
	passport_type = /obj/item/passport/service
	passport_color = "#167935"
	citizen_role = ROLE_NATION_SER
	leader_jobs = list(/datum/job/command/head_of_personnel)
	citizen_job_categories = list(
		JOB_CIVILIAN,
		JOB_CLOWN,
	)

/datum/nation/supply
	name = "\the Independent Station-state of Cargonia"
	short_name = "Cargonia"
	passport_type = /obj/item/passport/supply
	passport_color = "#4a301b"
	citizen_role = ROLE_NATION_SUP
	citizen_jobs = list(
		/datum/job/engineering/miner,
		/datum/job/engineering/quartermaster,
	)

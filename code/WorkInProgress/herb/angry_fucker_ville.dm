#define CARGO_WEAPONS "Cargo"
#define CIVILIAN_WEAPONS "Civilian"
#define COMMAND_WEAPONS "Command"
#define ENGINEERING_WEAPONS "Engineering"
#define HONK_WEAPONS "Clown"
#define MEDICAL_WEAPONS "Medical"
#define RESEARCH_WEAPONS "Research"
#define SECURITY_WEAPONS "Security"

var/static/list/mutantrace_choices = list(
	/datum/mutantrace/cow,
	/datum/mutantrace/lizard,
	/datum/mutantrace/pug,
	/datum/mutantrace/roach,
	/datum/mutantrace/skeleton
)

var/static/list/shitty_cargo_weapons = list(
	/obj/item/mining_tool/drill,
	/obj/item/mining_tool/power_pick,
	/obj/item/mining_tool/powerhammer,
	/obj/item/mining_tool/power_shovel
)

var/static/list/shitty_civ_weapons = list(
	/obj/item/chair/folded,
	/obj/item/kitchen/rollingpin,
	/obj/item/kitchen/utensil/fork,
	/obj/item/kitchen/utensil/knife,
	/obj/item/kitchen/utensil/knife/pizza_cutter,
	/obj/item/mop,
	/obj/item/plate,
	/obj/item/plate/tray,
	/obj/item/razor_blade,
	/obj/item/scissors,
	/obj/item/storage/toolbox/emergency
)

var/static/list/shitty_eng_weapons = list(
	/obj/item/crowbar/yellow,
	/obj/item/deconstructor,
	/obj/item/screwdriver/yellow,
	/obj/item/wrench/yellow
)

var/static/list/shitty_med_weapons = list(
	/obj/item/scalpel,
	/obj/item/circular_saw,
	/obj/item/staple_gun,
	/obj/item/scissors/surgical_scissors
)

var/static/list/shitty_sci_weapons = list(
	/obj/item/gun/energy/phaser_gun,
	/obj/item/reagent_containers/glass/bottle/pacid
)

var/static/list/shitty_sec_weapons = list(
	/obj/item/gun/kinetic/detectiverevolver,
	/obj/item/gun/energy/taser_gun,
	/obj/item/gun/energy/tasershotgun,
	/obj/item/gun/energy/tasersmg
)

var/static/list/jobs_and_departments = list(
	"Miner" = CARGO_WEAPONS,
	"Quartermaster" = CARGO_WEAPONS,
	"Captain" = COMMAND_WEAPONS,
	"Chief Engineer" = ENGINEERING_WEAPONS,
	"Engineer" = ENGINEERING_WEAPONS,
	"Clown" = HONK_WEAPONS,
	"Geneticist" = MEDICAL_WEAPONS,
	"Medical Director" = MEDICAL_WEAPONS,
	"Medical Doctor" = MEDICAL_WEAPONS,
	"Pathologist" = MEDICAL_WEAPONS,
	"Roboticist" = MEDICAL_WEAPONS,
	"Scientist" = RESEARCH_WEAPONS,
	"Research Director" = RESEARCH_WEAPONS,
	"Detective" = SECURITY_WEAPONS,
	"Head of Security" = SECURITY_WEAPONS,
	"Security Assistant" = SECURITY_WEAPONS,
	"Security Officer" = SECURITY_WEAPONS,
	"Botanist" = CIVILIAN_WEAPONS,
	"Bartender" = CIVILIAN_WEAPONS,
	"Chaplain" = CIVILIAN_WEAPONS,
	"Chef" = CIVILIAN_WEAPONS,
	"Head of Personnel" = CIVILIAN_WEAPONS,
	"Janitor" = CIVILIAN_WEAPONS,
	"Rancher" = CIVILIAN_WEAPONS,
	"Staff Assistant" = CIVILIAN_WEAPONS
)

var/static/list/angry_fucker_weapon_weights = list(
	energy_gun = 70,
	kinetic_gun = 30,
)

var/list/valid_energy_gun_list = list()
var/list/valid_kinetic_gun_list = list()

/client/proc/populate_with_angry_fuckers()
	SET_ADMIN_CAT(ADMIN_CAT_FUN)
	set name = "Populate With Angry Bois"

	var/gun_weight = tgui_input_number(usr, "Probability of rolling a real gun?", "Real gun", 0, 100, 0)
	var/job_weapon_weight = 100 - gun_weight
	if(tgui_alert(usr, "Are you fucking sure about this? This will lag to fuck!", "BE CERTAIN.", list("YAYA", "NAH")) == "YAYA")
		angry_fucker_setup(gun_weight, job_weapon_weight)
		usr.show_text("Oh god. It's happening.", "blue")
		logTheThing(LOG_ADMIN, usr, "has populated the station with angry motherfuckers!")
	else
		usr.show_text("Good choice.", "red")

/proc/angry_fucker_setup(gun_weight, job_weapon_weight)
	for(var/job_name in job_start_locations)
		if(job_name == "AI" || job_name == "Cyborg")
			continue
		for(var/turf/T in job_start_locations[job_name])
			var/mob/living/carbon/human/npc/NTemployee/H = new(T)
			H.JobEquipSpawned(job_name)
			var/gun_or_shit = weighted_pick(list("gun" = gun_weight, "shit" = job_weapon_weight))
			var/find_a_hand
			if (H.l_hand)
				find_a_hand = H.slot_r_hand
			else
				find_a_hand = H.slot_l_hand
			switch(gun_or_shit)
				if("gun")
					var/gun_to_be
					switch(pick(weighted_pick(angry_fucker_weapon_weights)))
						if("energy_gun")
							gun_to_be = pick(valid_energy_gun_list)
						if("kinetic_gun")
							gun_to_be = pick(valid_kinetic_gun_list)
						else
							gun_to_be = pick(valid_kinetic_gun_list)
					H.equip_new_if_possible(gun_to_be, find_a_hand)
				if("shit")
					var/weapon_of_choice = pick_a_weapon(job_name)
					H.equip_new_if_possible(weapon_of_choice, find_a_hand)
			H.update_inhands()

/proc/energy_weapons_setup()
	var/list/exemptions = list(
		/obj/item/gun/energy/howitzer,
		/obj/item/gun/energy/owl,
		/obj/item/gun/energy/owl_safe,
		/obj/item/gun/energy/plasma_gun/hunter,
		/obj/item/gun/energy/shrinkray,
		/obj/item/gun/energy/shrinkray/growray,
		/obj/item/gun/energy/stinkray
	)
	var/list/gun_list = list()
	for(var/obj/item/gun/energy/the_gun as anything in concrete_typesof(/obj/item/gun/energy))
		for(var/i in 1 to length(exemptions))
			if(exemptions[i] == the_gun)
				break
		gun_list += the_gun
	valid_energy_gun_list = gun_list

/proc/kinetic_weapons_setup()
	var/list/exemptions = list(
		/obj/item/gun/kinetic/meowitzer,
		/obj/item/gun/kinetic/slamgun,
		/obj/item/gun/kinetic/zipgun
	)
	var/list/gun_list = list()
	for(var/obj/item/gun/kinetic/the_gun as anything in concrete_typesof(/obj/item/gun/kinetic))
		for(var/i in 1 to length(exemptions))
			if(exemptions[i] == the_gun)
				break
		gun_list += the_gun
	valid_kinetic_gun_list = gun_list

/proc/pick_a_weapon(var/job_name)
	var/get_department
	for(var/i in jobs_and_departments)
		if(i == job_name)
			get_department = jobs_and_departments[i]
	if(!get_department)
		get_department = CIVILIAN_WEAPONS

	switch(get_department)
		if(CARGO_WEAPONS)
			. = shitty_cargo_weapons[rand(1, length(shitty_cargo_weapons))]
		if(CIVILIAN_WEAPONS)
			. = shitty_civ_weapons[rand(1, length(shitty_civ_weapons))]
		if(COMMAND_WEAPONS)
			. = /obj/item/swords/captain
		if(ENGINEERING_WEAPONS)
			. = shitty_eng_weapons[rand(1, length(shitty_eng_weapons))]
		if(HONK_WEAPONS)
			. = /obj/item/reagent_containers/food/snacks/pie/cream
		if(MEDICAL_WEAPONS)
			. = shitty_med_weapons[rand(1, length(shitty_med_weapons))]
		if(RESEARCH_WEAPONS)
			. = shitty_sci_weapons[rand(1, length(shitty_sci_weapons))]
		if(SECURITY_WEAPONS)
			. = shitty_sec_weapons[rand(1, length(shitty_sec_weapons))]


#define IS_NPC_HATED_ITEM(x) ( \
		istype(x, /obj/item/clothing/suit/straight_jacket) || \
		istype(x, /obj/item/handcuffs) || \
		istype(x, /obj/item/device/radio/electropack) || \
		x:block_vision \
	)
#define IS_NPC_CLOTHING(x) ( \
		( \
			istype(x, /obj/item/clothing) || \
			istype(x, /obj/item/device/radio/headset) || \
			istype(x, /obj/item/card/id) || \
			x.c_flags & ONBELT || \
			x.c_flags & ONBACK \
		) && !IS_NPC_HATED_ITEM(x) \
	)

/mob/living/carbon/human/npc/NTemployee
	name = "Employee"
	ai_aggressive = 1
	var/mutantrace_chance = 0.4

	New()
		. = ..()
		SPAWN(1 SECOND)
			if(rand() <= src.mutantrace_chance)
				src.set_mutantrace(pick(mutantrace_choices))

	initializeBioholder(gender)
		if(gender)
			src.gender = gender
		. = ..()
		randomize_look(src, !gender, 1, 1, 1, 1, 1)
		set_clothing_icon_dirty()
		APPLY_ATOM_PROPERTY(src, PROP_MOB_THERMALVISION_MK2, "angry bois see all")

	// Overriding default AI things, since I want these guys to be more merciless in combat.
	ai_do_hand_stuff()
		// suplex and table!
		if(isgrab(src.r_hand) || isgrab(src.l_hand))
			var/obj/item/grab/grab = src.equipped()
			if(!istype(grab))
				src.swap_hand()
				grab = src.equipped()
			if(prob(10) || grab.state > 0)
				if(prob(80))
					var/list/obj/table/tables = list()
					for(var/obj/table/table in view(1))
						tables += table
					if(length(tables))
						src.ai_attack_target(pick(tables), grab)
				if(!grab.disposed && grab.loc == src)
					src.emote("flip", TRUE)

		// swap hands
		if(src.r_hand && src.l_hand)
			if(prob(src.hand ? 15 : 4))
				src.swap_hand()
		else if(!src.equipped() && (src.r_hand || src.l_hand))
			src.swap_hand()

		if(!src.equipped())
			return

		var/throw_equipped

		if(IS_NPC_HATED_ITEM(src.equipped()))
			throw_equipped |= prob(80)

		// wear clothes
		if(src.hand && IS_NPC_CLOTHING(src.equipped()) && prob(80) && (!(src.equipped()?.c_flags & ONBELT) || prob(0.1)))
			src.hud.relay_click("invtoggle", src, list())
			if(src.equipped())
				throw_equipped |= prob(80)

		// eat, drink, splash!
		if(istype(src.equipped(), /obj/item/reagent_containers))
			var/poured = FALSE
			if(istype(src.equipped(), /obj/item/reagent_containers/glass) || prob(20))
				for(var/obj/item/reagent_containers/container in view(1, src))
					if(container != src.equipped() && container.is_open_container() && container.reagents?.total_volume < container.reagents?.maximum_volume)
						src.ai_attack_target(container, src.equipped())
						poured = TRUE
						break

		// use (prevented from using reagent container on self)
		if(src.equipped() && prob(ai_state == AI_PASSIVE ? 2 : 7) && ai_useitems && !istype(src.equipped(), /obj/item/reagent_containers))
			src.equipped().AttackSelf(src)

		// throw
		if(throw_equipped)
			var/turf/T = get_turf(src)
			if(T)
				SPAWN(0.2 SECONDS) // todo: probably reorder ai_move stuff and remove this spawn, without this they keep hitting themselves
					src.throw_item(locate(T.x + rand(-5, 5), T.y + rand(-5, 5), T.z), list("npc_throw"))

	// Adjusted the score weightings of certain items, de-prioritises some things entirely.
	// TO DO: increase weight of whitelisted job weapons.
	ai_pickupoffhand()
		if(src.l_hand?.cant_drop)
			return

		var/obj/item/pickup
		var/pickup_score = 0

		for (var/obj/item/G in view(1,src))
			if(G.anchored || G.throwing) continue
			var/score = 0
			if(G.loc == src && !G.equipped_in_slot) // probably organs
				continue
			if(istype(G, /obj/item/chem_grenade) || istype(G, /obj/item/old_grenade))
				score += 6
			if(IS_NPC_CLOTHING(G) && (G.loc != src || prob(2)) && !ON_COOLDOWN(src, "pickup clothing", 30 SECONDS))
				score -= 10
			else if(IS_NPC_CLOTHING(G) && G.loc == src)
				continue
			if(IS_NPC_HATED_ITEM(G))
				score -= 10
			if(istype(G, /obj/item/reagent_containers) && G.reagents?.total_volume > 0)
				score += 5
			if(G.loc == src)
				score += 1
			score += G.contraband // this doesn't use get_contraband() because monkeys aren't feds
			if(score > pickup_score)
				pickup_score = score
				pickup = G

		if(src.l_hand && pickup && pickup != src.l_hand)
			var/obj/item/LHITM = src.l_hand
			src.u_equip(LHITM)
			LHITM.set_loc(get_turf(src))
			LHITM.dropped(src)
			LHITM.layer = initial(LHITM.layer)

		if(pickup && !src.l_hand)
			src.swap_hand(1)
			if(pickup.equipped_in_slot)
				src.u_equip(pickup)
			if(src.put_in_hand_or_drop(pickup))
				src.set_clothing_icon_dirty()

#undef IS_NPC_HATED_ITEM
#undef IS_NPC_CLOTHING

#undef CARGO_WEAPONS
#undef CIVILIAN_WEAPONS
#undef COMMAND_WEAPONS
#undef ENGINEERING_WEAPONS
#undef HONK_WEAPONS
#undef MEDICAL_WEAPONS
#undef RESEARCH_WEAPONS
#undef SECURITY_WEAPONS

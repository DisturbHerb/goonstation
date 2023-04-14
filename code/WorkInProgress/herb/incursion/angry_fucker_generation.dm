#define DEFAULT_WEAPON_WEIGHT 50
#define DEFAULT_ARMOUR_WEIGHT 50
#define DEFAULT_INTERNALS_WEIGHT 80
#define MAX_WEIGHT 100

// Admin verb to fire angry_fucker_setup().
/client/proc/populate_with_angry_fuckers()
	SET_ADMIN_CAT(ADMIN_CAT_FUN)
	set name = "Populate With Angry Bois"

	var/weapon_weight = tgui_input_number(usr, "Probability of rolling a real weapon?", "Real weapon", DEFAULT_WEAPON_WEIGHT, MAX_WEIGHT, 0)
	var/job_weapon_weight = 100 - weapon_weight
	var/armour_weight = tgui_input_number(usr, "Probability of rolling body armour?", "Body Armour", DEFAULT_ARMOUR_WEIGHT, MAX_WEIGHT, 0)
	var/internals_weight = tgui_input_number(usr, "Probability of rolling internals?", "Internals", DEFAULT_INTERNALS_WEIGHT, MAX_WEIGHT, 0)
	if(tgui_alert(usr, "Are you fucking sure about this? This will lag to fuck!", "BE CERTAIN.", list("YAYA", "NAH")) == "YAYA")
		angry_fucker_setup(weapon_weight, job_weapon_weight, armour_weight, internals_weight)
		var/ratio = "[weapon_weight]:[job_weapon_weight]"
		usr.show_text("Oh god. It's happening.", "blue")
		message_admins("([usr.ckey]) has populated the station with angry motherfuckers, at a [ratio] ratio of weapons to shit!")
		logTheThing(LOG_ADMIN, usr.ckey, "has populated the station with angry motherfuckers, at a [ratio] ratio of weapons to shit!")

		// Incursion gamemode-specific stuff.
		if(istype(ticker?.mode, /datum/game_mode/incursion))
			var/datum/game_mode/incursion/incursion = ticker.mode
			incursion.can_finish = TRUE
			message_admins("([usr.ckey]) has started the Syndicate Incursion! The round will end once one side is eliminated!")

	else
		usr.show_text("Good choice.", "red")

#undef DEFAULT_WEAPON_WEIGHT
#undef DEFAULT_ARMOUR_WEIGHT
#undef DEFAULT_INTERNALS_WEIGHT
#undef MAX_WEIGHT

/** Populates the station with "angry fuckers". Every angry fucker spawns with a weapon of some type, with a weighted pick of either actual guns or
	"shitty" weapons which are then picked from their respective whitelists. */
/proc/angry_fucker_setup(weapon_weight, job_weapon_weight, armour_weight, internals_weight)
	for(var/job_name in job_start_locations)
		// Don't spawn mobs with these jobs.
		if(job_name == "AI" || job_name == "Cyborg" || job_name == "JoinLate")
			continue
		for(var/turf/T in job_start_locations[job_name])
			var/mob/living/carbon/human/npc/NTemployee/H = new(T)
			H.JobEquipSpawned(job_name)

			// fuck you, no backpack or storage
			if(H.back && istype(H.back,/obj/item/storage/backpack))
				qdel(H.back)
			if(H.l_store)
				qdel(H.l_store)
			if(H.r_store)
				qdel(H.r_store)

			// fuck your hands
			if(H.l_hand)
				qdel(H.l_hand)
			if(H.r_hand)
				qdel(H.r_hand)

			// Spawn them a weapon! Gun to shit ratio is determined by input from whatever client called the proc.
			var/gun_or_shit = weighted_pick(list("gun" = weapon_weight, "shit" = job_weapon_weight))
			var/weapon_of_choice
			switch(gun_or_shit)
				if("gun")
					switch(pick(weighted_pick(angry_fucker_weapon_weights)))
						if("energy_gun")
							weapon_of_choice = weighted_pick(valid_energy_gun_list)
						if("kinetic_gun")
							weapon_of_choice = weighted_pick(valid_kinetic_gun_list)
						if("throwable")
							weapon_of_choice = weighted_pick(valid_throwable_list)
						else
							weapon_of_choice = weighted_pick(valid_kinetic_gun_list)
				if("shit")
					weapon_of_choice = pick_a_weapon(job_name)
			if(!weapon_of_choice)
				weapon_of_choice = /obj/item/rubberduck
			H.equip_new_if_possible(weapon_of_choice, pick(H.slot_l_hand, H.slot_r_hand))

			if(prob(armour_weight))
				if(!istype(H.wear_suit, /obj/item/clothing/suit/armor))
					qdel(H.wear_suit)
					var/armour_of_choice = weighted_pick(worn_suit_weights_list)
					H.equip_new_if_possible(armour_of_choice, H.slot_wear_suit)

			if(prob(internals_weight))
				if(!istype(H.wear_mask, /obj/item/clothing/mask/gas))
					qdel(H.wear_mask)
					var/mask_of_choice = weighted_pick(internals_weights_list)
					H.equip_new_if_possible(mask_of_choice, H.slot_wear_mask)
				H.equip_new_if_possible(/obj/item/tank/emergency_oxygen, H.slot_l_store)

			H.update_clothing()
			H.update_inhands()

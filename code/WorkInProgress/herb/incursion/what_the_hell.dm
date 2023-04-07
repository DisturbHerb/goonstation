// yaya

/mob/living/carbon/human/jennifer/proc/yayaMode(var/fast)
	var/emotePicker = rand(0,4)
	if(fast)
		switch(emotePicker)
			if(0)
				SPAWN(0) src.emote("eyelick")
			if(1)
				SPAWN(0) src.emote("scream")
			if(2)
				SPAWN(0) src.say("Yaya!!")
			if(3)
				SPAWN(0) src.say("What!!")
			if(4)
				SPAWN(0) src.say("Huh??")
	else
		switch(emotePicker)
			if(0)
				SPAWN(0) src.emote("eyelick")
			if(1)
				SPAWN(0) src.emote("scream")
				walk_rand(src)
				sleep(10)
				walk(src, 0)
			if(2)
				SPAWN(0) src.say("Yaya!!")
			if(3)
				SPAWN(0) src.say("What!!")
			if(4)
				SPAWN(0) src.say("Huh??")

/mob/living/carbon/human/jennifer
	is_npc = 1
	uses_mobai = 1

	New()
		..()
		src.real_name = "Jennifer Dodge"
		src.bioHolder.AddEffect("lizard")
		src.equip_new_if_possible(/obj/item/storage/backpack, src.slot_back)
		src.equip_new_if_possible(/obj/item/clothing/gloves/ring/gold, src.slot_gloves)
		src.equip_new_if_possible(/obj/item/clothing/under/gimmick/wedding_dress, src.slot_w_uniform)

		var/obj/item/toy/plush/small/kitten/fluffles = new /obj/item/toy/plush/small/kitten/(get_turf(src))
		if(!islist(fluffles.name_suffixes))
			fluffles.name_suffixes = list()
		fluffles.name_suffix("(Mr. Fluffles!!! ♥♥)")
		fluffles.UpdateName()

		src.equip_if_possible(fluffles, src.slot_r_hand)

		src.ai = new /datum/aiHolder/human/yank(src)
		src.ai.enabled = 0

		START_TRACKING

	disposing()
		STOP_TRACKING
		..()

	initializeBioholder()
		. = ..()
		bioHolder.age = 22
		bioHolder.mobAppearance.customization_first_color = "#ff5050"
		bioHolder.mobAppearance.customization_second_color = "#ff7c80"
		bioHolder.mobAppearance.customization_third_color = "#ff7c80"
		bioHolder.mobAppearance.e_color = "#ffa200"
		bioHolder.mobAppearance.screamsound = "femalescream4"
		bioHolder.mobAppearance.fartsound = "fart2"
		bioHolder.mobAppearance.gender = "male"
		bioHolder.mobAppearance.pronouns = get_singleton(/datum/pronouns/sheHer)
		bioHolder.mobAppearance.voicetype = "Two"
		bioHolder.mobAppearance.flavor_text = "Curiously tall lizard. What's she doing here?"

	Life(datum/controller/process/mobs/parent)
		if (..(parent))
			return 1

		if(prob(20) && !src.stat && src.ai_state != AI_ATTACKING)
			step_rand(src)

		if(prob(5) && !src.stat && src.ai_state != AI_ATTACKING)
			yayaMode(FALSE)

	was_harmed(var/mob/M as mob, var/obj/item/weapon = 0, var/special = 0, var/intent = null)
		. = ..()
		SPAWN(0) src.emote("scream")
		src.target = M
		src.ai_state = AI_ATTACKING
		src.ai_threatened = world.timeofday
		src.ai_target = M
		src.ai.enabled = 1
	zoomy

		Life(datum/controller/process/mobs/parent)
			if (..(parent))
				return 1

			if(!src.stat)
				walk_rand(src)

			yayaMode(TRUE)

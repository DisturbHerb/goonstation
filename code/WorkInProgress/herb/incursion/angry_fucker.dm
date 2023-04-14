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

// Mutantraces that an angry fucker can spawn as.
var/static/list/mutantrace_choices = list(
	/datum/mutantrace/cow,
	/datum/mutantrace/lizard,
	/datum/mutantrace/pug,
	/datum/mutantrace/roach,
	/datum/mutantrace/skeleton
)

// THE angry fucker themself!
/mob/living/carbon/human/npc/NTemployee
	name = "Employee"
	ai_aggressive = 1
	ai_useitems = 0 // stop using grenades for fuck's sake
	var/is_jennifer = FALSE
	var/mutantrace_chance = 0.4
	var/list/will_attack = list(ROLE_INCURSION, ROLE_INCURSION_COMMANDER, ROLE_NUKEOP, ROLE_NUKEOP_COMMANDER, ROLE_NUKEOP_GUNBOT)

	New()
		. = ..()
		START_TRACKING_CAT(TR_CAT_NTEMPLOYEES)
		SPAWN(1 SECOND)
			if(rand() <= src.mutantrace_chance)
				var/datum/mutantrace/the_mutantrace = pick(mutantrace_choices)
				if(istype(the_mutantrace,/datum/mutantrace/cow))
					qdel(src.shoes)
				src.set_mutantrace(the_mutantrace)

	initializeBioholder(gender)
		if(gender)
			src.gender = gender
		. = ..()
		randomize_look(src, !gender, 1, 1, 1, 1, 1)
		set_clothing_icon_dirty()
		APPLY_ATOM_PROPERTY(src, PROP_MOB_THERMALVISION_MK2, "angry bois see all")

	attack_hand(mob/M)
		..()
		if(M.a_intent in list(INTENT_HARM,INTENT_DISARM,INTENT_GRAB))
			if(!ON_COOLDOWN(src, "cry_attacked", 5 SECONDS))
				SPAWN(rand(10,30))
					src.cry_attacked(M)

	attackby(obj/item/W, mob/M)
		var/oldbloss = get_brute_damage()
		var/oldfloss = get_burn_damage()
		..()
		var/damage = ((get_brute_damage() - oldbloss) + (get_burn_damage() - oldfloss))
		if((damage > 0) || W.force)
			if(!ON_COOLDOWN(src, "cry_attacked", 5 SECONDS))
				SPAWN(rand(10,30))
					src.cry_attacked(M)

	death()
		..()
		STOP_TRACKING_CAT(TR_CAT_NTEMPLOYEES)

	abom
		name = "OH FUCK OH GOD"
		desc = "WHAT THE FUCK IS THAT THING"
		icon = 'icons/mob/abomination.dmi'
		icon_state = "abomination"

		New()
			..()
			src.set_mutantrace(/datum/mutantrace/abomination/admin/weak)


// Please god only attack the specified antags.
/mob/living/carbon/human/npc/NTemployee/ai_findtarget_new()
	for(var/mob/living/M in viewers(7,src))
		for(var/i in 1 to length(src.will_attack))
			if(M.mind.special_role == src.will_attack[i])
				..()

// Overriding default AI things, since I want these guys to be more merciless in combat.
/mob/living/carbon/human/npc/NTemployee/ai_do_hand_stuff()
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
/mob/living/carbon/human/npc/NTemployee/ai_pickupoffhand()
	if(src.l_hand?.cant_drop)
		return

	var/obj/item/pickup
	var/pickup_score = 0

	for (var/obj/item/G in view(1,src))
		if(G.anchored || G.throwing) continue
		var/score = 0
		if(G.loc == src && !G.equipped_in_slot) // probably organs
			continue
		// Increased grenade weight for funny.
		if(istype(G, /obj/item/chem_grenade) || istype(G, /obj/item/old_grenade))
			score += 10
		if(IS_NPC_CLOTHING(G) && (G.loc != src || prob(2)) && !ON_COOLDOWN(src, "pickup clothing", 30 SECONDS))
			score -= 10
		else if(IS_NPC_CLOTHING(G) && G.loc == src)
			continue
		if(IS_NPC_HATED_ITEM(G))
			score -= 10
		if(istype(G, /obj/item/reagent_containers) && G.reagents?.total_volume > 0)
			if (istype(G, /obj/item/reagent_containers/glass/bottle/pacid))
				score += 10 // hahaha
			else
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

// Grenade throwing and shit-talking. I hope.
/mob/living/carbon/human/npc/NTemployee/ai_action()
	..()
	var/area/A = get_area(src)
	var/distance = GET_DIST(src,ai_target)
	if(src.ai_state == AI_ATTACKING || iscarbon(src.ai_target))
		//Talk shit!
		if(prob(75) && distance > 1 && (world.timeofday - ai_attacked) > 100 && ai_validpath() && !A?.sanctuary && !src.is_jennifer)
			var/buffer
			switch(pick(1,2))
				if(1)
					buffer = (pick("+Fuck you!+",\
					"You're [prob(10) ? "fucking " : ""]+dead,+ Syndie!",\
					"I will |kill| you!!",\
					"Asshole!",\
					"[prob(10) ? "My name is [src.name]! You killed my father! Prepare" : "Time"] to die!",\
					"Retribution!",\
					"For Nanotrasen!",\
					"Syndie [pick("shitbag", "asshole", "snake", "stinker")]!",\
					"Greytide worldwide, |asshole!|",\
					"You picked the wrong house, fool!"))
				if(2)
					buffer = (pick("Eat lead!", "Suck it down!"))
			if(prob(30))
				buffer = uppertext(buffer)
			src.say(buffer)
		//Nading your ass.
		if(ai_validpath() && src.equipped() && (istype(src.equipped(),/obj/item/old_grenade) || istype(src.equipped(),/obj/item/chem_grenade)) && !A?.sanctuary)
			ai_target_old.Cut()
			src.equipped().AttackSelf(src)
			src.throw_item(ai_target, list("npc_throw"))
		//Single-actions? How bothersome!
		if(istype(src.equipped(), /obj/item/gun/kinetic/single_action))
			var/obj/item/gun/kinetic/single_action/the_gun = src.equipped()
			if(the_gun.hammer_cocked == FALSE && the_gun.ammo)
				the_gun.AttackSelf(src)

	// if you've suddenly got no oxygen
	if(src.oxyloss > 10 || src.losebreath >= 4)
		var/obj/item/tank/tank_to_use
		for(var/obj/item/stored_item in src.contents)
			if(istype(stored_item, /obj/item/tank))
				tank_to_use = stored_item
		if(tank_to_use && !src.internal)
			tank_to_use.toggle_valve()
		if(tank_to_use && (src.oxyloss > 30 || src.losebreath >= 12)) // uh oh, my tank's probably empty
			src.put_in_hand_or_drop(tank_to_use)
			if(src.equipped() == tank_to_use)
				src.drop_item_throw(tank_to_use)

/mob/living/carbon/human/npc/NTemployee/proc/cry_attacked(mob/M)
	if(!M)
		return
	if(isdead(src))
		return
	src.target = M
	src.ai_state = AI_ATTACKING
	src.ai_threatened = world.timeofday
	var/complaint = pick("+[pick("OW", "AGH", "FUCK", "SHIT")]!+ [pick("SCREW [pick("OFF", "YOU")]", "FUCK [pick("OFF", "YOU")]", "DAMN YOU", "PISS OFF")] SYNDIE!",\
	"+[pick("OW", "AGH", "FUCK", "SHIT", "SHIVER ME TIMBERS", "THAT FUCKING HURT", "ASSHOLE", "FUCKER", "GOD DAMN IT")]!+",\
	"[pick("[pick("GOD DAMN", "FUCKING", "MOTHERFUCKING")] SYNDICATE +[pick("SNAKE", "SHITTER", "SHITHEAD", "ASSHOLE")]")]!+")
	complaint = uppertext(complaint)
	var/max_excl = rand(-2,4)
	for(var/i = 0, i < max_excl, i++)
		complaint += "!"
	src.say("[complaint]")

// WEAPONS
/obj/item/gun/kinetic/assault_rifle/empty

	New()
		..()
		ammo.amount_left = 0
		UpdateIcon()

/obj/item/gun/kinetic/spes/engineer/empty

	New()
		..()
		ammo.amount_left = 0
		UpdateIcon()

/obj/item/gun/kinetic/light_machine_gun/empty

	New()
		..()
		ammo.amount_left = 0
		UpdateIcon()

/obj/item/gun/kinetic/pistol/empty

	New()
		..()
		ammo.amount_left = 0
		UpdateIcon()

/obj/item/storage/belt/gun/pistol/empty
	spawn_contents = list(/obj/item/gun/kinetic/pistol/empty, /obj/item/ammo/bullets/bullet_9mm = 4)

// LOADOUTS (for sending supply drops)
/obj/storage/crate/classcrate/rifleman
	name = "Class Crate - Specialist"
	desc = "A crate containing the barest of essentials for a Syndicate specialist."
	spawn_contents = list(/obj/item/gun/kinetic/assault_rifle/empty,
	/obj/item/storage/pouch/assault_rifle/mixed,
	/obj/item/clothing/suit/space/syndicate/specialist,
	/obj/item/clothing/head/helmet/space/syndicate/specialist,
	/obj/item/chem_grenade/flashbang)

// FLAVOUR
/obj/item/device/audio_log/incursion_briefing
	name = "Mission Briefing"
	desc = "The standard for covert mission briefing."
	continuous = 0

	New(newloc)
		..()
		src.audiolog_messages += "Your mission this time is simple, team."
		src.audiolog_messages += "NanoTrasen has been causing us significant trouble establishing [station_name(1)] out here."
		src.audiolog_messages += "We have decided to take swift and decisive action to kick them out."
		src.audiolog_messages += "You must eliminate all NanoTrasen employees aboard the [station_or_ship()]. Give no quarter."
		src.audiolog_speakers.len = length(src.audiolog_messages)

		if (!src.tape)
			src.tape = new /obj/item/audio_tape(src)

		src.tape.messages = src.audiolog_messages
		src.audiolog_messages = null

		src.tape.speakers = src.audiolog_speakers
		src.audiolog_speakers = null

		return

/obj/item/pinpointer/ntemployee
	name = "nanotrasen rat pinpointer"
	desc = "Locates NanoTrasen employees."
	icon_state = "nuke_pinoff"
	hudarrow_color = "#ad1400"

	var/category = TR_CAT_NTEMPLOYEES
	var/thing_name = "NanoTrasen employee"
	var/in_or_on = "in"
	var/z_locked = null // Z-level number if locked to that Z-level
	var/include_area_text = TRUE

	proc/get_choices()
		var/list/trackable
		if(istext(category))
			trackable = by_cat[category]
		else if(ispath(category))
			trackable = by_type[category]
		. = list()
		for(var/atom/A in trackable)
			var/turf/T = get_turf(A)
			if(A.disposed || isnull(T))
				continue
			if(!isnull(z_locked) && z_locked != T.z)
				continue
			var/dist = GET_DIST(A, src)
			if(!isnull(max_range) && dist > max_range)
				continue
			.[A] = A

	proc/process_choice(choice, list/choices, mob/user)
		if(isnull(choice))
			return null
		return choices[choice]

	attack_self(mob/user)
		if(!active)
			if(isnull(category))
				user.show_text("No tracking category, cannot activate the pinpointer.", "red")
				return
			var/list/choices = get_choices()
			if(!length(choices))
				user.show_text("No [thing_name]s available, cannot activate the pinpointer.", "red")
				return

			var/current_closest
			var/current_closest_dist
			for(var/i in 1 to length(choices))
				if (!current_closest)
					current_closest = choices[i]
					current_closest_dist = GET_DIST(current_closest, src)
					continue
				var/comparison = choices[i]
				var/comparison_dist = GET_DIST(comparison, src)
				if (current_closest_dist > comparison_dist)
					current_closest = choices[i]
					current_closest_dist = comparison_dist

			if(isnull(current_closest))
				return
			var/atom/potential_target = process_choice(current_closest, choices, user)
			if(isnull(potential_target))
				return
			target = potential_target
		. = ..()

#define FT_REMOVAL "Remove target from fireteam"

/obj/item/fireteam_designator
	name = "fireteam deisgnator"
	desc = "target device that handily assigns someone to a selected fireteam. Works almost identically to a hand labeller, woah!"
	icon = 'icons/obj/items/device.dmi'
	icon_state = "blueprintmarker"
	item_state = "blueprintmarker"
	flags = FPRINT | TABLEPASS | SUPPRESSATTACK
	c_flags = ONBELT

	var/static/regex/fireteam_clearer = regex(@"(Alpha|Bravo|Charlie|Delta)\s(Fireteam)\s", "g")
	var/list/fireteam_prefixes = list("Alpha Fireteam", "Bravo Fireteam", "Charlie Fireteam", "Delta Fireteam")
	var/assignment = null
	var/removal_mode = FALSE

	New()
		..()
		src.assignment = src.fireteam_prefixes[1]

	get_desc()
		if (!src.assignment || !length(src.assignment))
			. += "<br>It doesn't have a fireteam set."
		else
			. += "<br>Currently assigning personnel to \"[src.assignment]\"."

	attack_self(mob/user)
		if(!user.literate)
			boutput(user, "<span class='alert'>You don't know how to write.</span>")
			return
		var/fireteam = tgui_input_list(user, "Select a fireteam.", "Fireteam Selection", (src.fireteam_prefixes + FT_REMOVAL), start_with_search = FALSE)
		if (fireteam == FT_REMOVAL)
			src.removal_mode = TRUE
			src.assignment = null
			boutput(user, "<span class='alert'>You set [src] to remove personnel from their assigned fireteam.</span>")
		else
			src.removal_mode = FALSE
			src.assignment = fireteam
			boutput(user, "<span class='alert'>You set [src] to assign personnel to [src.assignment].</span>")

	attack(mob/M, mob/user)
		if (src.removal_mode)
			src.remove_from_fireteam(M, user)
			return

		src.add_to_fireteam(M, user)

	proc/add_to_fireteam(mob/target, mob/user)
		if(!src.assignment)
			boutput(user, "<span class='alert'>Uh oh! Looks like this [src] is broken somehow.</span>")

		target.real_name = fireteam_clearer.Replace_char(target.real_name, "")
		target.real_name = "[src.assignment] [target.real_name]"
		target.UpdateName()
		user.visible_message("<span class='notice'><b>[user]</b> assigns [target] to [src.assignment].</span>",\
			"<span class='notice'>You add [target] to [src.assignment].</span>")
		target.add_fingerprint(user)
		playsound(src, 'sound/items/hand_label.ogg', 40, 1)

	proc/remove_from_fireteam(mob/target, mob/user)
		target.real_name = fireteam_clearer.Replace_char(target.real_name, "")
		target.UpdateName()
		user.visible_message("<span class='notice'><b>[user]</b> removes [target] from all fireteams.</span>",\
		"<span class='notice'>You remove [target] from all fireteams.</span>")
		target.add_fingerprint(user)
		return

#undef FT_REMOVAL

/obj/item/paper/syndicateIOU
	name = "'I OWE YOU"
	info = {"<span style="color:#FF00FF;font-family:Comic Sans MS"><h1>IOU: x1 pod interceptor wing<br>
	from MOPSY</h1></span>"}

	New()
		. = ..()
		src.stamp(200, 20, rand(-5,5), "stamp-clown.png", "stamp-clown")

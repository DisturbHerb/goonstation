// WEAPONS
/obj/item/gun/kinetic/assault_rifle/empty

	New()
		..()
		var/obj/item/gun/kinetic/assault_rifle/empty_gun = new(src.loc ? src.loc : get_turf(src))
		empty_gun.pixel_x = src.pixel_x
		empty_gun.pixel_y = src.pixel_y
		empty_gun.ammo.amount_left = 0
		empty_gun.UpdateIcon()
		qdel(src)

/obj/item/gun/kinetic/spes/engineer/empty

	New()
		..()
		var/obj/item/gun/kinetic/spes/engineer/empty_gun = new(src.loc ? src.loc : get_turf(src))
		empty_gun.pixel_x = src.pixel_x
		empty_gun.pixel_y = src.pixel_y
		empty_gun.ammo.amount_left = 0
		empty_gun.UpdateIcon()
		qdel(src)

/obj/item/gun/kinetic/light_machine_gun/empty

	New()
		..()
		var/obj/item/gun/kinetic/light_machine_gun/empty_gun = new(src.loc ? src.loc : get_turf(src))
		empty_gun.pixel_x = src.pixel_x
		empty_gun.pixel_y = src.pixel_y
		empty_gun.ammo.amount_left = 0
		empty_gun.UpdateIcon()
		qdel(src)

/obj/item/gun/kinetic/pistol/empty

	New()
		..()
		var/obj/item/gun/kinetic/pistol/empty_gun = new(src.loc ? src.loc : get_turf(src))
		empty_gun.pixel_x = src.pixel_x
		empty_gun.pixel_y = src.pixel_y
		empty_gun.ammo.amount_left = 0
		empty_gun.UpdateIcon()
		qdel(src)

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

// ALTAI
/obj/item/device/laser_designator/syndicate/altai
	desc = "A handheld monocular device with a laser built into it, used for calling in fire support from the Altai."
	ship_looking_for = "Altai"

	New()
		..()
		desc = "A handheld monocular device with a laser built into it, used for calling in fire support from the Altai. It has [src.uses] charge left."

	airstrike(atom/target, params, mob/user, reach)
		..()
		src.desc = "A handheld monocular device with a laser built into it, used for calling in fire support from the Altai. It has [src.uses] charge left."
		return TRUE

/obj/machinery/broadside_gun/artillery_cannon/syndicate/altai
	firingfrom = "Altai"

// FLAVOUR
/obj/item/clothing/under/suit/hos/syndicate
	name = "\improper Syndicate formal dress suit"
	desc = "A red suit and black necktie. This one seems oddly familiar."

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

	var/static/regex/fireteam_clearer = regex(@"(Able|Baker|Charlie|Dog)\s(Fireteam)\s", "g")
	var/list/fireteam_prefixes = list("Able Fireteam", "Baker Fireteam", "Charlie Fireteam", "Dog Fireteam")
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

	afterattack(atom/A, mob/user as mob)
		if (ismob(A))
			return
		if (istype(A, /obj/item/device/radio))
			if (src.removal_mode)
				src.remove_fireteam_frequency(user, A)
			else if (src.assignment)
				src.set_fireteam_frequency(user, A, src.assignment)

	attack_self(mob/user)
		if(!user.literate)
			boutput(user, "<span class='alert'>You don't know how to write.</span>")
			return
		var/fireteam = tgui_input_list(user, "Select a fireteam.", "Fireteam Selection", (src.fireteam_prefixes + FT_REMOVAL), start_with_search = FALSE)
		if (!fireteam)
			boutput(user, "<span class='alert'>Fireteam selection unchanged.</span>")
			return
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
			boutput(user, "<span class='alert'>Uh oh! There should be an assignment right now!</span>")

		target.real_name = fireteam_clearer.Replace_char(target.real_name, "")
		target.real_name = "[src.assignment] [target.real_name]"
		target.UpdateName()
		user.visible_message("<span class='notice'><b>[user]</b> assigns [target] to [src.assignment].</span>",\
			"<span class='notice'>You add [target] to [src.assignment].</span>")
		target.add_fingerprint(user)
		var/target_radio = target.ears
		if(target_radio && istype(target_radio, /obj/item/device/radio/headset/syndicate))
			src.set_fireteam_frequency(user, target_radio, src.assignment)
		else
			boutput(user, "<span class='alert'>[target] does not have a radio to adjust.</span>")
		playsound(src, 'sound/items/hand_label.ogg', 40, 1)

	proc/remove_from_fireteam(mob/target, mob/user)
		if(src.assignment)
			boutput(user, "<span class='alert'>Uh oh! There shouldn't be an assignment right now!</span>")

		target.real_name = fireteam_clearer.Replace_char(target.real_name, "")
		target.UpdateName()
		user.visible_message("<span class='notice'><b>[user]</b> removes [target] from all fireteams.</span>",\
		"<span class='notice'>You remove [target] from all fireteams.</span>")
		target.add_fingerprint(user)
		var/target_radio = target.ears
		if(target_radio && istype(target_radio, /obj/item/device/radio/headset/syndicate))
			src.remove_fireteam_frequency(user, target_radio)
		else
			boutput(user, "<span class='alert'>[target] does not have a radio to adjust.</span>")
		return

	proc/set_fireteam_frequency(mob/user, obj/item/device/radio/targeted_radio, assignment)
		if(!targeted_radio)
			boutput(user, "<span class='alert'>Uh oh! No radio to set!</span>")
			return
		if(istype(targeted_radio, /obj/item/device/radio/headset/syndicate/leader))
			boutput(user, "<span class='alert'>It's no use! This radio's too powerful!</span>")
			return
		if(ticker?.mode && istype(ticker.mode, /datum/game_mode/incursion))
			var/datum/game_mode/incursion/I = ticker.mode
			var/fireteam_frequency = I.fireteam_frequencies[assignment]
			if(fireteam_frequency)
				targeted_radio.secure_frequencies = list("z" = R_FREQ_SYNDICATE, "g" = fireteam_frequency)
				var/fireteam_class
				switch(assignment)
					if("Able Fireteam")
						fireteam_class = RADIOCL_DETECTIVE
					if("Baker Fireteam")
						fireteam_class = RADIOCL_ENGINEERING
					if("Charlie Fireteam")
						fireteam_class = RADIOCL_RESEARCH
					if("Dog Fireteam")
						fireteam_class = RADIOCL_COMMAND
				if(fireteam_class)
					targeted_radio.secure_classes = list("z" = RADIOCL_SYNDICATE, "g" = fireteam_class)
				targeted_radio.set_secure_frequencies()
				user.visible_message("<span class='notice'><b>[user]</b> adds [targeted_radio] to the [assignment] channel.</span>",\
				"<span class='notice'>You add [targeted_radio] to the [assignment] channel.</span>")

	proc/remove_fireteam_frequency(mob/user, obj/item/device/radio/targeted_radio)
		if(!targeted_radio)
			boutput(user, "<span class='alert'>Uh oh! No radio to set!</span>")
			return
		if(istype(targeted_radio, /obj/item/device/radio/headset/syndicate/leader))
			boutput(user, "<span class='alert'>It's no use! This radio's too powerful!</span>")
			return
		// Known bug: clearing out the radio frequency and attempting to use the :g prefix again will broadcast on frequency 0.0
		targeted_radio.secure_frequencies = list("z" = R_FREQ_SYNDICATE)
		targeted_radio.secure_classes = list("z" = RADIOCL_SYNDICATE)
		targeted_radio.set_secure_frequencies()
		user.visible_message("<span class='notice'><b>[user]</b> sets [targeted_radio] to the default settings.</span>",\
		"<span class='notice'>You set [targeted_radio] to the default settings.</span>")

#undef FT_REMOVAL

#define CAMERA_ON 1
#define CAMERA_OFF 0
/obj/item/device/bodycam
	name = "body camera"
	desc = "A body-worn camera that sends a live feed to all camera-viewing devices in the ALTAI network."
	icon = 'icons/herb/device.dmi'
	icon_state = "bodycam"
	wear_image_icon = 'icons/herb/mob/accessory.dmi'
	item_state = "bodycam"
	rand_pos = FALSE
	c_flags = ONACCESSORY

	var/obj/machinery/camera/camera = null
	var/camera_tag = "Body Cam"
	var/camera_network = "ALTAI"
	var/camera_on = CAMERA_OFF
	var/static/camera_counter = 0

	var/fireteam = null
	var/band_colour = RADIOC_DETECTIVE

	var/desc_sans_camera_status = ""

	New()
		..()

		// Is this a fireteam-level cam?
		if (src.fireteam)
			src.name = "[src.name] ([src.fireteam])"
			src.desc += " This one belongs to [src.fireteam] fireteam."
			src.desc_sans_camera_status = src.desc
			src.camera_tag = "[src.fireteam] [src.camera_tag]"

			// Apply bodycam coloured band.
			var/image/band_image = image(src.icon, "bodycam-band")
			band_image.color = src.band_colour
			src.UpdateOverlays(band_image, "band")

		// Creates the camera and adds it to the network.
		if(src.camera_tag == initial(src.camera_tag))
			src.camera_tag = "Built [src.camera_tag] [src.camera_counter]"
			camera_counter++
		src.camera = new /obj/machinery/camera (src)
		src.camera.c_tag = src.camera_tag
		src.camera.network = src.camera_network

		// Turns the camera off.
		src.turn_off()

	attack_self(mob/user)
		. = ..()
		if (src.camera.camera_status)
			src.turn_off(user)
		else
			src.turn_on(user)

	proc/turn_off(mob/user)
		src.camera.set_camera_status(CAMERA_OFF)
		src.icon_state = "bodycam"
		src.item_state = "bodycam"
		src.desc = src.desc_sans_camera_status + " It's turned off."
		boutput(user, "<span class='notice'>You turn off \the [src].</span>")

	proc/turn_on(mob/user)
		src.camera.set_camera_status(CAMERA_ON)
		src.icon_state = "bodycam-on"
		src.item_state = "bodycam-on"
		src.desc = src.desc_sans_camera_status + " It's turned on and recording."
		boutput(user, "<span class='notice'>You turn on \the [src] and the recording light starts to blink.</span>")

	able
		fireteam = "Able"
		band_colour = RADIOC_DETECTIVE

	baker
		fireteam = "Baker"
		band_colour = RADIOC_ENGINEERING

	charlie
		fireteam = "Charlie"
		band_colour = RADIOC_RESEARCH

	dog
		fireteam = "Dog"
		band_colour = RADIOC_COMMAND

#undef CAMERA_ON
#undef CAMERA_OFF

/obj/item/paper/syndicateIOU
	name = "'I OWE YOU"
	info = {"<span style="color:#FF00FF;font-family:Comic Sans MS"><h1>IOU: x1 pod interceptor wing<br>
	from MOPSY</h1></span>"}

	New()
		. = ..()
		src.stamp(200, 20, rand(-5,5), "stamp-clown.png", "stamp-clown")

/obj/item/paper/syndicate_intelligence_report
	name = "Intelligence Findings Report - HighCom"
	info = {"
		#15 APR 2053
		#FROM EXTERNAL INTELLIGENCE BRANCH
		#ADDRESSED TO FRONTIER SECTOR HIGHCOM
		#SUMMARY OF FINDINGS
		---
		Weather report: Significant burst of stellar radiation originating from star A. Search instrument readings hampered as a result. Further information on NT movements in Frontier star system as of 0500 13th APR is sparse.

		Designated target NT13, Kondaru-type installation, lies in orbit around X-0.

		NanoTrasen naval signals traffic originating around NT13 incrased in volume over the last 24 hours. Presumed occupants aware of impending Syndicate presence in area. Messages appear to have gotten out in spite of electronic interference by jamming efforts or the recent stellar weather event. Efforts are underway to decrypt, however recent changes to NT ciphers has caused delays.

		Any offensive moves against the installation likely to pose extreme danger."}

	New()
		. = ..()
		src.stamp(200, 20, rand(-5,5), "stamp-syndicate.png", "stamp-syndicate")

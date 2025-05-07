/mob/living/silicon/hivebot
	name = "Robot"
	voice_name = "synthesized voice"
	icon = 'icons/mob/hivebot.dmi'
	voice_type = "cyborg"
	icon_state = "vegas"
	health = 60
	max_health = 60
	var/beebot = 0

	// 3 tools can be activated at any one time.
	var/obj/item/robot_module/module = null
	var/module_active = null
	var/list/module_states = list(null,null,null)

	var/datum/hud/shell/hud

	var/obj/item/device/radio/radio = null

	req_access = list(access_robotics)
	//var/energy = 4000
	//var/energy_max = 4000
	var/jetpack = 0

	shell = 1

	sound_fart = 'sound/voice/farts/poo2_robot.ogg'

	var/bruteloss = 0
	var/fireloss = 0

	var/obj/machinery/camera/camera = null

/mob/living/silicon/hivebot/TakeDamage(zone, brute, burn, tox, damage_type, disallow_limb_loss)
	bruteloss += brute
	fireloss += burn
	health_update_queue |= src

/mob/living/silicon/hivebot/HealDamage(zone, brute, burn)
	bruteloss -= brute
	fireloss -= burn
	bruteloss = max(0, bruteloss)
	fireloss = max(0, fireloss)
	health_update_queue |= src

/mob/living/silicon/hivebot/get_brute_damage()
	return bruteloss

/mob/living/silicon/hivebot/get_burn_damage()
	return fireloss

/mob/living/silicon/hivebot/New(loc, mainframe)
	boutput(src, SPAN_NOTICE("Your icons have been generated!"))
	UpdateIcon()

	if (mainframe)
		dependent = 1
		//src.real_name = mainframe:name
		src.name = mainframe:name
	else
		src.real_name = "AI Shell [copytext("\ref[src]", 6, 11)]"
		src.name = src.real_name

	src.radio = new /obj/item/device/radio/headset/command/ai(src)
	src.ears = src.radio

	SPAWN(1 SECOND)
		if (!src.cell)
			src.cell = new /obj/item/cell/shell_cell/charged (src)
		src.camera = new /obj/machinery/camera/auto/AI(src)
		src.camera.c_tag = src.name
		src.camera.network = CAMERA_NETWORK_ROBOTS

	..()
	src.botcard.access = get_all_accesses()

/mob/living/silicon/hivebot/death(gibbed)
	if (src.mainframe)
		logTheThing(LOG_COMBAT, src, "'s AI shell was destroyed at [log_loc(src)].") // Brought in line with carbon mobs (Convair880).
		src.mainframe.return_to(src)
	if (src.camera)
		src.camera.set_camera_status(FALSE)

	setdead(src)
	src.canmove = 0

	vision.set_color_mod("#ffffff") // reset any blindness
	src.sight |= SEE_TURFS
	src.sight |= SEE_MOBS
	src.sight |= SEE_OBJS

	src.see_in_dark = SEE_DARK_FULL
	src.see_invisible = INVIS_CLOAK
	src.UpdateIcon()
/*
	if(src.client)
		SPAWN(0)
			var/key = src.ckey
			recently_dead += key
			sleep(recently_time)
			recently_dead -= key
*/
	src.mind?.register_death()

	return ..(gibbed)

/mob/living/silicon/hivebot/examine(mob/user)
	if (isghostdrone(user))
		return list()

	. = list(SPAN_NOTICE("*---------*"))
	. += SPAN_NOTICE("\nThis is [bicon(src)] <B>[src.name]</B>!")

	if (isdead(src))
		. += SPAN_ALERT("[src.name] is powered-down.")
	if (src.bruteloss)
		if (src.bruteloss < 75)
			. += SPAN_ALERT("[src.name] looks slightly dented.")
		else
			. += SPAN_ALERT("<B>[src.name] looks severely dented!</B>")
	if (src.fireloss)
		if (src.fireloss < 75)
			. += SPAN_ALERT("[src.name] looks slightly burnt!")
		else
			. += SPAN_ALERT("<B>[src.name] looks severely burnt!</B>")
	if (isunconscious(src))
		. += SPAN_ALERT("[src.name] doesn't seem to be responding.")

/mob/living/silicon/hivebot/blob_act(var/power)
	if (!isdead(src))
		src.bruteloss += power
		health_update_queue |= src
		return 1
	return 0

/mob/living/silicon/hivebot/Stat()
	..()
	if(src.cell)
		stat("Charge Left:", "[src.cell.charge]/[src.cell.maxcharge]")
	else
		stat("No Cell Inserted!")

/mob/living/silicon/hivebot/restrained()
	return 0

/mob/living/silicon/hivebot/bullet_act(var/obj/projectile/P)
	..()
	log_shot(P,src) // Was missing (Convair880).

/mob/living/silicon/hivebot/ex_act(severity)
	..() // Logs.
	src.flash(3 SECONDS)

	if (isdead(src) && src.client)
		src.gib(1)
		return

	else if (isdead(src) && !src.client)
		qdel(src)
		return

	var/b_loss = src.bruteloss
	var/f_loss = src.fireloss
	switch(severity)
		if(1)
			if (!isdead(src))
				b_loss += 100
				f_loss += 100
				src.gib(1)
				return
		if(2)
			if (!isdead(src))
				b_loss += 60
				f_loss += 60
		if(3)
			if (!isdead(src))
				b_loss += 30
	src.bruteloss = b_loss
	src.fireloss = f_loss
	health_update_queue |= src

/mob/living/silicon/hivebot/meteorhit(obj/O as obj)
	for(var/mob/M in viewers(src, null))
		M.show_message(SPAN_ALERT("[src] has been hit by [O]"), 1)
		//Foreach goto(19)
	if (src.health > 0)
		src.bruteloss += 30
		if ((O.icon_state == "flaming"))
			src.fireloss += 40
		health_update_queue |= src
	return

/mob/living/silicon/hivebot/attackby(obj/item/W, mob/user)
	if (isweldingtool(W))
		if (src.get_brute_damage() < 1)
			boutput(user, SPAN_ALERT("[src] has no dents to repair."))
			return
		if(!W:try_weld(user, 1))
			return
		src.HealDamage("All", 30, 0)
		src.add_fingerprint(user)
		if (src.get_brute_damage() < 1)
			src.bruteloss = 0
			src.visible_message(SPAN_ALERT("<b>[user] fully repairs the dents on [src]!</b>"))
		else
			src.visible_message(SPAN_ALERT("[user] has fixed some of the dents on [src]."))
		health_update_queue |= src

	// Added ability to repair burn-damaged AI shells (Convair880).
	else if (istype(W, /obj/item/cable_coil))
		var/obj/item/cable_coil/coil = W
		src.add_fingerprint(user)
		if (src.get_burn_damage() < 1)
			user.show_text("There's no burn damage on [src.name]'s wiring to mend.", "red")
			return
		coil.use(1)
		src.HealDamage("All", 0, 30)
		if (src.get_burn_damage() < 1)
			src.fireloss = 0
			src.visible_message(SPAN_ALERT("<b>[user.name]</b> fully repairs the damage to [src.name]'s wiring."))
		else
			boutput(user, SPAN_ALERT("<b>[user.name]</b> repairs some of the damage to [src.name]'s wiring."))
		health_update_queue |= src

	else if (istype(W, /obj/item/clothing/suit/bee))
		boutput(user, "You stuff [src] into [W]! It fits surprisingly well.")
		src.beebot = 1
		src.UpdateIcon()
		qdel(W)
		return
	else
		return ..()

/mob/living/silicon/hivebot/attack_hand(mob/user)
	user.lastattacked = get_weakref(src)
	if(!user.stat)
		if (user.a_intent != INTENT_HELP)
			actions.interrupt(src, INTERRUPT_ATTACKED)
		switch(user.a_intent)
			if(INTENT_HELP) //Friend person
				playsound(src.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -2)
				user.visible_message(SPAN_NOTICE("[user] gives [src] a [pick_string("descriptors.txt", "borg_pat")] pat on the [pick("back", "head", "shoulder")]."))
			if(INTENT_DISARM) //Shove
				SPAWN(0) playsound(src.loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 40, 1)
				user.visible_message(SPAN_ALERT("<B>[user] shoves [src]! [prob(40) ? pick_string("descriptors.txt", "jerks") : null]</B>"))
			if(INTENT_GRAB) //Shake
				if(src.beebot == 1)
					var/obj/item/clothing/suit/bee/B = new /obj/item/clothing/suit/bee(src.loc)
					boutput(user, "You pull [B] off of [src]!")
					src.beebot = 0
					src.UpdateIcon()
				else
					playsound(src.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 30, 1, -2)
					user.visible_message(SPAN_ALERT("[user] shakes [src] [pick_string("descriptors.txt", "borg_shake")]!"))
			if(INTENT_HARM) //Dumbo
				if (user.is_hulk())
					src.TakeDamage("All", 5, 0)
					if (prob(40))
						var/turf/T = get_edge_target_turf(user, user.dir)
						if (isturf(T))
							src.visible_message(SPAN_ALERT("<B>[user] savagely punches [src], sending them flying!</B>"))
							src.throw_at(T, 10, 2)
				/*if (user.glove_weaponcheck())
					user.energyclaws_attack(src)*/
				else if (user.equipped_limb()?.can_beat_up_robots)
					user.equipped_limb().harm(src, user)
				else
					user.visible_message(SPAN_ALERT("<B>[user] punches [src]! What [pick_string("descriptors.txt", "borg_punch")]!"), SPAN_ALERT("<B>You punch [src]![prob(20) ? " Turns out they were made of metal!" : null] Ouch!</B>"))
					random_brute_damage(user, rand(2,5))
					playsound(src.loc, 'sound/impact_sounds/Metal_Clang_3.ogg', 60, 1)
					if(prob(10)) user.show_text("Your hand hurts...", "red")

		add_fingerprint(user)

/mob/living/silicon/hivebot/allowed(mob/M)
	//check if it doesn't require any access at all
	if(src.check_access(null))
		return 1
	return 0

/mob/living/silicon/hivebot/check_access(obj/item/I)
	if(!istype(src.req_access, /list)) //something's very wrong
		return 1

	var/obj/item/card/id/id_card = get_id_card(I)
	if (istype(id_card))
		I = id_card
	var/list/L = src.req_access
	if(!L.len) //no requirements
		return 1
	if(!I || !istype(I, /obj/item/card/id) || !I:access) //not ID or no access
		return 0
	for(var/req in src.req_access)
		if(!(req in I:access)) //doesn't have this access
			return 0
	return 1

/mob/living/silicon/hivebot/update_icon()
	if (isalive(src))
		if (src.beebot == 1)
			src.icon_state = "eyebot-bee[src.client ? null : "-logout"]"
		else
			src.icon_state = "[initial(icon_state)][src.client ? null : "-logout"]"
	else
		if (src.beebot == 1)
			src.icon_state = "eyebot-bee-dead"
		else
			src.icon_state = "[initial(icon_state)]-dead"

/mob/living/silicon/hivebot/proc/uneq_active()
	if (isnull(src.module_active))
		return
	if (isitem(src.module_active))
		var/obj/item/I = src.module_active
		I.dropped(src) // Handle light datums and the like.

	if(src.module_states[1] == src.module_active)
		if (src.client)
			src.client.screen -= module_states[1]
		src.contents -= module_states[1]
		src.module_active = null
		src.module_states[1] = null
	else if(src.module_states[2] == src.module_active)
		if (src.client)
			src.client.screen -= module_states[2]
		src.contents -= module_states[2]
		src.module_active = null
		src.module_states[2] = null
	else if(src.module_states[3] == src.module_active)
		if (src.client)
			src.client.screen -= module_states[3]
		src.contents -= module_states[3]
		src.module_active = null
		src.module_states[3] = null
	hud.update_tools()
	hud.update_tool_selector()
	hud.update_active_tool()

/mob/living/silicon/hivebot/swap_hand(var/switchto = 0)
	if (!module_states[1] && !module_states[2] && !module_states[3])
		module_active = null
		return

	var/active = src.module_states.Find(src.module_active)
	if (!switchto)
		switchto = (active % 3) + 1
	if (switchto == active)
		src.module_active = null
	// clicking the already on slot, so deselect basically
	else
		switch(switchto)
			if(1) src.module_active = src.module_states[1]
			if(2) src.module_active = src.module_states[2]
			if(3) src.module_active = src.module_states[3]
			else src.module_active = null
	hud.update_active_tool()

/mob/living/silicon/hivebot/click(atom/target, list/params)
	if ((target in src.module.tools) && !(target in src.module_states))
		for (var/i = 1; i <= 3; i++)
			if (!src.module_states[i])
				src.module_states[i] = target
				var/obj/item/I = target
				if(isitem(I))
					I.pickup(src) // attempted fix for no flashlight functionality - cirr
				hud.update_tool_selector()
				hud.update_tools()
				break
		return
	..()

/mob/living/silicon/hivebot/proc/activated(obj/item/O)
	if(src.module_states[1] == O)
		return 1
	else if(src.module_states[2] == O)
		return 1
	else if(src.module_states[3] == O)
		return 1
	else
		return 0

/mob/living/silicon/hivebot/proc/radio_menu()
	if(!src.radio)
		src.radio = new /obj/item/device/radio(src)
		src.ears = src.radio
	var/dat = {"
<TT>
Microphone: [src.radio.microphone_enabled ? "<A href='byond://?src=\ref[src.radio];talk=0'>Engaged</A>" : "<A href='byond://?src=\ref[src.radio];talk=1'>Disengaged</A>"]<BR>
Speaker: [src.radio.speaker_enabled ? "<A href='byond://?src=\ref[src.radio];listen=0'>Engaged</A>" : "<A href='byond://?src=\ref[src.radio];listen=1'>Disengaged</A>"]<BR>
Frequency:
<A href='byond://?src=\ref[src.radio];freq=-10'>-</A>
<A href='byond://?src=\ref[src.radio];freq=-2'>-</A>
[format_frequency(src.radio.frequency)]
<A href='byond://?src=\ref[src.radio];freq=2'>+</A>
<A href='byond://?src=\ref[src.radio];freq=10'>+</A><BR>
-------
</TT>"}
	src.Browse(dat, "window=radio")
	onclose(src, "radio")
	return

/mob/living/silicon/hivebot/verb/cmd_show_laws()
	set category = "Robot Commands"
	set name = "Show Laws"

	src.show_laws()
	return

/mob/living/silicon/hivebot/verb/open_nearest_door()
	set category = "Robot Commands"
	set name = "Open Nearest Door to..."
	set desc = "Automatically opens the nearest door to a selected individual, if possible."

	src.open_nearest_door_silicon()
	return

/mob/living/silicon/hivebot/verb/cmd_return_mainframe()
	set category = "Robot Commands"
	set name = "Recall to Mainframe"
	return_mainframe()

/mob/living/silicon/hivebot/return_mainframe()
	..()
	src.UpdateIcon()

/mob/living/silicon/hivebot
	clamp_values()
		..()
		sleeping = clamp(sleeping, 0, 1)
		bruteloss = max(bruteloss, 0)
		fireloss = max(fireloss, 0)
		if (src.stuttering)
			src.stuttering = 0

		src.lying = 0
		src.set_density(1)

		if (src.get_eye_blurry())
			src.change_eye_blurry(-1)

		if (src.druggy > 0)
			src.druggy--
			src.druggy = max(0, src.druggy)

	use_power()
		..()
		if (src.cell)
			if (src.cell.charge <= 0)
				//death() no why would it just explode upon running out of power that is absurd
				if (isalive(src))
					sleep(0)
					src.lastgasp()
				setunconscious(src)
			else if (src.cell.charge <= 10)
				src.module_active = null
				src.module_states[1] = null
				src.module_states[2] = null
				src.module_states[3] = null
				src.cell.use(1)
			else
				if (src.module_states[1])
					src.cell.use(1)
				if (src.module_states[2])
					src.cell.use(1)
				if (src.module_states[3])
					src.cell.use(1)
				src.cell.use(1)
				setalive(src)
		else
			if (isalive(src))
				sleep(0)
				src.lastgasp() // calling lastgasp() here because we just ran out of power
			setunconscious(src)

	proc/mainframe_check()
		if (mainframe)
			if (isdead(mainframe))
				mainframe.return_to(src)
		else
			gib(1)

/mob/living/silicon/hivebot/Login()
	..()

	update_clothing()
	UpdateIcon()

	if (src.mainframe)
		src.real_name = "SHELL/[src.mainframe.name]"
		src.bioHolder.mobAppearance.pronouns = src.client.preferences.AH.pronouns
		src.name = src.real_name
		src.update_name_tag()

	else if(src.real_name == "Cyborg")
		src.real_name += " "
		src.real_name += pick("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
		src.real_name += "-[pick(rand(1, 99))]"
		src.name = src.real_name
	return

/mob/living/silicon/hivebot/Logout()
	..()
	UpdateIcon()

	src.real_name = "AI Shell [copytext("\ref[src]", 6, 11)]"
	src.name = src.real_name
	src.update_name_tag()

	return

/mob/living/silicon/hivebot/find_in_hand(var/obj/item/I, var/this_hand)
	if (!I)
		return 0
	if (!src.module_states[3] && !src.module_states[2] && !src.module_states[1])
		return 0

	if (this_hand)
		if (this_hand == "right" || this_hand == 3)
			if (src.module_states[3] && src.module_states[3] == I)
				return 1
			else
				return 0
		else if (this_hand == "middle" || this_hand == 2)
			if (src.module_states[2] && src.module_states[2] == I)
				return 1
			else
				return 0
		else if (this_hand == "left" || this_hand == LEFT_HAND)
			if (src.module_states[1] && src.module_states[1] == I)
				return 1
			else
				return 0
		else
			return 0

	if (src.module_states[3] && src.module_states[3] == I)
		return src.module_states[3]
	else if (src.module_states[2] && src.module_states[2] == I)
		return src.module_states[2]
	else if (src.module_states[1] && src.module_states[1] == I)
		return src.module_states[1]
	else
		return 0

/mob/living/silicon/hivebot/find_type_in_hand(var/obj/item/I, var/this_hand)
	if (!I)
		return 0
	if (!src.module_states[3] && !src.module_states[2] && !src.module_states[1])
		return 0

	if (this_hand)
		if (this_hand == "right" || this_hand == 3)
			if (src.module_states[3] && istype(I, src.module_states[3]))
				return 1
			else
				return 0
		else if (this_hand == "middle" || this_hand == 2)
			if (src.module_states[2] && istype(I, src.module_states[2]))
				return 1
			else
				return 0
		else if (this_hand == "left" || this_hand == LEFT_HAND)
			if (src.module_states[1] && istype(I, src.module_states[1]))
				return 1
			else
				return 0
		else
			return 0

	if (src.module_states[3] && istype(I, src.module_states[3]))
		return src.module_states[3]
	else if (src.module_states[2] && istype(I, src.module_states[2]))
		return src.module_states[2]
	else if (src.module_states[1] && istype(I, src.module_states[1]))
		return src.module_states[1]
	else
		return 0

/mob/living/silicon/hivebot/find_tool_in_hand(var/tool_flag, var/hand)
	if (hand)
		if (hand == "right" || hand == 3)
			var/obj/item/I = src.module_states[3]
			if (I && (I.tool_flags & tool_flag))
				return src.module_states[3]
		if (hand == "middle" || hand == 2)
			var/obj/item/I = src.module_states[2]
			if (I && (I.tool_flags & tool_flag))
				return src.module_states[2]
		if (hand == "left" || hand == LEFT_HAND)
			var/obj/item/I = src.module_states[1]
			if (I && (I.tool_flags & tool_flag))
				return src.module_states[1]
	else
		for(var/i = 1 to 3)
			var/obj/item/I = src.module_states[i]
			if (I && (I.tool_flags & tool_flag))
				return src.module_states[i]
	return 0

/mob/living/silicon/hivebot/set_a_intent(intent)
	. = ..()
	src.hud?.update_intent()

/mob/living/silicon/hivebot/set_pulling(atom/movable/A)
	. = ..()
	src.hud?.update_pulling()

/*-----Actual AI Shells---------------------------------------*/

/mob/living/silicon/hivebot/eyebot
	name = "Eyebot"
	icon_state = "eyebot"
	health = 25
	do_hurt_slowdown = FALSE
	jetpack = 1 //ZeWaka: I concur with ghostdrone commenter, fuck whoever made this. See spacemove.

	New()
		..()
		hud = new(src)
		src.attach_hud(hud)
		if(!bioHolder)
			bioHolder = new/datum/bioHolder( src )
		SPAWN(0.5 SECONDS)
			if (QDELETED(src)) //bleh
				return
			if (src.module)
				qdel(src.module)
			if (ticker?.mode && istype(ticker.mode, /datum/game_mode/construction))
				src.module = new /obj/item/robot_module/construction_ai( src )
			else
				src.module = new /obj/item/robot_module/eyebot( src )
			hud.update_tool_selector()

			//ew
			if (!(src in available_ai_shells))
				available_ai_shells += src

	movement_delay()
		if (src.pulling && !isitem(src.pulling))
			return ..()
		return 1 + movement_delay_modifier

	hotkey(name)
		switch (name)
			if ("unequip")
				src.uneq_active()
			if ("swaphand")
				src.swap_hand()
			if ("module1")
				src.swap_hand(1)
			if ("module2")
				src.swap_hand(2)
			if ("module3")
				src.swap_hand(3)
			if ("module4")
				src.swap_hand(4)
			if ("attackself")
				var/obj/item/W = src.equipped()
				if (W)
					src.click(W, list())
			else
				return ..()

	build_keybind_styles(client/C)
		..()
		C.apply_keybind("robot")

		if (!C.preferences.use_wasd)
			C.apply_keybind("robot_arrow")

		if (C.preferences.use_azerty)
			C.apply_keybind("robot_azerty")
		if (C.tg_controls)
			C.apply_keybind("robot_tg")

	create_offline_indicator()
		return

	update_icon() // Haine wandered in here and just junked up this code with bees.  I'm so sorry it's so ugly aaaa
		if(isalive(src))
			if(src.client)
				if(pixel_y)
					if (src.beebot == 1)
						src.icon_state = "eyebot-bee"
					else
						src.icon_state = "[initial(icon_state)]"
				else
					SPAWN(0)
						while(src.pixel_y < 10)
							src.pixel_y++
							sleep(0.1 SECONDS)
						if (src.beebot == 1)
							src.icon_state = "eyebot-bee"
						else
							src.icon_state = "[initial(icon_state)]"
					return
			else
				if (src.beebot == 1)
					src.icon_state = "eyebot-bee-logout"
				else
					src.icon_state = "[initial(icon_state)]-logout"
				src.pixel_y = 0
		else
			if (src.beebot == 1)
				src.icon_state = "eyebot-bee-dead"
			else
				src.icon_state = "[initial(icon_state)]-dead"
			src.pixel_y = 0
		return

	show_laws()
		var/mob/living/silicon/ai/aiMainframe = src.mainframe
		if (istype(aiMainframe))
			aiMainframe.show_laws(0, src)
		else
			boutput(src, SPAN_ALERT("You lack a dedicated mainframe! This is a bug, report to an admin!"))

		return

	ghostize()
		if(src.mainframe)
			src.mainframe.return_to(src)
		else
			return ..()

	disposing()
		available_ai_shells -= src
		..()



/*-----Shell-Creation---------------------------------------*/

/obj/item/ai_interface
	name = "\improper AI interface board"
	desc = "A board that allows AIs to interface with the robot it's installed in. It features a little blinking LED, but who knows what the LED is trying to tell you? Does it even mean anything? Why is it blinking? WHY?? WHAT DOES IT MEAN?! ??????"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "ai-interface"
	item_state = "ai-interface"
	w_class = W_CLASS_SMALL

//obj/item/cell/shell_cell moved to cells.dm

/obj/item/shell_frame
	name = "\improper AI shell frame"
	desc = "An empty frame for an AI shell."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "shell-frame"
	item_state = "shell-frame"
	w_class = W_CLASS_SMALL
	var/build_step = 0
	var/obj/item/cell/cell = null
	var/has_radio = 0
	var/has_interface = 0

	Exited(Obj, newloc)
		. = ..()
		if(Obj == src.cell)
			src.cell = null

/obj/item/shell_frame/attackby(obj/item/W, mob/user)
	if (istype(W, /obj/item/sheet))
		if (src.build_step < 1)
			var/obj/item/sheet/M = W
			if (M.change_stack_amount(-1))
				src.build_step++
				boutput(user, "You add the plating to [src]!")
				playsound(src, 'sound/impact_sounds/Generic_Stab_1.ogg', 40, TRUE)
				src.icon_state = "shell-plate"
				return
			else
				boutput(user, "You need at least one metal sheet to add plating! How are you even seeing this message?! How do you have a metal sheet that has no metal sheets in it?!?!")
				user.drop_item()
				qdel(W) // no bizarro nega-sheets for you :v
				return
		else
			boutput(user, "\The [src] already has plating!")
			return

	else if (istype(W, /obj/item/cable_coil))
		if (src.build_step == 1)
			var/obj/item/cable_coil/coil = W
			if (coil.amount >= 3)
				src.build_step++
				boutput(user, "You add \the cable to [src]!")
				playsound(src, 'sound/impact_sounds/Generic_Stab_1.ogg', 40, TRUE)
				coil.amount -= 3
				src.icon_state = "shell-cable"
				if (coil.amount < 1)
					user.drop_item()
					qdel(coil)
				return
			else
				boutput(user, "You need at least three lengths of cable to install it in [src].")
				return
		else if (src.build_step > 1)
			boutput(user, "\The [src] already has wiring!")
			return

	else if (istype(W, /obj/item/cell))
		if (src.build_step >= 2)
			if (!src.cell)
				src.build_step++
				boutput(user, "You add \the [W] to [src]!")
				playsound(src, 'sound/impact_sounds/Generic_Stab_1.ogg', 40, TRUE)
				src.cell = W
				user.u_equip(W)
				W.set_loc(src)
				return
			else
				boutput(user, "\The [src] already has a cell!")
				return
		else
			boutput(user, "\The [src] needs[src.build_step ? "" : " metal plating and"] wiring installed before you can add the cell.")
			return

	else if (istype(W, /obj/item/device/radio))
		if (src.build_step >= 2)
			if (!src.has_radio)
				src.build_step++
				boutput(user, "You add \the [W] to [src]!")
				playsound(src, 'sound/impact_sounds/Generic_Stab_1.ogg', 40, TRUE)
				src.icon_state = "shell-radio"
				src.has_radio = 1
				qdel(W)
				return
			else
				boutput(user, "\The [src] already has a radio!")
				return
		else
			boutput(user, "\The [src] needs[src.build_step ? "" : " metal plating and"] wiring installed before you can add the radio.")
			return

	else if (istype(W, /obj/item/ai_interface))
		if (src.build_step >= 2)
			if (!src.has_interface)
				src.build_step++
				boutput(user, "You add the [W] to [src]!")
				playsound(src, 'sound/impact_sounds/Generic_Stab_1.ogg', 40, TRUE)
				src.has_interface = 1
				qdel(W)
				return
			else
				boutput(user, "\The [src] already has an AI interface!")
				return
		else
			boutput(user, "\The [src] needs[src.build_step ? "" : " metal plating and"] wiring installed before you can add the AI interface.")
			return

	else if (iswrenchingtool(W))
		if (src.build_step >= 5)
			src.build_step++
			boutput(user, "You activate the shell!  Beep bop!")
			var/mob/living/silicon/hivebot/eyebot/S = new /mob/living/silicon/hivebot/eyebot(get_turf(src))
			S.cell = src.cell
			src.cell.set_loc(S)
			src.cell = null
			qdel(src)
			return
		else
			var/list/still_needed = list()
			if (src.build_step < 1)
				still_needed += "metal plating"
			if (src.build_step < 2)
				still_needed += "wiring"
			if (!src.cell)
				still_needed += "a power cell"
			if (!src.has_radio)
				still_needed += "a station bounced radio"
			if (!src.has_interface)
				still_needed += "an AI interface board"
			boutput(user, "\The [src] needs [still_needed.len ? english_list(still_needed) : "bugfixing (please call a coder)"] before you can activate it.")
			return


/datum/statusEffect/low_signal
	id = "low_signal"
	name = "Low Signal"
	desc = "You have reduced signal to your shell."
	icon_state = "low_signal"
	unique = TRUE
	effect_quality = STATUS_QUALITY_NEGATIVE

	onAdd(optional)
		. = ..()
		if (!ismob(owner)) return
		var/mob/M = owner
		M.addOverlayComposition(/datum/overlayComposition/low_signal)

	onUpdate(timePassed)
		. = ..()
		if (ishivebot(owner))
			var/mob/living/silicon/hivebot/H = owner
			if(H.module_active || H.module_states[1] || H.module_states[2] || H.module_states[3])
				H.module_active = null
				H.module_states[1] = null
				H.module_states[2] = null
				H.module_states[3] = null
				H.hud.update_tools()
				H.hud.update_tool_selector()
				H.hud.update_active_tool()
				H.show_text("Insufficient signal to maintain control of tools.")

	onRemove()
		. = ..()
		if (QDELETED(owner) || !ismob(owner)) return
		var/mob/M = owner
		M.removeOverlayComposition(/datum/overlayComposition/low_signal)

/datum/lifeprocess/hivebot_signal
	process(var/datum/gas_mixture/environment)
		if(hivebot_owner?.mainframe)
			if((get_step(hivebot_owner.mainframe, 0)?.z == get_step(hivebot_owner, 0)?.z) || (inunrestrictedz(hivebot_owner) && inonstationz(hivebot_owner.mainframe)))
				hivebot_owner.delStatus("low_signal")
			else
				hivebot_owner.setStatus("low_signal", INFINITE_STATUS)
		..()


/// Cargo cult from Pod Wars for now.
/obj/nations_control_point_computer
	name = "computer"
	icon = 'icons/obj/control_point_computer.dmi'
	icon_state = "control_point_computer"
	density = 1
	anchored = ANCHORED

	var/image/screen
	var/image/screen_light
	var/image/name_overlay

	var/datum/light/light
	var/light_r =1
	var/light_g = 1
	var/light_b = 1

/obj/nations_control_point_computer/New()
	..()
	light = new/datum/light/point
	light.set_brightness(0.8)
	light.set_color(light_r, light_g, light_b)
	light.attach(src)

	src.update_screen("screen")

	if (src.dir == NORTH || src.dir == SOUTH)
		src.bound_width = 64
		src.bound_height = 32
	else if (src.dir == EAST || src.dir == WEST)
		src.bound_width = 32
		src.bound_height = 64

/obj/nations_control_point_computer/proc/update_screen(var/icon_state)
	src.screen = image('icons/obj/control_point_computer.dmi', icon_state)
	src.UpdateOverlays(src.screen, "screen")

	src.screen_light = image('icons/obj/control_point_computer.dmi', icon_state)
	src.screen_light.plane = PLANE_LIGHTING
	src.screen_light.blend_mode = BLEND_ADD
	src.screen_light.layer = LIGHTING_LAYER_BASE
	src.screen_light.color = list(0.33,0.33,0.33, 0.33,0.33,0.33, 0.33,0.33,0.33)
	src.UpdateOverlays(src.screen_light, "screen_light")

/obj/nations_control_point_computer/proc/update_name_overlay(var/icon_state)
	src.name_overlay = image('icons/obj/control_point_computer.dmi', icon_state)
	src.UpdateOverlays(src.name_overlay, "name_overlay")

/obj/nations_control_point_computer/ex_act()
	return

/obj/nations_control_point_computer/meteorhit(obj/O as obj)
	return

/*
//called from the action bar completion in src.Attackhand()
/obj/nations_control_point_computer/proc/capture(var/mob/user)
	var/team_num = get_pod_wars_team_num(user)
	owner_team = team_num
	update_light_color()

	ctrl_pt.capture(user, team_num)
	switch(get_pod_wars_team_num(user))
		if (TEAM_NANOTRASEN)
			message_ghosts("<b>[user]</b> successfully captured [src] for Nanotrasen! [log_loc(src, ghostjump=TRUE)].")
		if (TEAM_SYNDICATE)
			message_ghosts("<b>[user]</b> successfully captured [src] for the Syndicate! [log_loc(src, ghostjump=TRUE)].")

/obj/nations_control_point_computer/proc/attack_hand(mob/user)
	if (!can_be_captured)
		var/cur_time
		var/datum/game_mode/pod_wars/mode = ticker.mode
		if (istype(mode))
			cur_time = round((mode.activate_control_points_time-ticker.round_elapsed_ticks) / (1 MINUTES), 1)	//converts to minutes
		else
			cur_time = round( 15 MINUTES / 1 MINUTES, 1)


		boutput(user, SPAN_NOTICE("This computer seems to be frozen on a space-weather tracking screen. It looks like a large ion storm will be passing this system in about <b class='alert'>[(cur_time)] minutes mission time</b>.<br>You can't input any commands to run the control protocols for this satelite..."))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE, flags = SOUND_IGNORE_SPACE)
		return 0
	if (owner_team != get_pod_wars_team_num(user))
		var/duration = is_commander(user) ? 10 SECONDS : 20 SECONDS
		playsound(get_turf(src), 'sound/machines/warning-buzzer.ogg', 150, 1, flags = SOUND_IGNORE_SPACE)	//loud

		if(!ON_COOLDOWN(src, "ghostalert", 10 SECONDS))
			message_ghosts("<b>[user]</b> is trying to capture <b>[src]</b>! [log_loc(src, ghostjump=TRUE)].")
		SETUP_GENERIC_ACTIONBAR(user, src, duration, /obj/control_point_computer/proc/capture, list(user),\
			null, null, "[user] successfully enters [his_or_her(user)] command code into \the [src]!", null)
	else
		boutput(user, SPAN_ALERT("You can't think of anything else to do on this console..."))

/obj/nations_control_point_computer/proc/is_commander(var/mob/user)
	if (istype(ticker.mode, /datum/game_mode/pod_wars))
		var/datum/game_mode/pod_wars/mode = ticker.mode
		if (user.mind == mode.team_NT.commander)
			return 1
		else if (user.mind == mode.team_SY.commander)
			return 1
	return 0

//change colour and owner team when captured.
//this doesn't work right now. idc -kyle
/obj/nations_control_point_computer/proc/update_light_color()
	//blue for NT|1, red for SY|2, white for neutral|0.
	if (owner_team == TEAM_NANOTRASEN)
		light_r = 0
		light_g = 0
		light_b = 1
		src.update_screen("nanotrasen")
	else if (owner_team == TEAM_SYNDICATE)
		light_r = 1
		light_g = 0
		light_b = 0
		src.update_screen("syndicate")
	else
		light_r = 1
		light_g = 1
		light_b = 1
		src.update_screen("screen")

	light.set_color(light_r, light_g, light_b)
*/

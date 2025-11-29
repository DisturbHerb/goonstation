/atom/movable/screen/hud/pod/indicator
	name = "Indicator"
	desc = "Displays useful information."
	icon_state = "screen-off"
	tooltip_options = list("theme" = "pod")
	base_name = "Indicator"
	base_icon_state = "screen"
	mouse_over_pointer = MOUSE_INACTIVE_POINTER

/atom/movable/screen/hud/pod/indicator/on_click()
	return

/atom/movable/screen/hud/pod/indicator/update_state()
	. = ..()
	if (!.)
		return
	var/obj/item/shipcomponent/sensor/master_sensor = src.pod_hud.master.get_part(POD_PART_SENSORS)
	if (length(master_sensor?.whos_tracking_me))
		src.name = "Master Caution"
		src.desc = "You're being tracked by another vehicle's sensors!"
		return
	var/obj/item/shipcomponent/secondary_system/master_secondary = src.pod_hud.master.get_part(POD_PART_SECONDARY)
	if (!master_secondary)
		return
	src.name = master_secondary.name
	src.desc = "This vehicle has [master_secondary.name] attached as its secondary system."

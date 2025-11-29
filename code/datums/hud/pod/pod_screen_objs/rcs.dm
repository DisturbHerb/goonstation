/atom/movable/screen/hud/pod/rcs
	name = "Toggle RCS"
	desc = "Reduce the pod's relative velocity."
	icon_state = "system-off"
	base_icon_state = "Toggle RCS"
	base_icon_state = "system"
	tooltip_options = list("theme" = "pod-alt")

/atom/movable/screen/hud/pod/rcs/on_click(mob/user)
	src.pod_hud.master.rcs = !src.pod_hud.master.rcs
	src.pod_hud.switch_sound()
	return TRUE

/atom/movable/screen/hud/pod/rcs/update_state()
	if (src.pod_hud.master.rcs)
		src.icon_state = "system-on"
	else
		src.icon_state = "system-off"

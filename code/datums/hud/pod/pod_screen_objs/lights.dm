/atom/movable/screen/hud/pod/lights
	name = "Toggle Lights"
	desc = "Turn the pod's external lights on or off."
	icon_state = "system-off"
	tooltip_options = list("theme" = "pod")
	base_name = "Lights"
	base_icon_state = "system"
	pod_part_id = POD_PART_LIGHTS

/atom/movable/screen/hud/pod/lights/update_state()
	var/obj/item/shipcomponent/pod_lights/pod_lights = src.pod_hud.master.get_part(POD_PART_LIGHTS)
	var/obj/item/shipcomponent/engine/engine = src.pod_hud.master.get_part(POD_PART_ENGINE)
	if (!pod_lights || !engine?.active)
		src.icon_state = "system-off"
		src.ClearSpecificOverlays(FALSE, "text_overlay")
		return
	src.icon_state = "system-on"
	src.draw_text(list("lights", "[pod_lights.active ? "on" : "off"]"))

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
		src.UpdateOverlays(image(src.icon, "system_switch-off"), "switch")
		src.ClearSpecificOverlays(FALSE, "text-lights", "text-status")
		return
	src.icon_state = "system-on"
	if (!src.GetOverlayImage("lights"))
		src.draw_text("lights")
	src.draw_text("[pod_lights.active ? "on" : "off"]", "status")
	src.UpdateOverlays(image(src.icon, "system_switch-[pod_lights.active? "on" : "off"]"), "switch")

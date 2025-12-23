/atom/movable/screen/hud/pod
	icon = 'icons/mob/hud_pod/hud_pod.dmi'
	show_tooltip = TRUE
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/active = FALSE
	var/base_name = ""
	var/base_icon_state = ""
	var/datum/hud/pod/pod_hud = null
	var/pod_part_id = null
	var/list/dependent_parts = null

/atom/movable/screen/hud/pod/New(loc, datum/hud/pod/pod_hud)
	src.master = pod_hud
	src.pod_hud = pod_hud
	. = ..()

/atom/movable/screen/hud/pod/clicked(list/params)
	var/mob/user = usr
	if (!istype(src.pod_hud) || !istype(user))
		return

	if (user.loc != src.pod_hud.master)
		boutput(user, SPAN_ALERT("You're not in the pod doofus. (Call 1-800-CODER.)"))
		src.pod_hud.remove_client(user.client)
		return

	if (!can_act(user))
		boutput(user, SPAN_ALERT("Not when you are incapacitated or restrained."))
		return

	src.on_click(user)
	src.pod_hud.update_states()

/atom/movable/screen/hud/pod/proc/on_click(mob/user)
	var/obj/item/shipcomponent/pod_part = src.pod_hud.master.get_part(src.pod_part_id)
	if (!istype(pod_part))
		return FALSE

	pod_part.toggle()
	src.pod_hud.switch_sound()
	return TRUE

/atom/movable/screen/hud/pod/proc/update_state()
	if (!src.base_icon_state)
		return
	src.active = src.is_active()
	if (src.active)
		src.icon_state = "[src.base_icon_state]-on"
	else
		src.icon_state = "[src.base_icon_state]-off"

/atom/movable/screen/hud/pod/proc/update_system()
	if (!src.base_name)
		return
	var/obj/item/shipcomponent/pod_part = src.pod_hud.master.get_part(src.pod_part_id)
	if (istype(pod_part))
		src.name = pod_part.name
	else
		src.name = src.base_name
	src.active = src.is_active()

// Are our pod part and our dependent parts all active?
/atom/movable/screen/hud/pod/proc/is_active()
	. = FALSE
	var/list/parts_buffer = list()
	if (length(src.dependent_parts))
		parts_buffer += src.dependent_parts
	if (!(src.pod_part_id in parts_buffer))
		parts_buffer += src.pod_part_id
	if (!length(parts_buffer))
		return
	for (var/part_id in parts_buffer)
		var/obj/item/shipcomponent/pod_part = src.pod_hud.master.get_part(part_id)
		if (!istype(pod_part))
			continue
		if (pod_part?.active)
			. = TRUE
			continue
		. = FALSE
		break

/atom/movable/screen/hud/pod/proc/draw_text(text_icon_state, name)
	if (!istext(text_icon_state))
		return
	var/image/drawn_text = image(src.icon, icon_state = text_icon_state)
	var/mutable_appearance/drawn_text_ma = new(drawn_text)
	var/image/drawn_text_alpha_mask = image('icons/mob/hud_pod/hud_pod-text_overlays.dmi', text_icon_state)
	drawn_text_ma.color = src.pod_hud.hud_color
	drawn_text_ma.filters["scan_effect"] = filter(type = "displace", icon = icon('icons/mob/hud_pod/hud_pod-text_overlays.dmi', "crt-displacement"), size = 1)
	drawn_text_ma.filters["scan_lines"] = filter(type = "layer", icon = icon('icons/mob/hud_common.dmi', "scan"), blend_mode = BLEND_MULTIPLY)
	drawn_text_ma.filters["alpha"] = filter(type = "alpha", icon = drawn_text_alpha_mask)
	drawn_text.appearance = drawn_text_ma
	src.UpdateOverlays(drawn_text, "text-[name ? name : text_icon_state]")

/atom/movable/screen/hud/pod/read_only
	mouse_over_pointer = MOUSE_INACTIVE_POINTER
	mouse_opacity = FALSE
	show_tooltip = FALSE

/atom/movable/screen/hud/pod/read_only/on_click()
	return

/atom/movable/screen/hud/pod/read_only/update_state()
	return

/atom/movable/screen/hud/pod/read_only/update_system()
	return

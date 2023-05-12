proc/set_snow_storm_intensity(opacity, speed, angle)
	for (var/client/client in clients)
		var/list/parallax_layers = client.parallax_controller?.z_level_parallax_layers?["[Z_LEVEL_STATION]"]
		for (var/atom/movable/screen/parallax_layer/foreground/snow/layer as anything in parallax_layers)
			if (!istype(layer, /atom/movable/screen/parallax_layer/foreground/snow))
				continue
			layer.set_intensity(opacity, speed, angle)


/atom/movable/screen/parallax_layer/foreground
	plane = PLANE_FOREGROUND_PARALLAX

// Storm Storm Layers
/atom/movable/screen/parallax_layer/foreground/snow
	parallax_icon = 'herb_modular/icons/misc/parallax.dmi'
	parallax_icon_state = "snow_dense"
	color = list(
		1, 0, 0, 0.4,
		0, 1, 0, 0.4,
		0, 0, 1, 0.4,
		0, 0, 0, 1,
		0, 0, 0, -1)
	static_colour = TRUE
	parallax_value = 0.8
	scroll_speed = 100
	scroll_angle = 240

	proc/set_intensity(opacity, speed, angle)
		if (!isnull(opacity))
			src.color = list(
				1, 0, 0, opacity,
				0, 1, 0, opacity,
				0, 0, 1, opacity,
				0, 0, 0, 1,
				0, 0, 0, -1)

			// Any "opacity" value above 0.5 results in noticable bands of high opacity forming on the parallax layers.
			// As the "opacity" approaches 1, the alpha of the layer should be reduced as prevent the layer from appearing entirely opaque.
			src.alpha = 255 * (1.65 ** (0.5 - opacity))

		if (!isnull(speed))
			src.scroll_speed = speed

		if (!isnull(angle))
			src.scroll_angle = angle

		animate(src)
		src.offset_layer()
		src.scroll_layer()
		src.update_tessellation_alignment()

/atom/movable/screen/parallax_layer/foreground/snow/sparse
	parallax_icon_state = "snow_sparse"
	color = null
	blend_mode = BLEND_ADD
	parallax_value = 0.9
	scroll_speed = 150

	set_intensity(opacity, speed, angle)
		opacity = null
		. = ..()


client
	New()
		add_plane(new /atom/movable/screen/plane_parent(PLANE_FOREGROUND_PARALLAX, appearance_flags = TILE_BOUND, mouse_opacity = 0, name = "foreground_parallax_plane", is_screen = 1))
		add_plane(new /atom/movable/screen/plane_parent(PLANE_FOREGROUND_PARALLAX_OCCLUSION, appearance_flags = TILE_BOUND, mouse_opacity = 0, name = "foreground_parallax_occlusion_plane", is_screen = 1))

		var/atom/movable/screen/plane_parent/occlusion_plane = src.get_plane(PLANE_FOREGROUND_PARALLAX_OCCLUSION)
		occlusion_plane.render_target = "*\ref[occlusion_plane]"
		var/atom/movable/screen/plane_parent/parallax_plane = src.get_plane(PLANE_FOREGROUND_PARALLAX)
		parallax_plane.add_filter("occlusion_plane", 1, alpha_mask_filter(render_source = "*\ref[occlusion_plane]", flags = MASK_INVERSE))

		. = ..()

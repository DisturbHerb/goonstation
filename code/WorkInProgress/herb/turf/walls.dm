// I am part of the copy-paste spaghetti problem.

TYPEINFO(/turf/simulated/wall/auto/herb)
	connect_overlay = 1
	connect_diagonal = 1
TYPEINFO_NEW(/turf/simulated/wall/auto/herb)
	. = ..()
	connects_to = typecacheof(list(
		/turf/simulated/wall/auto/herb, /turf/simulated/wall/auto/reinforced/herb,
		/turf/simulated/wall/auto/supernorn, /turf/simulated/wall/auto/reinforced/supernorn,
		/turf/simulated/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
		/turf/simulated/wall/auto/jen, /turf/simulated/wall/auto/reinforced/jen,
		/turf/simulated/wall/auto/old, /turf/simulated/wall/auto/reinforced/old
	))
	connects_with_overlay = typecacheof(list(
		/turf/simulated/wall/auto/shuttle,
		/turf/simulated/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
		/turf/simulated/wall/auto/jen, /turf/simulated/wall/auto/reinforced/jen
	))

/turf/simulated/wall/auto/herb
	icon = 'icons/herb/turf/wall.dmi'
#ifdef IN_MAP_EDITOR
	icon_state = "wall-0"
#endif
	mod = "wall-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.UpdateIcon()

TYPEINFO(/turf/simulated/wall/auto/reinforced/herb)
	connect_overlay = 1
	connect_diagonal = 1

TYPEINFO_NEW(/turf/simulated/wall/auto/reinforced/herb)
	. = ..()
	connects_to = typecacheof(list(
		/turf/simulated/wall/auto/herb, /turf/simulated/wall/auto/reinforced/herb,
		/turf/simulated/wall/auto/jen, /turf/simulated/wall/auto/reinforced/jen,
		/turf/simulated/wall/false_wall, /turf/simulated/wall/auto/shuttle, /obj/machinery/door,
		/obj/window, /obj/wingrille_spawn, /turf/simulated/wall/auto/reinforced/supernorn/yellow,
		/turf/simulated/wall/auto/reinforced/supernorn/blackred, /turf/simulated/wall/auto/reinforced/supernorn/orange,
		/turf/simulated/wall/auto/old, /turf/simulated/wall/auto/reinforced/old
	))
	connects_with_overlay = typecacheof(list(
		/turf/simulated/wall/auto/jen, /turf/simulated/wall/auto/reinforced/jen,
		/turf/simulated/wall/auto/shuttle, /obj/machinery/door, /obj/window,
		/obj/wingrille_spawn, /turf/simulated/wall/auto/reinforced/paper
	))

/turf/simulated/wall/auto/reinforced/herb
	icon = 'icons/herb/turf/rwall.dmi'
#ifdef IN_MAP_EDITOR
	icon_state = "rwall-0"
#endif
	mod = "rwall-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.UpdateIcon()

// yes a lot of this is blatantly stolen sleeper code but FLAVOUR, my boy
/obj/machinery/stasis_pod
	name = "stasis pod"
	icon = 'herb_modular/icons/obj/machinery/stasis.dmi'
	icon_state = "stasis_pod"
	desc = {"A device that can preseve its occupants in cryo-stasis for an extended period of time on long space journeys. Doubles as a casket if the
			occupant does not wake up."}
	density = 1
	anchored = ANCHORED
	deconstruct_flags = DECON_CROWBAR | DECON_WIRECUTTERS | DECON_MULTITOOL

	var/mob/occupant = null
	var/image/image_lid = null

	New()
		..()
		src.UpdateIcon()

	disposing()
		if(occupant)
			MOVE_OUT_TO_TURF_SAFE(src.occupant, src)
			occupant = null
		..()

	update_icon()
		ENSURE_IMAGE(src.image_lid, src.icon, "stasis_lid[!isnull(occupant)]")
		src.UpdateOverlays(src.image_lid, "lid")

	ex_act(severity)
		switch (severity)
			if (1)
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(src.loc)
					A.ex_act(severity)
				qdel(src)
			if (2)
				if (prob(50))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(src.loc)
						A.ex_act(severity)
					qdel(src)
			if (3)
				if (prob(25))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(src.loc)
						A.ex_act(severity)
					qdel(src)

	blob_act(var/power)
		if (prob(power * 3.75))
			for (var/atom/movable/A as mob|obj in src)
				A.set_loc(src.loc)
				A.blob_act(power)
			qdel(src)
		return

	allow_drop()
		return FALSE

	attackby(obj/item/grab/G, mob/user)
		src.add_fingerprint(user)

		if (!istype(G) || !ishuman(G.affecting))
			..()
			return
		if (src.occupant)
			user.show_text("[src] is already occupied!", "red")
			return

		var/mob/living/carbon/human/H = G.affecting
		H.set_loc(src)
		src.occupant = H
		src.UpdateIcon()
		qdel(G)
		playsound(src.loc, 'sound/machines/sleeper_close.ogg', 30, 1)
		return

	powered()
		return

	use_power()
		return

	power_change()
		return


	proc/go_out()
		if (!src || !src.occupant)
			return
		MOVE_OUT_TO_TURF_SAFE(src.occupant, src)

	was_deconstructed_to_frame(mob/user)
		src.go_out()

	Exited(Obj, newloc)
		. = ..()
		if(Obj == src.occupant)
			for (var/obj/O in src)
				O.set_loc(src.loc)
				src.add_fingerprint(usr)
			src.occupant.changeStatus("weakened", 1 SECOND)
			src.occupant.force_laydown_standup()
			src.occupant = null
			src.UpdateIcon()
			playsound(src.loc, 'sound/machines/sleeper_open.ogg', 50, 1)

	relaymove(mob/user as mob, dir)
		eject_occupant(user)

	MouseDrop_T(mob/living/target, mob/user)
		if (!istype(target) || isAI(user))
			return

		if (BOUNDS_DIST(src, user) > 0 || BOUNDS_DIST(user, target) > 0)
			return

		if (target == user)
			move_inside()
		else if (can_operate(user))
			var/previous_user_intent = user.a_intent
			user.set_a_intent(INTENT_GRAB)
			user.drop_item()
			target.Attackhand(user)
			user.set_a_intent(previous_user_intent)
			SPAWN(user.combat_click_delay + 2)
				if (can_operate(user))
					if (istype(user.equipped(), /obj/item/grab))
						src.Attackby(user.equipped(), user)

	proc/can_operate(var/mob/M)
		if (!(BOUNDS_DIST(src, M) == 0))
			return FALSE
		if (istype(M) && is_incapacitated(M))
			return FALSE
		if (src.occupant)
			boutput(M, "<span class='notice'><B>The scanner is already occupied!</B></span>")
			return FALSE
		if (!ishuman(M))
			boutput(usr, "<span class='alert'>You can't seem to fit into \the [src].</span>")
			return FALSE
		if (src.occupant)
			usr.show_text("The [src.name] is already occupied!", "red")
			return FALSE

		. = TRUE

	verb/move_inside()
		set src in oview(1)
		set category = "Local"

		if (!src) return

		if (!can_operate(usr)) return

		usr.remove_pulling()
		usr.set_loc(src)
		src.occupant = usr
		src.UpdateIcon()
		for (var/obj/O in src)
			O.set_loc(src.loc)
		playsound(src.loc, 'sound/machines/sleeper_close.ogg', 50, 1)

	attack_hand(mob/user)
		..()
		eject_occupant(user)

	mouse_drop(mob/user as mob)
		if (can_operate(user))
			eject_occupant(user)
		else
			..()

	verb/eject()
		set src in oview(1)
		set category = "Local"

		eject_occupant(usr)

	verb/eject_occupant(var/mob/user)
		if (!isalive(user) || iswraith(user) || isintangible(user)) return
		src.go_out()
		add_fingerprint(user)

// clothing booth stuffs <3
/obj/machinery/clothingbooth
	name = "Clothing Booth"
	desc = "Contains a sophisticated autoloom system capable of manufacturing a variety of clothing items on demand."
	icon = 'icons/obj/vending.dmi'
	icon_state = "clothingbooth-open"
	flags = FPRINT | TGUI_INTERACTIVE
	anchored = ANCHORED
	density = 1
	var/datum/light/ambient_light

	// Preview and purchase-related.
	var/datum/clothingbooth_item/item_to_purchase = null
	var/datum/movable_preview/character/multiclient/preview
	var/mob/living/carbon/human/occupant
	var/obj/item/preview_item = null
	var/preview_direction_default = SOUTH
	/// This is set to `src.preview_direction_default` on New() and whenever a new occupant is added. This can be rotated in the UI.
	var/current_preview_direction

	/// Amount of inserted cash; presently, only cash is accepted.
	var/money = 0
	/// `src` can only be entered if `src.open` is TRUE.
	var/open = TRUE

	New()
		..()
		UnsubscribeProcess()
		src.ambient_light = new /datum/light/point
		src.ambient_light.attach(src)
		src.ambient_light.set_brightness(0.6)
		src.ambient_light.set_height(1.5)
		src.ambient_light.enable()
		src.preview = new()
		src.preview.add_background()
		src.current_preview_direction = src.preview_direction_default

	attackby(obj/item/W, mob/user)
		if(istype(W, /obj/item/currency/spacecash))
			if(!(locate(/mob) in src))
				src.money += W.amount
				W.amount = 0
				user.visible_message("<span class='notice'>[user.name] inserts credits into [src]")
				playsound(user, 'sound/machines/capsulebuy.ogg', 80, TRUE)
				user.u_equip(W)
				W.dropped(user)
				qdel(W)
			else
				boutput(user,"<span style=\"color:red\">It seems the clothing booth is currently occupied. Maybe it's better to just wait.</span>")

		else if (istype(W, /obj/item/grab))
			var/obj/item/grab/G = W
			if (ismob(G.affecting))
				var/mob/GM = G.affecting
				if (src.open)
					GM.set_loc(src)
					src.occupant = GM
					src.preview.add_client(GM.client)
					src.update_preview()
					ui_interact(GM)
					user.visible_message("<span class='alert'><b>[user] stuffs [GM.name] into [src]!</b></span>","<span class='alert'><b>You stuff [GM.name] into [src]!</b></span>")
					src.close()
					qdel(G)
					logTheThing(LOG_COMBAT, user, "places [constructTarget(GM,"combat")] into [src] at [log_loc(src)].")
		else
			..()

	attack_hand(mob/user)
		if (!ishuman(user))
			boutput(user,"<span style=\"color:red\">Human clothes don't fit you!</span>")
			return
		if (!IN_RANGE(user, src, 1))
			return
		if (!can_act(user))
			return
		if (open)
			user.set_loc(src.loc)
			SPAWN(0.5 SECONDS)
				if (!open) return
				user.set_loc(src)
				src.close()
				src.occupant = user
				src.preview.add_client(user.client)
				src.update_preview()
				ui_interact(user)
		else
			SETUP_GENERIC_ACTIONBAR(user, src, 10 SECONDS, PROC_REF(eject), null, src.icon, src.icon_state, "[user] forces open [src]!", INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ACTION)

	Click()
		if((usr in src) && (src.open == 0))
			if(istype(usr.equipped(),/obj/item/currency/spacecash))
				var/obj/item/dummycredits = usr.equipped()
				src.money += dummycredits.amount
				dummycredits.amount = 0
				qdel(dummycredits)
			src.ui_interact(usr)
		..()

	disposing()
		qdel(src.preview)
		qdel(src.preview_item)
		qdel(src.item_to_purchase)
		..()

	relaymove(mob/user as mob)
		if (!isalive(user))
			return
		eject(user)

	ui_interact(mob/user, datum/tgui/ui)
		if(!user.client)
			return
		if(!ishuman(user))
			return
		ui = tgui_process.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "ClothingBooth")
			ui.open()

	ui_close(mob/user)
		. = ..()
		if (!isnull(src.preview_item))
			qdel(src.preview_item)
			src.preview_item = null

	ui_static_data(mob/user)
		. = list(
			"name" = src.name
		)
		.["clothingBoothStockInformation"] = global.clothingbooth_stock_information

	ui_data(mob/user)
		var/icon/preview_icon = getFlatIcon(src.preview.preview_thing, no_anim = TRUE)
		. = list(
			"money" = src.money,
			"previewIcon" = icon2base64(preview_icon),
			"previewHeight" = preview_icon.Height(),
			"previewItem" = src.preview_item,
		)

	ui_act(action, params)
		. = ..()
		if (. || !(usr in src.contents))
			return

		switch(action)
			if("purchase")
				if(src.item_to_purchase)
					if(text2num_safe(src.item_to_purchase.cost) <= src.money)
					else
						boutput(usr, "<span class='alert'>Insufficient funds!</span>")
						animate_shake(src, 12, 3, 3)
					. = TRUE
				else
					boutput(usr, "<span class='alert'>No item selected!</span>")
			if ("rotate-cw")
				src.current_preview_direction = turn(src.current_preview_direction, -90)
				update_preview()
				. = TRUE
			if ("rotate-ccw")
				src.current_preview_direction = turn(src.current_preview_direction, 90)
				update_preview()
				. = TRUE
			if("select")
				update_preview()
				. = TRUE

	/// open the booth
	proc/open()
		flick("clothingbooth-opening", src)
		src.icon_state = "clothingbooth-open"
		src.open = TRUE

	/// close the booth
	proc/close()
		flick("clothingbooth-closing", src)
		src.icon_state = "clothingbooth-closed"
		src.open = FALSE

	/// ejects occupant if any along with any contents
	proc/eject(mob/occupant)
		if (open) return
		open()
		SPAWN(2 SECONDS)
			qdel(src.preview_item)
			qdel(src.item_to_purchase)
			src.preview.remove_all_clients()
			src.current_preview_direction = src.preview_direction_default
			src.item_to_purchase = null
			tgui_process.close_uis(src)
			var/turf/T = get_turf(src)
			if (!occupant)
				occupant = locate(/mob/living/carbon/human) in src
			if (occupant?.loc == src) //ensure mob wasn't otherwise removed during out spawn call
				occupant.set_loc(T)
				if(src.money > 0)
					occupant.put_in_hand_or_drop(new /obj/item/currency/spacecash(T, src.money))
				src.money = 0
				for (var/obj/item/I in src.contents)
					occupant.put_in_hand_or_drop(I)
				for (var/atom/movable/AM in contents)
					AM.set_loc(T) //dump anything that's left in there on out
			else
				if(src.money > 0)
					new /obj/item/currency/spacecash(T, src.money)
				src.money = 0
				for (var/atom/movable/AM in contents)
					AM.set_loc(T)

	/// generates a preview of the current occupant
	proc/update_preview()
		src.preview.update_appearance(src.occupant.bioHolder.mobAppearance, src.occupant.mutantrace, src.current_preview_direction, src.occupant.real_name)

/obj/item/paper/passport_slip
	name = "application for citizenship"
	info = {"\
<pre>
│.│......UN Space Station Geneva.......|..Deep.Space..│
│.│...................................................│
│.│............APPLICATION FOR CITIZENSHIP............│
│.│...................................................│
│.│..APPLICANT STAMP: ...........OFFICIAL STAMP: .....│
│.│..┌───────────────────────┐..┌──────────────────┐..│
│.│..│                       │..│                  │..│
│.│..│                       │..│                  │..│
│.│..│                       │..│                  │..│
│.│..└───────────────────────┘..└──────────────────┘..│
│.│...................................................│
</pre>\
"}
	sizey = 220
	var/datum/mind/passport_recipient = null
	var/alist/stamp_mode = alist(
		"Captain"			= /datum/nation/un,
		"Head of Security"	= /datum/nation/un,
		"Chief Engineer"	= /datum/nation/engineering,
		"Medical Director"	= /datum/nation/medical,
		"Research Director"	= /datum/nation/research,
		"Head of Personnel"	= /datum/nation/service,
		"Quartermaster"		= /datum/nation/supply,
	)

/obj/item/paper/passport_slip/disposing()
	src.passport_recipient = null
	. = ..()

/obj/item/paper/passport_slip/on_stamp(mob/user, datum/tgui/ui, obj/item/stamp/stamp)
	if (user.mind && (stamp.current_mode == "Your Name"))
		ON_COOLDOWN(src, "passport_stampable", 60 SECONDS)
		src.passport_recipient = user.mind

	else
		src.attempt_passportify(user, ui, src.stamp_mode[stamp.current_mode])

/obj/item/paper/passport_slip/proc/attempt_passportify(mob/user, datum/tgui/ui, datum/nation/nation_type)
	if (!ispath(nation_type) || QDELETED(src.passport_recipient))
		return

	var/datum/nation/nation = global.get_singleton(nation_type)
	if (user.mind != nation.leader)
		boutput(user, SPAN_ALERT("You aren't the leader of that nation!"))
		return

	if (!GET_COOLDOWN(src, "passport_stampable"))
		boutput(user, SPAN_ALERT("Passport VOID: This paper was stamped too long ago by the applicant!"))
		return

	if ((user.mind != src.passport_recipient) && (src.passport_recipient.passport?.nation?.leader == src.passport_recipient))
		boutput(user, SPAN_ALERT("You can't grant citizenship to rival leaders!"))
		return

	SPAWN(0.5 SECONDS)
		var/obj/item/passport/passport = null
		if (!QDELETED(src.passport_recipient.passport) && (src.passport_recipient.passport.nation_type == nation_type))
			passport = src.passport_recipient.passport
		else
			var/passport_type = nation_type::passport_type
			passport = new passport_type(null, src.passport_recipient)

		passport.set_loc(src.loc)
		passport.pixel_x = src.pixel_x
		passport.pixel_y = src.pixel_y

		if (src.loc == user)
			user.u_equip(src)
			user.put_in_hand_or_drop(passport)

		ui?.close()
		qdel(src)

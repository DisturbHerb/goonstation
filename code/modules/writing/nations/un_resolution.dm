/obj/item/paper/un_resolution
	name = "UN Resolution"
	info = {"\
<pre>
│.│......UN Space Station Geneva.......|..Deep.Space..│
│.│...................................................│
│.│..┌─────────────────────────────────────────────┐..│
$RESOLUTION_TEXT
│.│..└─────────────────────────────────────────────┘..│
│.│...................................................│
│.│..APPROVAL: ...............UNITED NATIONS: ........│
│.│..┌──────────────────┐.....┌────────────────────┐..│
│.│..│                  │.....│                    │..│
│.│..│                  │.....│                    │..│
│.│..│                  │.....│                    │..│
│.│..└──────────────────┘.....│                    │..│
│.│..GENERAL SECRETARY: ......│                    │..│
│.│..┌──────────────────┐.....│                    │..│
│.│..│                  │.....│                    │..│
│.│..│                  │.....│                    │..│
│.│..│                  │.....│                    │..│
│.│..└──────────────────┘.....└────────────────────┘..│
│.│...................................................│
</pre>\
"}
	var/line_length = 43
	var/line_prefix = "│.│..│ "
	var/line_suffix = " │..│"
	var/resolution_text = "Lorem ipsum dolor sit amet."

	var/stamp_granted = FALSE
	var/stamp_captain = FALSE
	var/stamp_un = FALSE
	var/stamp_void = FALSE
	var/approved = FALSE
	var/voided = FALSE

/obj/item/paper/un_resolution/New(newLoc, resolution_text)
	. = ..()

	if (resolution_text)
		src.resolution_text = resolution_text

	src.resolution_text = trimtext(src.resolution_text)

	var/list/replacement_text = list()
	for (var/line as anything in src.format_resolution_text())
		replacement_text += src.line_prefix + line + src.line_suffix

	src.info = replacetext(src.info, "$RESOLUTION_TEXT", replacement_text.Join("\n"))

/obj/item/paper/un_resolution/disposing()
	src.void_resolution(null)
	. = ..()

/obj/item/paper/un_resolution/on_stamp(mob/user, datum/tgui/ui, obj/item/stamp/stamp)
	if (!user.mind)
		return

	if (!user.mind.get_antagonist(ROLE_UN_SECGEN) && !user.mind.get_antagonist(ROLE_UN_UNDSEC))
		return

	switch (stamp.current_mode)
		if ("Granted")
			src.stamp_granted = TRUE
		if ("Captain", "Head of Security")
			src.stamp_captain = TRUE
		if ("United Nations")
			src.stamp_un = TRUE
		if ("Void")
			src.stamp_void = TRUE
		else
			return

	if (!src.approved && src.stamp_granted && src.stamp_captain && src.stamp_un)
		if (src.stamp_void)
			boutput(user, SPAN_ALERT("This resolution has been voided and can't be approved!"))
			return

		src.approve_resolution()

	else if (src.approved && !src.voided && src.stamp_void)
		src.void_resolution()

/obj/item/paper/un_resolution/proc/approve_resolution(mob/user)
	if (src.approved)
		return

	src.approved = TRUE
	logTheThing(LOG_GAMEMODE, user, "approved UN resolution with content: \"[src.resolution_text]\"")
	SPAWN(0.5 SECONDS)
		command_alert(src.resolution_text, title = "New Resolution Adopted", sound_to_play = 'sound/misc/announcement_1.ogg', alert_origin = ALERT_UNITED_NATIONS)

/obj/item/paper/un_resolution/proc/void_resolution(mob/user)
	if (!src.approved || src.voided)
		return

	src.voided = TRUE
	logTheThing(LOG_GAMEMODE, user, "voided UN resolution with content: \"[src.resolution_text]\"")
	SPAWN(0.5 SECONDS)
		command_alert(src.resolution_text, title = "Resolution VOIDED", sound_to_play = 'sound/misc/announcement_1.ogg', alert_origin = ALERT_UNITED_NATIONS)

/obj/item/paper/un_resolution/proc/format_resolution_text()
	var/list/lines = list()
	var/list/words = splittext(src.resolution_text, " ")

	var/line = ""
	while (length(words))
		var/word = words[1]
		words.Cut(1, 2)
		line += word

		// If the line is the correct length, move to the next line.
		if (length(line) == src.line_length)
			lines += line
			line = ""

		// If the line is one short of the correct length, add a space and move to the next line.
		else if (length(line) == (src.line_length - 1))
			lines += line + " "
			line = ""

		// If the line is two short of the correct length, add two spaces and move to the next line.
		else if (length(line) == (src.line_length - 2))
			lines += line + "  "
			line = ""

		// If the line is longer than the correct length, split the most recent word with a hyphen and add the remainder to the next line.
		else if (length(line) > src.line_length)
			lines += copytext(line, 1, src.line_length) + "-"
			words.Insert(1, copytext(line, src.line_length, 0))
			line = ""

		// Otherwise, add a space and move to the next word.
		else if (length(words))
			line += " "

	if (line)
		lines += pad_trailing(line, src.line_length)

	return lines





/obj/item/device/resolution_writer
	name = "ResolutionWriter 2000"
	desc = "A device used to draft resolutions for the United Nations."
	icon_state = "ticketwriter"
	item_state = "accessgun"
	w_class = W_CLASS_SMALL
	flags = TABLEPASS | CONDUCT
	c_flags = ONBELT

/obj/item/device/resolution_writer/attack_self(mob/user)
	if (!ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/card/id/I = get_id_card(H.wear_id)
	if (!istype(I) || !(access_security in I.access))
		boutput(user, SPAN_ALERT("Insufficient access."))
		return

	playsound(src, 'sound/machines/keyboard3.ogg', 30, TRUE)
	var/resolution_text = global.tgui_input_text(user, "Resolution content:", "Create Draft Resolution", multiline = TRUE)
	if (!trimtext(resolution_text))
		return

	playsound(src, 'sound/machines/printer_thermal.ogg', 50, TRUE)
	SPAWN(3 SECONDS)
		var/obj/item/paper/un_resolution/resolution = new /obj/item/paper/un_resolution(null, resolution_text)
		user.put_in_hand_or_drop(resolution)

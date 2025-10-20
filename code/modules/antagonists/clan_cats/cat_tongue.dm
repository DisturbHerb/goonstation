/datum/bioEffect/speech/clan_cat
	name = "Frontal Gyrus Alteration Type-Warrior"
	desc = "Compels the language center of the subject's brain to reject the vocabulary of a soft kittypet."
	id = SPEECH_MODIFIER_ACCENT_CLAN_CAT
	msgGain = "You feel like you've seen a sign from StarClan!"
	msgLose = "The memory of the Clans, alongside years of a forgotten childhood absorbed in cat-based fandom discourse, begins to fade..."

/datum/speech_module/modifier/accent/clan_cat
	id = SPEECH_MODIFIER_ACCENT_CLAN_CAT
	accent_proc = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cat_tongueify))

/// I AM A WARRIOR CAT!
/proc/cat_tongueify(string)
	if (!length(string))
		return

	// ORDER OF SUBSTITUTION AND ALIAS MATTERS.
	// Multi-word phrases.
	var/alist/substitutes = list(
		"belt hell" = "thunderpath",
		"chief engineer" = "twoleg workfolk mentor"
		"god damn it" = "StarClan-curse it",
		"god damned" = "StarClan-cursed",
		"god damn" = "StarClan-curse",
		"head of personnel" = "twoleg deputy",
		"head of security" = "twoleg warrior",
		"security officer" = "twoleg warrior",
		"staff assistant" = "rogue"
		"medical assistant" = "twoleg medicine apprentice",
		"medical director" = "twoleg medicine mentor",
	)
	// Aliases for multi-word phrases and random sbus.
	var/alist/aliases = list(
		"foolish" = "idiotic",
		"fool" = "idiot",
		"stupid" = "idiotic",
		"god damnit" = "god damn it",
		"med assistant" = "medical assistant",
		"medical ass" = "medical assistant",
		"med ass" = "medical assistant",
		"med director" = "medical director",
		"medical dir" = "medical director",
		"med dir" = "medical director",
		"medical doctor" = "medical director",
		"med doctor" = "medical director",
		"medical doc" = "medical director",
		"med doc" = "medical director",
		"sec officer" = "security officer",
		"bull crap" = "bullcrap",
		"bull shit" = "bullshit",
		"house cat" = "housecat",
		"hall way" = "hallway",
	)
	// Replace aliases in string first.
	for (var/alias in aliases)
		string = replacetext(string, alias, aliases[alias])
	for (var/phrase in substitutes)
		string = replacetext(string, phrase, substitutes[phrase])

	// Single words. See language/clan_cat.txt.
	var/list/tokens = splittext(string, " ")
	var/list/modded_tokens = list()
	for (var/token in tokens)
		var/regex/punct_check = regex(@"\W+\Z", "i")
		var/punct = ""
		var/punct_index = findtext(token, punct_check)
		if (punct_index)
			punct = copytext(token, punct_index)
			token = copytext(token, 1, punct_index)
		// Check case-sensitive first.
		var/matching_token = strings("language/clan_cat.txt", token, TRUE) || strings("language/clan_cat.txt", lowertext(token), TRUE)
		// Some replacements are as lists that may be randomly picked from.
		if (matching_token)
			if (findtext(matching_token, ","))
				matching_token = pick(splittext(matching_token, ","))
			token = replacetext(token, lowertext(token), matching_token)
		modded_tokens += (token + punct)
	. = jointext(modded_tokens, " ") || string

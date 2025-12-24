// Todo: Settler colony named after the leader.

/datum/cat_clan
	var/clan_name = "DebugClan"
	var/name_prefix = "Debug"
	var/clan_type = CLAN_TYPE_MODERN
	var/datum/mind/leader = null
	var/list/datum/mind/members = list()

/datum/cat_clan/New()
	. = ..()
	src.clan_name = src.pick_clan_name()

/datum/cat_clan/proc/pick_clan_name()
	if (src.clan_type == CLAN_TYPE_SETTLER)
		. = "Tall Shadow's Camp"
		return
	src.name_prefix = strings("names/clan_cats/clan_cat_names.txt", pick("prefixes"))
	. = "[src.name_prefix]Clan"

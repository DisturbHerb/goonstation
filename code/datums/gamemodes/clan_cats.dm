/*
 *	Clan Cats/Battle Kitties
 *
 *	Significant portions of this gamemode are derived from `code\datums\gamemodes\gangwar.dm`.
 */

var/global/list/color_list = list("#88CCEE","#117733","#332288","#DDCC77","#CC6677","#AA4499")
var/global/list/colors_to_assign = list()

/datum/game_mode/clan_cats
	name = "Battle Kitties"
	config_tag = "clan_cats"
	regular = FALSE

	var/list/datum/cat_clans/clans = list()

	/// Fourtrees means four clans, right?
	var/const/max_clans = 5
	var/const/min_clans = 2

	/// Maximum starting clan size.
	var/const/max_clan_size = 9
	/// Minimum starting clan size.
	var/const/min_clan_size = 3

	var/const/min_players = 15

	var/clan_count = 0

/datum/game_mode/clan_cats/announce()
	boutput(world, "<b>The current game mode is - Battle Kitties!</b>")
	boutput(world, "<b>Groups of wild cats will vie for control of territory in Twolegplace!</b>")
	boutput(world, "<b>Clan cats are antagonists, avoid humans with disdain, and may kill or be killed!</b>")

/datum/game_mode/clan_cats/pre_setup()
	. = TRUE

	var/num_players = src.roundstart_player_count()
#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	if (num_players < src.min_players)
		message_admins("<b>ERROR: Minimum player count of [src.min_players] required for Battle Kitties, aborting round pre-setup.</b>")
		logTheThing(LOG_GAMEMODE, src, "Failed to start Battle Kitties. [num_players] players were ready but a minimum of [src.min_players] players is required. ")
		return FALSE
#endif

	var/list/datum/mind/possible_leaders = src.get_possible_enemies(ROLE_CLAN_LEADER)
	if (!length(possible_leaders))
		logTheThing(LOG_GAMEMODE, src, "No clan leaders are available, aborting round pre-setup.")
		return FALSE
#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	if (src.min_clans > length(possible_leaders))
		logTheThing(LOG_GAMEMODE, src, "Not enough clan leaders are available, aborting round pre-setup.")
		return FALSE
#endif

#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	var/list/datum/mind/possible_clan_cats = src.get_possible_enemies(ROLE_CLAN_CAT, force_fill = FALSE)
	if (length(possible_clan_cats) < (src.min_clans * src.min_clan_size))
		logTheThing(LOG_GAMEMODE, src, "Not enough available cats to fill out a minimum of [src.min_clans] clans, aborting round pre-setup.")
		return FALSE
#endif

	/// Given a maximum of 6 cats to a clan, we'll attempt to maximise the size of a clan before spinning off more clans. For example, if there are
	/// 12 available cats (incl. 2 leaders), we'll have 2 clans at the maximum size. If we add another cat and assume there's another leader
	/// available, we'll have 3 clans; 2 of which will have 4 cats and 1 with 5 cats.
	src.clan_count = clamp(ceil((length(possible_clan_cats) / src.max_clan_size)), src.min_clans, min(length(possible_leaders), src.max_clans))
	if (src.clan_count < src.min_clans)
		logTheThing(LOG_GAMEMODE, src, "Something went wrong when calculating the number of clans to spawn! Aborting round pre-setup.")
		return FALSE

	var/list/chosen_leaders = antagWeighter.choose(pool = possible_leaders, role = ROLE_CLAN_LEADER, amount = src.clan_count, recordChosen = 1)
	src.traitors |= chosen_leaders

	for (var/datum/mind/leader as anything in src.traitors)
		possible_leaders.Remove(leader)
		leader.special_role = ROLE_CLAN_LEADER

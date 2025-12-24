/*
 *	Clan Cats/Battle Kitties
 *
 *	Significant portions of this gamemode are derived from `code\datums\gamemodes\gangwar.dm`.
 */

/// Must equal in count to the maximum number of possible clans.
var/global/list/cat_clan_color_list = list("#88CCEE","#117733","#332288","#DDCC77","#CC6677","#AA4499")
var/global/list/cat_clan_colors_to_assign = list()

/datum/game_mode/clan_cats
	name = "Battle Kitties"
	config_tag = "clan_cats"
	regular = FALSE
	antag_token_support = TRUE

	var/list/datum/cat_clan/clans = list()

	/// Fourtrees means four clans, right?
	var/const/max_clans = 5
	var/const/min_clans = 2

	/// Maximum starting clan size.
	var/const/max_clan_size = 6
	/// Minimum starting clan size.
	var/const/min_clan_size = 3
	/// For every cat, there must be this many human players.
	var/const/human_to_cat_ratio = 2

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

	var/list/datum/mind/possible_clan_cats = src.get_possible_enemies(ROLE_CLAN_CAT, force_fill = FALSE)
	var/clan_cat_count = length(possible_clan_cats)
#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	if (clan_cat_count < (src.min_clans * src.min_clan_size))
		logTheThing(LOG_GAMEMODE, src, "Not enough available cats to fill out a minimum of [src.min_clans] clans, aborting round pre-setup.")
		return FALSE
#endif
	clan_cat_count = min(clan_cat_count, num_players / (src.human_to_cat_ratio + 1))

	// Given a maximum of 6 cats to a clan, we'll attempt to maximise the size of a clan before spinning off more clans. For example, if there are
	// 12 available cats, we'll have 2 clans at the maximum size. If we add another cat, we'll have 3 clans; 2 of which will have 4 cats and 1 with
	// 5 cats.
	src.clan_count = clamp(ceil((clan_cat_count / src.max_clan_size)), src.min_clans, src.max_clans)
	if (src.clan_count < src.min_clans)
		logTheThing(LOG_GAMEMODE, src, "Something went wrong when calculating the number of clans to spawn! Aborting round pre-setup.")
		return FALSE

	var/list/datum/mind/chosen_clan_cats = list()

	// Antag token handling.
	src.token_players = antag_token_list()
	for (var/datum/mind/token_player in src.token_players)
		if (!length(src.token_players))
			break
		chosen_clan_cats += token_player
		token_players.Remove(token_player)
		logTheThing(LOG_ADMIN, token_player.current, "successfully redeemed an antag token.")
		message_admins("[key_name(token_player.current)] successfully redeemed an antag token.")

	clan_cat_count = clan_cat_count - length(chosen_clan_cats)
	chosen_clan_cats += antagWeighter.choose(pool = possible_clan_cats, role = ROLE_CLAN_CAT, amount = clan_cat_count, recordChosen = 1)
	src.traitors |= chosen_clan_cats

	global.cat_clan_colors_to_assign = global.cat_clan_color_list

/datum/game_mode/clan_cats/post_setup()
	. = TRUE
	var/list/datum/mind/chosen_leaders = antagWeighter.choose(pool = src.traitors, role = ROLE_CLAN_LEADER, amount = src.clan_count, recordChosen = 1)
	for (var/datum/mind/leader_mind as anything in chosen_leaders)
		leader_mind.special_role = ROLE_CLAN_LEADER
		leader_mind.add_antagonist(ROLE_CLAN_LEADER, silent = TRUE)

	var/list/datum/mind/members_to_assign = src.traitors - chosen_leaders
	shuffle_list(members_to_assign)
	for (var/datum/mind/member_to_assign as anything in members_to_assign)
		var/datum/cat_clan/target_clan = src.get_smallest_clan()
		target_clan.members += member_to_assign
		member_to_assign.special_role = ROLE_CLAN_CAT
		member_to_assign.add_antagonist(ROLE_CLAN_CAT, silent = TRUE)

	for (var/datum/mind/evil_kitty_mind in src.traitors)
		evil_kitty_mind.get_antagonist(ROLE_CLAN_LEADER)?.unsilence()
		evil_kitty_mind.get_antagonist(ROLE_CLAN_CAT)?.unsilence()

/datum/game_mode/clan_cats/proc/get_smallest_clan()
	RETURN_TYPE(/datum/cat_clan)
	var/datum/cat_clan/smallest_clan = null
	for (var/datum/cat_clan/clan_to_check as anything in src.clans)
		if ((length(smallest_clan.members) > length(clan_to_check.members)) || !smallest_clan)
			smallest_clan = clan_to_check
			continue
	. = smallest_clan

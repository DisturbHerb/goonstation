ABSTRACT_TYPE(/datum/antagonist/mob/clan_cat)
/datum/antagonist/mob/clan_cat
	id = ROLE_CLAN_CAT
	display_name = "battle kitty"
	antagonist_icon = "clan_cat"
	faction = list(FACTION_CLAN_CATS)
	mob_path = /mob/living/critter/small_animal/cat
	uses_pref_name = FALSE

	var/datum/cat_clan/clan = null

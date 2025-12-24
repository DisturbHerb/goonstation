ABSTRACT_TYPE(/datum/canon_cat)
/// These are cats that are canon to *Warrior Cats*. There's a chance to roll one randomly when randomly picking cat appearances.
/datum/canon_cat
	/// Do not override manually.
	var/name = ""
	var/prefix = ""
	var/suffix = ""
	var/gender = NEUTER
	/// As type path.
	var/pronouns = /datum/pronouns/theyThem
	var/desc = "unpleasant black-and-purple chequered non-binary warrior"
	var/pelt_pattern = PELT_PATTERN_TUXEDO
	var/primary_color = "#000000"
	var/secondary_color = "#FF00FF"

// todo: give him blond hair
/datum/canon_cat/ashfur

/datum/canon_cat/blackstar

/datum/canon_cat/brambleclaw

/datum/canon_cat/briarlight

/datum/canon_cat/brightheart

/datum/canon_cat/cinderpelt

/datum/canon_cat/cloudtail

/datum/canon_cat/crookedstar

/datum/canon_cat/crowfeather

/datum/canon_cat/dovewing

/datum/canon_cat/feathertail

/datum/canon_cat/fireheart
	prefix = "Fire"
	suffix = "Heart"
	gender = MALE
	pronouns = /datum/pronouns/heHim
	desc = "handsome ginger tom"
	pelt_pattern = PELT_PATTERN_TUXEDO
	primary_color = "#EF7F1D"
	secondary_color = "#da9d1b"

/datum/canon_cat/graystripe

/datum/canon_cat/hollyleaf

/datum/canon_cat/jayfeather

/datum/canon_cat/leafpool

/datum/canon_cat/longtail

/datum/canon_cat/mothwing

/datum/canon_cat/ravenpaw

/datum/canon_cat/sandstorm

/datum/canon_cat/sorreltail

/datum/canon_cat/squirrelflight

/datum/canon_cat/talltail

/datum/canon_cat/tawnypelt

/datum/canon_cat/tigerclaw

/datum/canon_cat/yellowfang


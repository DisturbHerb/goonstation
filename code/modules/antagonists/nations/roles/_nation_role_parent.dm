ABSTRACT_TYPE(/datum/antagonist/nation)
/datum/antagonist/nation
	/// Whether the display name should be generated from the nation datum.
	var/generate_name = TRUE
	/// The nation type that the owner belongs to.
	var/datum/nation/nation_type = /datum/nation
	/// The owner's passport.
	var/obj/item/passport/passport = null
	/// Whether this role is a citizen or a leader.
	var/role_type = null
	/// Whether to use the definite or indefinite article.
	var/article = ""

/datum/antagonist/nation/New(datum/mind/new_owner)
	for (var/datum/antagonist/nation/A in new_owner.antagonists)
		new_owner.remove_antagonist(A.id)

	if (src.generate_name)
		src.display_name = "[src.role_type] of [src.nation_type::name]"

	. = ..()

/datum/antagonist/nation/give_equipment()
	if (!QDELETED(src.owner.passport) && (src.owner.passport.nation_type == src.nation_type))
		src.passport = src.owner.passport

	else
		var/passport_type = src.nation_type::passport_type
		src.passport = new passport_type(null, src.owner, give_antag_role = FALSE)
		src.owner.current.put_in_hand_or_drop(src.passport)

	src.RegisterSignal(src.passport, COMSIG_PARENT_PRE_DISPOSING, PROC_REF(remove_callback))

/datum/antagonist/nation/remove_equipment()
	src.UnregisterSignal(src.passport, COMSIG_PARENT_PRE_DISPOSING)
	QDEL_NULL(src.passport)

/datum/antagonist/nation/announce()
	boutput(src.owner.current, SPAN_ALERT("<h2 class='system'>You are [src.article] [src.display_name]!</h2>"))

/datum/antagonist/nation/announce_removal()
	boutput(src.owner.current, SPAN_ALERT("<h2 class='system'>You are no longer [src.article] [src.display_name]!</h2>"))

/datum/antagonist/nation/proc/remove_callback()
	src.owner.remove_antagonist(src)


ABSTRACT_TYPE(/datum/antagonist/nation/citizen)
/datum/antagonist/nation/citizen
	succinct_end_of_round_antagonist_entry = TRUE
	role_type = "Citizen"
	article = "a"

/datum/antagonist/nation/citizen/give_equipment()
	. = ..()
	src.passport.nation.add_citizen(src.owner)

/datum/antagonist/nation/citizen/remove_equipment()
	src.passport.nation.remove_citizen(src.owner)
	. = ..()


ABSTRACT_TYPE(/datum/antagonist/nation/leader)
/datum/antagonist/nation/leader
	role_type = "Leader"
	article = "the"

/datum/antagonist/nation/leader/give_equipment()
	. = ..()
	src.passport.nation.add_leader(src.owner, src.id)

/datum/antagonist/nation/leader/remove_equipment()
	src.passport.nation.remove_leader(src.owner, src.id)
	. = ..()

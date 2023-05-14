/obj/ability_button/herb/hood_toggle
	name = "Toggle Hood"
	icon_state = "hood_up"

	execute_ability()
		var/obj/item/clothing/suit/parka/W = the_item
		SEND_SIGNAL(W, COMSIG_SUIT_HOOD, src.the_mob)
		..()

/obj/ability_button/herb/coat_toggle
	name = "(Un)Button Coat"
	icon_state = "labcoat"

	execute_ability()
		var/obj/item/clothing/suit/parka/W = the_item
		SEND_SIGNAL(W, COMSIG_SUIT_BUTTON, src.the_mob)
		..()

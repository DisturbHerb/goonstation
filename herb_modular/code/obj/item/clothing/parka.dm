/obj/item/clothing/suit/parka
	name = "expedition parka"
	desc = {"A weather-resistant parka bearing the mission patch of the NSS Intrepid and the seal of the Nanotrasen Exploratory and Research Division.
			That name can't be anything but intentional, right?"}
	icon = 'herb_modular/icons/obj/clothing/item_suit.dmi'
	wear_image_icon = 'herb_modular/icons/mob/clothing/worn_suit.dmi'
	inhand_image_icon = 'herb_modular/icons/mob/inhand/hand_suit.dmi'
	icon_state = "parka"
	item_state = "parka"
	coat_style = "parka"
	body_parts_covered = TORSO|LEGS
	hides_from_examine = C_UNIFORM
	bloodoverlayimage = SUITBLOOD_COAT
	duration_remove = 4 SECONDS
	duration_put = 4 SECONDS

	New()
		..()
		src.AddComponent(/datum/component/toggle_hood, hood_style = "parka")

	setupProperties()
		..()
		setProperty("movespeed", 0.9)
		setProperty("coldprot", 70)

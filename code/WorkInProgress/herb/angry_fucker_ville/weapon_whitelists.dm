#define CARGO_WEAPONS "Cargo"
#define CIVILIAN_WEAPONS "Civilian"
#define ENGINEERING_WEAPONS "Engineering"
#define MEDICAL_WEAPONS "Medical"
#define RESEARCH_WEAPONS "Research"
#define SECURITY_WEAPONS "Security"


// Energy to kinetic weapons ratio.
#define ENERGY_GUN_WEIGHT 5
#define KINETIC_GUN_WEIGHT 3
#define THROWABLE_WEIGHT 2

var/static/list/jobs_and_departments = list(
	"Bartender" = CIVILIAN_WEAPONS,
	"Botanist" = CIVILIAN_WEAPONS,
	"Chef" = CIVILIAN_WEAPONS,
	"Chief Engineer" = ENGINEERING_WEAPONS,
	"Engineer" = ENGINEERING_WEAPONS,
	"Geneticist" = MEDICAL_WEAPONS,
	"Head of Personnel" = CIVILIAN_WEAPONS,
	"Janitor" = CIVILIAN_WEAPONS,
	"Medical Doctor" = MEDICAL_WEAPONS,
	"Miner" = CARGO_WEAPONS,
	"Pathologist" = MEDICAL_WEAPONS,
	"Quartermaster" = CARGO_WEAPONS,
	"Rancher" = CIVILIAN_WEAPONS,
	"Research Director" = RESEARCH_WEAPONS,
	"Roboticist" = MEDICAL_WEAPONS,
	"Scientist" = RESEARCH_WEAPONS,
	"Security Assistant" = SECURITY_WEAPONS,
	"Security Officer" = SECURITY_WEAPONS,
	"Staff Assistant" = CIVILIAN_WEAPONS
)

var/static/list/job_specific_weapons = list(
	"Bartender" = /obj/item/gun/kinetic/sawnoff,
	"Captain" = /obj/item/swords/captain,
	"Chaplain" = /obj/item/gun/kinetic/faith,
	"Clown" = /obj/item/toy/sword,
	"Detective" = /obj/item/gun/kinetic/detectiverevolver,
	"Head of Security" = /obj/item/gun/energy/lawbringer,
	"Medical Director" = /obj/item/gun/kinetic/dart_rifle
)

var/static/list/shitty_cargo_weapons = list(
	/obj/item/mining_tool/drill,
	/obj/item/mining_tool/power_pick,
	/obj/item/mining_tool/powerhammer,
	/obj/item/mining_tool/power_shovel
)

var/static/list/shitty_civ_weapons = list(
	/obj/item/chair/folded,
	/obj/item/extinguisher,
	/obj/item/gun/kinetic/foamdartgun,
	/obj/item/gun/kinetic/foamdartrevolver,
	/obj/item/gun/kinetic/foamdartshotgun,
	/obj/item/kitchen/rollingpin,
	/obj/item/kitchen/utensil/fork,
	/obj/item/kitchen/utensil/knife,
	/obj/item/kitchen/utensil/knife/pizza_cutter,
	/obj/item/mop,
	/obj/item/plate,
	/obj/item/plate/tray,
	/obj/item/razor_blade,
	/obj/item/scissors,
	/obj/item/storage/toolbox/emergency
)

var/static/list/shitty_eng_weapons = list(
	/obj/item/crowbar/yellow,
	/obj/item/deconstructor,
	/obj/item/screwdriver/yellow,
	/obj/item/wrench/yellow
)

var/static/list/shitty_med_weapons = list(
	/obj/item/scalpel,
	/obj/item/circular_saw,
	/obj/item/staple_gun,
	/obj/item/scissors/surgical_scissors
)

var/static/list/shitty_sci_weapons = list(
	/obj/item/gun/energy/phaser_gun,
	/obj/item/reagent_containers/glass/bottle/pacid
)

var/static/list/shitty_sec_weapons = list(
	/obj/item/gun/energy/taser_gun,
	/obj/item/gun/energy/tasershotgun,
	/obj/item/gun/energy/tasersmg,
	/obj/item/gun/energy/wavegun
)

var/static/list/angry_fucker_weapon_weights = list(
	energy_gun = ENERGY_GUN_WEIGHT,
	kinetic_gun = KINETIC_GUN_WEIGHT,
	throwable = THROWABLE_WEIGHT
)

var/static/list/valid_energy_gun_list = list(
	/obj/item/gun/energy/blaster_pistol = 30,
	/obj/item/gun/energy/crabgun = 2,
	/obj/item/gun/energy/wasp = 2,
	/obj/item/gun/energy/dazzler = 5,
	/obj/item/gun/energy/phaser_gun = 30,
	/obj/item/gun/energy/phaser_huge = 5,
	/obj/item/gun/energy/phaser_small = 50,
	/obj/item/gun/energy/laser_gun = 30,
)

var/static/list/valid_kinetic_gun_list = list(
	/obj/item/gun/kinetic/clock_188 = 30,
	/obj/item/gun/kinetic/hunting_rifle = 2,
	/obj/item/gun/kinetic/makarov = 30,
	/obj/item/gun/kinetic/minigun = 1,
	/obj/item/gun/kinetic/riotgun = 10,
	/obj/item/gun/kinetic/single_action/mts_255 = 5,
	/obj/item/gun/kinetic/spes = 5,
	/obj/item/gun/kinetic/survival_rifle = 20,
	/obj/item/gun/kinetic/akm = 5,
)

var/static/list/valid_throwable_list = list(
	/obj/item/chem_grenade/flashbang = 10,
	/obj/item/chem_grenade/incendiary = 5,
	/obj/item/old_grenade/emp = 2,
	/obj/item/old_grenade/sonic = 2,
	/obj/item/old_grenade/stinger = 5,
)

/proc/pick_a_weapon(var/job_name)
	for(var/i in job_specific_weapons)
		if(i == job_name)
			return job_specific_weapons[i]

	var/get_department
	for(var/i in jobs_and_departments)
		if(i == job_name)
			get_department = jobs_and_departments[i]
	if(!get_department)
		get_department = CIVILIAN_WEAPONS

	switch(get_department)
		if(CARGO_WEAPONS)
			. = shitty_cargo_weapons[rand(1, length(shitty_cargo_weapons))]
		if(CIVILIAN_WEAPONS)
			. = shitty_civ_weapons[rand(1, length(shitty_civ_weapons))]
		if(ENGINEERING_WEAPONS)
			. = shitty_eng_weapons[rand(1, length(shitty_eng_weapons))]
		if(MEDICAL_WEAPONS)
			. = shitty_med_weapons[rand(1, length(shitty_med_weapons))]
		if(RESEARCH_WEAPONS)
			. = shitty_sci_weapons[rand(1, length(shitty_sci_weapons))]
		if(SECURITY_WEAPONS)
			. = shitty_sec_weapons[rand(1, length(shitty_sec_weapons))]

#undef ENERGY_GUN_WEIGHT
#undef KINETIC_GUN_WEIGHT

#undef CARGO_WEAPONS
#undef CIVILIAN_WEAPONS
#undef ENGINEERING_WEAPONS
#undef MEDICAL_WEAPONS
#undef RESEARCH_WEAPONS
#undef SECURITY_WEAPONS

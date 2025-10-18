/**
 * # /datum/action/bar/icon/med_equipment_add_patient
 *
 * Because a generic actionbar didn't work.
 */
/datum/action/bar/icon/med_equipment_add_patient
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	var/datum/medical_equipment/medical_equipment = null
	var/obj/medical_equipment_obj = null
	var/mob/user = null
	var/mob/living/carbon/patient = null

/datum/action/bar/icon/med_equipment_add_patient/New(datum/medical_equipment/medical_equipment, mob/user, mob/living/carbon/patient, connect_time = 3 SECONDS)
	src.medical_equipment = medical_equipment
	src.medical_equipment_obj = src.medical_equipment.equipment_obj
	if (!src.medical_equipment_obj)
		CRASH("/datum/action/bar/icon/med_equipment_add_patient created without medical_equipment_obj!")
	src.icon = getFlatIcon(src.medical_equipment_obj, no_anim = TRUE)
	src.user = user
	src.owner = src.user
	if (!src.owner)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_equipment_add_patient without valid user!")
	src.patient = patient
	if (!src.patient)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_equipment_add_patient without valid patient!")
	src.duration = connect_time
	if (!src.duration)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_equipment_add_patient without valid duration!")
	..()

/datum/action/bar/icon/med_equipment_add_patient/onUpdate()
	..()
	if (src.check_interrupt())
		return

/datum/action/bar/icon/med_equipment_add_patient/onStart()
	..()
	if (src.check_interrupt())
		return

/datum/action/bar/icon/med_equipment_add_patient/onEnd()
	..()
	if (src.check_interrupt())
		return
	src.medical_equipment.add_patient(src.patient, src.user)

/datum/action/bar/icon/med_equipment_add_patient/proc/check_interrupt()
	. = FALSE
	if (BOUNDS_DIST(src.user, src.patient) || BOUNDS_DIST(src.user, src.owner) || BOUNDS_DIST(src.owner, src.patient))
		src.interrupt(INTERRUPT_ALWAYS)
		. = TRUE

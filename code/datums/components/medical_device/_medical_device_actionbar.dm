/**
 * # /datum/action/bar/icon/med_device_add_patient
 *
 * Because a generic actionbar didn't work.
 */
/datum/action/bar/icon/med_device_add_patient
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	var/datum/component/medical_device/medical_device = null
	var/obj/medical_device_parent = null
	var/mob/user = null
	var/mob/living/carbon/patient = null

/datum/action/bar/icon/med_device_add_patient/New(datum/component/medical_device/medical_device, mob/user, mob/living/carbon/patient, connect_time = 3 SECONDS)
	src.medical_device = medical_device
	src.medical_device_parent = src.medical_device.parent
	if (!isatom(src.medical_device_parent))
		CRASH("/datum/action/bar/icon/med_device_add_patient created without valid /datum/component/medical_device parent!")
	src.icon = getFlatIcon(src.medical_device_parent, no_anim = TRUE)
	src.user = user
	src.owner = src.user
	if (!src.owner)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_device_add_patient without valid user!")
	src.patient = patient
	if (!src.patient)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_device_add_patient without valid patient!")
	src.duration = connect_time
	if (!src.duration)
		CRASH("Cannot instantiate /datum/action/bar/icon/med_device_add_patient without valid duration!")
	..()

/datum/action/bar/icon/med_device_add_patient/onUpdate()
	..()
	if (src.check_interrupt())
		return

/datum/action/bar/icon/med_device_add_patient/onStart()
	..()
	if (src.check_interrupt())
		return

/datum/action/bar/icon/med_device_add_patient/onEnd()
	..()
	if (src.check_interrupt())
		return
	src.medical_device.add_patient(src.patient, src.user)

/datum/action/bar/icon/med_device_add_patient/proc/check_interrupt()
	. = FALSE
	if (BOUNDS_DIST(src.user, src.patient) || BOUNDS_DIST(src.user, src.owner) || BOUNDS_DIST(src.owner, src.patient))
		src.interrupt(INTERRUPT_ALWAYS)
		. = TRUE

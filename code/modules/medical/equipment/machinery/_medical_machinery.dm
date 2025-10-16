TYPEINFO(/obj/machinery/medical)
	mats = 10
	start_speech_modifiers = null
	start_speech_outputs = list(SPEECH_OUTPUT_SPOKEN_SUBTLE)

	/// `obj` types this machine can connect to.
	var/list/paired_obj_whitelist = list(
		/obj/machinery/optable,
		/obj/stool/bed,
		/obj/stool/chair,
	)

ABSTRACT_TYPE(/obj/machinery/medical)
/**
 * # Medical Machinery
 *
 * Larger medical equipments which utilise the machinery process loop and consume grid power.
 *
 * ## Unique behaviour
 * - Toggle brakes to (un)anchor the machine.
 * - Provides clear spoken feedback with maptext on certain events.
 * - Can be attached to any object within `TYPEINFO(/obj/machinery/medical).paired_obj_whitelist`.
 */
/obj/machinery/medical
	name = "medical machine"
	desc = "A medical doohickey. Call 1800-CODER if you see this."
	icon = 'icons/obj/machines/medical/iv_stand.dmi'
	icon_state = "IVstand"
	default_speech_output_channel = SAY_CHANNEL_OUTLOUD
	speech_verb_say = "beeps"

	var/tmp/datum/medical_equipment/equipment_datum = null

	/*
	 * `/datum/medical_equipment/` initialisation args.
	 * Modifying these at runtime won't do anything.
	 */
	var/tmp/connect_time = 3 SECONDS
	/// Type paths of `/datum/medical_equipment_function`.
	var/tmp/list/functions = list()

	/// Power consumption is constant if a patient is connected to the machine. In Watts.
	var/tmp/power_consumption = 250 MILLI WATTS

	/// For EMAG effects.
	var/tmp/hacked = FALSE
	/// Appended on examine.
	var/hacked_desc = "Something about it seems a little off."
	/*
	 * Start/Stop feedback.
	 */
	/// Fire off single feedback message after losing power. Resets on successful start.
	var/tmp/low_power_alert_given = FALSE
	/// Fire off single feedback message if failing to start. Resets on successful start.
	var/tmp/start_fail_alert_given = FALSE
	/// Fire off single feedback message on startup. Resets on stop.
	var/tmp/start_alert_given = FALSE
	/// Fire off single feedback message if stopping. Resets on successful start.
	var/tmp/stop_alert_given = FALSE
	/*
	 * Paired object vars.
	 */
	var/tmp/obj/paired_obj = null
	// Pixel offsets for this machine when paired.
	var/connect_offset_x = 0
	var/connect_offset_y = 10

/obj/machinery/medical/New()
	. = ..()
	src.equipment_datum = new /datum/medical_equipment(\
		attached_obj = src,\
		connect_time = src.connect_time,\
		functions = src.functions,\
	)

/obj/machinery/medical/disposing()
	qdel(src.equipment_datum)
	src.equipment_datum = null
	src.detach_from_obj()
	. = ..()

/obj/machinery/medical/get_desc(dist, mob/user)
	..()
	if (src.hacked)
		. += " [src.hacked_desc]"

/obj/machinery/medical/attack_hand(mob/user)
	if (src.paired_obj)
		boutput(user, SPAN_ALERT("Cannot adjust brakes while [src] is attached to [src.paired_obj]!"))
		return
	src.anchored = !src.anchored
	boutput(user, SPAN_NOTICE("You [src.anchored ? "apply" : "release"] \the [src.name]'s brake."))

/obj/machinery/medical/process(mult)
	..()

/obj/machinery/medical/mouse_drop(atom/over_object)
	var/mob/living/user = usr
	// Shunt it over to the datum if it's a potential patient.
	if (iscarbon(over_object))
		src.equipment_datum.mouse_drop(user, over_object)
		return
	if (!isatom(over_object))
		return
	if (!isliving(user))
		return FALSE
	if (isintangible(user))
		return FALSE
	if (!can_act(user))
		return FALSE
	if (!in_interact_range(src, user))
		return FALSE
	if (!in_interact_range(over_object, user))
		return FALSE
	src.mouse_drop_interactions(over_object, user)

/obj/machinery/medical/emag_act(mob/user, obj/item/card/emag/E)
	SHOULD_NOT_OVERRIDE(TRUE)
	if (src.hacked)
		return
	if (!src.equipment_datum)
		return
	if (!src.equipment_datum.hack())
		return
	src.hacked = TRUE
	logTheThing(LOG_ADMIN, user, "emagged [src] at [log_loc(user)].")
	logTheThing(LOG_DIARY, user, "emagged [src] at [log_loc(user)].", "admin")
	message_admins("[key_name(user)] emagged [src] at [log_loc(user)].")

/obj/machinery/medical/power_change()
	..()
	src.equipment_datum.power_change()

/obj/machinery/medical/proc/mouse_drop_interactions(atom/over_object, mob/living/user)
	if (!isatom(over_object) || !isliving(user))
		return
	if (isobj(over_object))
		if (over_object == src.paired_obj)
			src.detach_from_obj(user)
		else
			src.attempt_attach_to_obj(over_object, user)
		return

/// If failure to start, fire off once.
/obj/machinery/medical/proc/start_failure_feedback()
	SHOULD_CALL_PARENT(TRUE)
	if (src.start_fail_alert_given)
		return
	src.start_fail_alert_given = TRUE

/// Feedback on successful startup.
/obj/machinery/medical/proc/start_feedback()
	SHOULD_CALL_PARENT(TRUE)
	if (src.start_alert_given)
		return
	if (!src.equipment_datum.active)
		return
	src.start_alert_given = TRUE

/// Feedback on stopping for any reason.
/obj/machinery/medical/proc/stop_feedback(reason = MED_EQUIPMENT_FAILURE)
	SHOULD_CALL_PARENT(TRUE)
	if (src.low_power_alert_given || src.stop_alert_given)
		return
	if (!length(reason))
		reason = MED_EQUIPMENT_FAILURE
	if (!src.equipment_datum.active)
		return
	if ((reason == MED_EQUIPMENT_NO_POWER) && !src.low_power_alert_given)
		src.low_power_alert()
		return
	if (src.is_disabled())
		return
	src.stop_alert_given = TRUE

/// If stopping due to power loss, fire off once.
/obj/machinery/medical/proc/low_power_alert()
	SHOULD_CALL_PARENT(TRUE)
	if (src.low_power_alert_given || src.stop_alert_given)
		return
	if (!src.equipment_datum.active)
		return
	if (src.is_broken())
		return
	src.low_power_alert_given = TRUE
	src.stop_alert_given = TRUE

/obj/machinery/medical/proc/attempt_attach_to_obj(obj/target_object, mob/user)
	. = TRUE
	if (target_object == src.paired_obj)
		boutput(user, SPAN_ALERT("[src] is already attached to [src.paired_obj]!"))
		return FALSE
	if (src.anchored)
		boutput(user, SPAN_ALERT("Disengage the brakes first to attach [src] to [target_object]!"))
		return FALSE
	if (!in_interact_range(target_object, user))
		boutput(user, SPAN_ALERT("[src] is too far away to be attached to [target_object]!"))
		return
	var/typeinfo/obj/machinery/medical/typinfo = src.get_typeinfo()
	var/obj/object_to_attach_to = null
	for (var/whitelist_type in typinfo.paired_obj_whitelist)
		if (!istype(target_object, whitelist_type))
			continue
		object_to_attach_to = target_object
		break
	if (!object_to_attach_to)
		return FALSE
	src.attach_to_obj(object_to_attach_to, user)

/obj/machinery/medical/proc/attach_to_obj(obj/target_object, mob/user)
	. = TRUE
	if (!isobj(target_object))
		return FALSE
	if (src.paired_obj)
		src.detach_from_obj(user)
	if (ismob(user))
		src.visible_message(SPAN_NOTICE("[user] attaches [src] to [target_object]."))
	src.paired_obj = target_object
	src.set_loc(src.paired_obj.loc)
	src.pixel_x = src.connect_offset_x
	src.pixel_y = src.connect_offset_y
	src.density = src.paired_obj.density
	src.set_layer()
	mutual_attach(src, src.paired_obj)
	RegisterSignal(src.paired_obj, COMSIG_ATOM_DIR_CHANGED, PROC_REF(set_layer))
	RegisterSignal(src.paired_obj, COMSIG_PARENT_PRE_DISPOSING, PROC_REF(paired_obj_disposed))

/obj/machinery/medical/proc/detach_from_obj(mob/user)
	UnregisterSignal(src.paired_obj, COMSIG_ATOM_DIR_CHANGED)
	UnregisterSignal(src.paired_obj, COMSIG_PARENT_PRE_DISPOSING)
	mutual_detach(src, src.paired_obj)
	if (ismob(user))
		src.visible_message(SPAN_NOTICE("[user] detaches [src] from [src.paired_obj]."))
	src.paired_obj = null
	src.layer = initial(src.layer)
	src.pixel_x = initial(src.pixel_x)
	src.pixel_y = initial(src.pixel_y)
	src.density = initial(src.density)

/obj/machinery/medical/proc/paired_obj_disposed()
	src.detach_from_obj()

/// Specifically because of chairs, they change layers on dir change.
/obj/machinery/medical/proc/set_layer()
	if (!src.paired_obj)
		return
	src.layer = src.paired_obj.layer - 0.1

/// Override on children.
/obj/machinery/medical/proc/deconstruct()
	qdel(src)


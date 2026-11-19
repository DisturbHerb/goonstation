// TOOD:
// - eliminate CURRENT_SPACE_YEAR
// - set date time in server config?

/*
 * This is the file for in-universe time controls.
 * Day-night cycles are governed by code\datums\controllers\daynight_controls.dm.
 */

var/global/datum/time_controls/time_controls

/**
  * # Time Controls
  * Authored by @DisturbHerb, @Laboredih123.
  *
  * Controller for in-universe time. Distinct from `world.timeofday` and `world.realtime`, this governs the times and dates that are displayed to
  * players such as in-game clocks, timestamps, etc.
  *
  * This implementation exists primarily to avoid technical limitations with the BYOND time format which runs into the Year 2038 problem despite the
  * BYOND epoch starting on 2000-01-01 as opposed to UNIX. Likely, some back-end operation changes the time representation to a signed 32-bit integer
  * and causes the input time to overflow.
  *
  * Using round-start as the epoch, in-universe time will be calculated based on round time elapsed, pulled from `ticker.round_elapsed_ticks`,
  * starting from an arbitrary time and date. In-universe time is mutable and convertible between formats in a similar manner to vanilla BYOND time.
  */
/datum/time_controls
	// Current date and time.
	/// May be any signed integer up to 24 bits of precision.
	VAR_PROTECTED/year = TIME_IC::DEFAULT_YEAR
	/// Range of 1 to 12.
	VAR_PROTECTED/month = 1
	/// Range of 1 to 31.
	VAR_PROTECTED/day = 1
	/// Range of 0 to 23.
	VAR_PROTECTED/hours = 0
	/// Range of 0 to 59.
	VAR_PROTECTED/minutes = 0
	/// Range of 0 to 59.
	VAR_PROTECTED/seconds = 0
	/// Range of 0 to 9.
	VAR_PROTECTED/deciseconds = 0

	// Date and time overrides used to set the date and time on round-start.
	/// User-defined override. May be any signed integer up to 24 bits of precision.
	var/override_year = TIME_IC::DEFAULT_YEAR
	/// User-defined override. Range of 1 to 12.
	var/override_month = 1
	/// User-defined override. Range of 1 to 31.
	var/override_day = 1
	/// User-defined override. Range of 0 to 23.
	var/override_hours = 0
	/// User-defined override. Range of 0 to 59.
	var/override_minutes = 0
	/// User-defined override. Range of 0 to 59.
	var/override_seconds = 0
	/// User-defined override. Range of 0 to 9.
	var/override_deciseconds = 0

	// Time manipulation.
	/// The size of each step in time, assuming one step is made per real-world decisecond.
	var/step_size = 1 DECI SECOND
	/// Determines how many steps of size `src.step_size` in time occur each real-world decisecond.
	var/step_coefficient = 1

/datum/time_controls/New()
	. = ..()

// TODO: Input validation
/datum/time_controls/proc/set_time(input_year, input_month, input_day, input_hours, input_minutes, input_seconds, input_deciseconds)
	src.year = input_year
	src.month = input_month
	src.day = input_day

	src.hours = input_hours
	src.minutes = input_minutes
	src.seconds = input_seconds
	src.deciseconds = input_deciseconds

	logTheThing(LOG_DEBUG, null, "<b>Time Controls:</b> In-universe time set to [TIME_IC.time_as_text()].")

/**
  * Sets in-universe date and time to `world.realtime`.
  *
  * Arguments:
  * * `override_year`: 	Default behaviour is to use the initial value of `time_controls.year`, i.e. `TIME_IC::DEFAULT::YEAR` or 2053. Set as `TRUE` to
  * 					set as the current real-world year.
  */
/datum/time_controls/proc/set_time_as_realtime(override_year = FALSE)
	var/current_time = world.realtime

	var/current_year = initial(src.year)
	if (override_year)
		current_year = text2num_safe(time2text(current_time, "YYYY")) || initial(src.year)
	var/current_month = text2num_safe(time2text(current_time, "MM")) || initial(src.month)
	var/current_day = text2num_safe(time2text(current_time, "DD")) || initial(src.day)

	var/current_hours = text2num_safe(time2text(current_time, "hh")) || initial(src.hours)
	var/current_minutes = text2num_safe(time2text(current_time, "mm")) || initial(src.minutes)
	var/current_seconds = text2num_safe(time2text(current_time, "ss")) || initial(src.seconds)
	var/current_deciseconds = current_time % 10 DECI SECONDS || initial(src.deciseconds)

	src.set_time(current_year, current_month, current_day, current_hours, current_minutes, current_seconds, current_deciseconds)

/**
  * Returns the current in-universe time as text per a givent format.
  *
  *	Arguments:
  *	* `format`:	Uses native BYOND `time2text` format syntax.
  */
/datum/time_controls/proc/time_as_text(format = "DDD MMM DD hh:mm:ss YYYY")
	var/output_text = format

	output_text = replacetext(output_text, "YYYY", "[src.year]")
	output_text = replacetext(output_text, "YY", jointext(splittext("[src.year]", ""), "", -2))
	output_text = replacetext(output_text, "Month")
	output_text = replacetext(output_text, "MMM")
	output_text = replacetext(output_text, "MM")
	output_text = replacetext(output_text, "Day")
	output_text = replacetext(output_text, "DDD")
	output_text = replacetext(output_text, "DD")
	output_text = replacetext(output_text, "hh")
	output_text = replacetext(output_text, "mm")
	output_text = replacetext(output_text, "ss")

/**
  * Returns the current in-universe time as text per ISO 8601. Assumes that the current time is UTC/Zulu.
  *
  */
/datum/time_controls/proc/time_as_iso8601()
	. = ""

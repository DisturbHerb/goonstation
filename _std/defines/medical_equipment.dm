/*
 * Medical Equipment Datum
 */
// Signal Params
	/// Equipment fail reason
	#define MED_EQUIPMENT_FAIL_REASON "med_equip_fail_reason"
// Fail states
	/// Fail when no patient is passed.
	#define MED_EQUIPMENT_NO_PATIENT "med_equip_no_patient"
	/// Fail due to being broken.
	#define MED_EQUIPMENT_BROKEN "med_equip_broken"
	/// Fail due to no power.
	#define MED_EQUIPMENT_NO_POWER "med_equip_no_power"
	/// General fail state.
	#define MED_EQUIPMENT_FAILURE "med_equip_failure"

/*
 * Medical Equipment Function Datum
 */
// Fail states
	// General fail state.
	#define MED_FUNCTION_FAILURE "med_function_fail"
// /datum/medical_equipment_function/transfuser/iv
	// Params
		/// `reservoir`
		#define MED_TRANSFUSER_RESERVOIR "transfuser_reservoir"
		/// `transfer_volume`
		#define MED_TRANSFUSER_VOLUME "transfuser_volume"
// /datum/medical_equipment_function/transfuser/iv
	// Params
		#define MED_IV_MODE "iv_mode"
	// Fail states
		/// Patient full on IV inject.
		#define MED_IV_FULL "iv_patient_full"
		/// IV empty on IV inject.
		#define MED_IV_PT_EMPTY "iv_empty"
		/// Patient empty on IV draw.
		#define MED_IV_EMPTY "iv_patient_empty"
		/// IV full on IV draw.
		#define MED_IV_PT_FULL "iv_full"
	// Modes
		/// `mode`: Falsy
		#define MED_IV_DRAW 0
		/// `mode`: Truthy
		#define MED_IV_INJECT 1

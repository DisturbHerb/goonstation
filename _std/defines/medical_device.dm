// /datum/component/medical_device
	// Fail states
		/// Fail when no patient is passed.
		#define MED_DEVICE_NO_PATIENT "med_device_no_patient"
		/// Fail due to being broken.
		#define MED_DEVICE_BROKEN "med_device_broken"
		/// Fail due to no power.
		#define MED_DEVICE_NO_POWER "med_device_no_power"
		/// General fail state.
		#define MED_DEVICE_FAILURE "med_device_failure"
// /datum/component/medical_device/transfuser
	// Params
		/// `reservoir`
		#define MED_TRANSFUSER_RESERVOIR "transfuser_reservoir"
		/// `transfer_volume`
		#define MED_TRANSFUSER_VOLUME "transfuser_volume"
// /datum/component/medical_device/transfuser/dialysis
	// Fail states
		/// Patient has no blood or reagents.
		#define MED_DIALYSIS_PT_EMPTY "dialysis_patient_empty"
// /datum/component/medical_device/transfuser/iv
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

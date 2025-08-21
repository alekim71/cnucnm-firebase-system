
#==================================#
# Body reserves calculation module #
# Date : 2014-10-21                #
# Written by Hyesun Park           #
#==================================#


AF_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sAF", calc_temp)

	if (!file.exists(var.file)) {
		AF = 0.037683*BCS_beef
		dump("AF", file = var.file)
	} else {
		source(var.file)
	}

	return (AF)
}


AP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sAP", calc_temp)

	if (!file.exists(var.file)) { 
		AP = 0.200886-0.0066762*BCS_beef
		dump("AP", file=var.file)
	} else {
		source(var.file)
	}

	return (AP)
}


EBWr_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEBWr", calc_temp)

	if (!file.exists(var.file)) {
		EBWr = 0.851 * SBW
		dump("EBWr", file = var.file)
	} else {
		source(var.file)
	}

	return (EBWr)
}


TF_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sTF", calc_temp)

	if (!file.exists(var.file)) {
		AF = AF_calc(source_code)
		EBWr = EBWr_calc(source_code)
		TF = AF * EBWr
		dump("TF", file = var.file)
	} else  {
		source(var.file)
	}

	return (TF)
}


TBP_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sTBP", calc_temp)

	if (!file.exists(var.file)) {
		AP = AP_calc(source_code)
		EBWr = EBWr_calc(source_code)
		TBP = AP * EBWr
		dump("TBP", file=var.file)
	} else {
		source(var.file)
	}

	return (TBP)
}


TE_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTE", calc_temp)

	if (!file.exists(var.file)) {
		TF = TF_calc(source_code)
		TBP = TBP_calc(source_code)
		TE = 9.4 * TF + 5.7 * TBP 
		dump("TE", file=var.file)
	} else {
		source(var.file)
	}

	return (TE)
}


get_ERTable = function(source_code, bcs) {

	source(source_code)

	EBWBCS5 = EBWBCS5_calc(source_code)
	bcs_factor = BCS_AD_calc(source_code, bcs=bcs)		
	EBW_at_BCS5 = EBWBCS5 * bcs_factor 	
	TE = (0.037683*bcs)*EBW_at_BCS5*9.4+(0.200886-0.0066762*bcs)*EBW_at_BCS5*5.7
	er_table_values = c(bcs_factor, EBW_at_BCS5, TE)

	return (er_table_values)
}


BCS_AD_calc = function(source_code, bcs=NULL) {

	source(source_code)

	bcs_factor_list = c(0.726, 0.794, 0.863, 0.931, 1, 1.069, 1.137, 1.206, 1.274)
	if (!is.null(bcs)) {
		BCS_beef = bcs 
	}
	BCS_AD = bcs_factor_list[BCS_beef]
		
	return (BCS_AD)
}


EBWBCS5_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEBWBCS5", calc_temp)

	if (!file.exists(var.file)) {
		EBWr = EBWr_calc(source_code)
		BCS_AD = BCS_AD_calc(source_code)
		EBWBCS5 = EBWr/BCS_AD
		dump("EBWBCS5", file=var.file)
	} else {
		source(var.file)
	}	

	return (EBWBCS5)
}


BCSneg_calc = function(source_code){

	source(source_code)

	var.file = sprintf("%sBCSneg", calc_temp)

	if (!file.exists(var.file)) {

		EBWBCS5 = EBWBCS5_calc(source_code)

		bcs_first = BCS_beef
		BCSneg_first = get_ERTable(source_code, bcs_first)[3]

		bcs_second = BCS_beef -2 
		BCSneg_second = get_ERTable(source_code, bcs_second)[3]

		BCSneg = BCSneg_first - BCSneg_second

		dump("BCSneg", file = var.file)
	} else {
		source(var.file)
	}


	return (BCSneg)
}


BCSnegNEL_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBCSnegNEL", calc_temp)

	if (!file.exists(var.file)) {
		BCSneg = BCSneg_calc(source_code)
		BCSnegNEL = BCSneg * 0.82 
		dump("BCSnegNEL", file = var.file)
	} else {
		source(var.file)
	}
	
	return (BCSnegNEL)
}


BCSpos_calc = function(source_code){

	source(source_code)

	var.file = sprintf("%sBCSpos", calc_temp)

	if (!file.exists(var.file)) {
		EBWBCS5 = EBWBCS5_calc(source_code)
		bcs_first = BCS_beef + 2 
		BCSpos_first = get_ERTable(source_code, bcs_first)[3]
		bcs_second = BCS_beef  
		BCSpos_second = get_ERTable(source_code, bcs_second)[3]
		BCSpos = BCSpos_first - BCSpos_second
		dump("BCSpos", file = var.file)
	} else {
		source(var.file)
	}

	return (BCSpos)
}


BCSposNEL_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sBCSposNEL", calc_temp)

	if (!file.exists(var.file)) {
		BCSpos = BCSpos_calc(source_code)		
		BCSposNEL = BCSpos * 0.644/0.75
		dump("BCSposNEL", file = var.file)
	} else {
		source(var.file)
	}	

	return (BCSposNEL)
}


BCS_BW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBCS_BW", calc_temp)

	if (!file.exists(var.file)) { 

		EBWBCS5 = EBWBCS5_calc(source_code)
		bcs_first = BCS_beef + 2 
		BCS_BW_first = get_ERTable(source_code, bcs_first)[2]

		bcs_second = BCS_beef  
		BCS_BW_second = get_ERTable(source_code, bcs_second)[2]

		BCS_BW = BCS_BW_first - BCS_BW_second
		dump("BCS_BW", file = var.file)

	} else {
		source(var.file)
	}

	return (BCS_BW)
}

NEDLW_calc = function(source_code){

	source(source_code)

	var.file = sprintf("%sNEDLW",calc_temp)

	if (!file.exists(var.file)) {
		NEDLW = 0.5381 * BCS_beef + 3.2855
		dump("NEDLW", file=var.file)
	} else {
		source(var.file)
	}

	return (NEDLW)
}


MEbal_get_to_bodyreserves = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMEbal", calc_temp)

	if (!file.exists(var.file)) {
		source(production_prediction_module)
		MEbal = MEbal_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	
	return(MEbal)
}


DLW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDLW", calc_temp)

	if (!file.exists(var.file)) {
		NEDLW = NEDLW_calc(source_code)		
		MEbal = MEbal_get_to_bodyreserves(source_code)
		if (MEbal >= 0) {
			constant = 0.75
		} else {
			constant = 0.785
		}
		DLW = MEbal * constant / NEDLW
		dump("DLW", file=var.file)
	} else {
		source(var.file)
	}


	return (DLW)
}
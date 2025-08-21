
#===========================================#
# Predicting production calculation module  #
# Date : 2014-10-24                         #
# Written by Hyesun Park                    #
#===========================================#



MEmr_get_to_production = function(source_code) {	

	source(source_code)

	var.file = sprintf("%sMEmr", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		MEmr = MEmr_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	
	return (MEmr)
}


MEgr_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEgr", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MEgr = MEgr_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	
	return (MEgr)
}


MEpreg_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEpreg", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MEpreg =  MEpreg_calc(source_code)
	} else {
		source(var.file)
	}
	
	return (MEpreg)
}


MEmm_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEmm", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MEmm = MEmm_calc (source_code)
	} else {
		source(var.file)
	}

	return (MEmm)
}


MElact_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMElact", calc_temp)

	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
	 	MElact = MElact_calc (source_code)
	} else {
		source(var.file)
	}
	
 	return (MElact)
}


MEreq_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEreq", calc_temp)

	if (!file.exists(var.file)) {
		MEmr = MEmr_get_to_production(source_code)
		MEgr = MEgr_get_to_production(source_code)
		MEpreg = MEpreg_get_to_production(source_code)
		MEmm = MEmm_get_to_production(source_code)
		MElact = MElact_get_to_production(source_code)
		MEreq = sum(MEmr, MEgr, MEpreg, MEmm, MElact)
		dump("MEreq", file = var.file)
	} else {
		source(var.file)
	}

	return (MEreq)
}


MEsup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEI", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		MEI = MEI_calc (source_code)
	} else {
		source(var.file)
	}

	MEsup = MEI 
	
	return (MEsup)
}


MEbal_calc = function(source_code) {

	source(source_code)	

	var.file = sprintf("%sMEbal", calc_temp)

	if (!file.exists(var.file)) {
		MEreq = MEreq_calc(source_code)
		MEsup = MEsup_calc(source_code)
		MEbal = MEsup - MEreq 
		dump("MEbal", file = var.file)
	} else {
		source(var.file)
	}

	return(MEbal)
}


MPm_get_to_production = function(source_code) {

	source (source_code)

	var.file = sprintf("%sMPm", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		MPm = MPm_calc_others(source_code)
	} else {
		source(var.file)
	}
	
	return(MPm)
}


MPg_get_to_production = function(source_code){

	source(source_code)

	var.file = sprintf("%sMPg", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MPg = MPg_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	
	return (MPg)
}


MPpreg_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPpreg", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MPpreg = MPpreg_calc(source_code)
	} else {
		source(var.file)
	}

	return (MPpreg)
}


MPmm_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPmm", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MPmm = MPmm_calc (source_code)
	} else {
		source(var.file)
	}

	return (MPmm)
}


MPlact_get_to_production  = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPlact", calc_temp)

	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
		MPlact = MPlact_calc (source_code)
	} else {
		source(var.file)
	}

	return (MPlact)
}


MPreq_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPreq", calc_temp)

	if (!file.exists(var.file)) {
		MPm = MPm_get_to_production(source_code)
		MPg = MPg_get_to_production(source_code)
		MPmm = MPmm_get_to_production(source_code)
		MPpreg = MPpreg_get_to_production(source_code)
		MPlact = MPlact_get_to_production(source_code)
		MPreq = sum(MPm, MPg, MPpreg, MPmm, MPlact)
	} else {
		source(var.file)
	}
	
	return (MPreq)
}


MPsup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPavail", calc_temp)

	if (!file.exists(var.file)) {
		source(rumen_model_module)
		MPavail = MPavail_get(source_code)
	} else {
		source(var.file)
	}

	MPsup = MPavail 

	return (MPsup)
}


MPbal_calc = function(source_code)  {

	source(source_code)

	var.file = sprintf("%sMPbal", calc_temp)

	if (!file.exists(var.file)) {
		MPsup = MPsup_calc(source_code)		
		MPreq = MPreq_calc(source_code)
		MPbal = MPsup - MPreq 
		dump("MPbal", file = var.file)
	} else {
		source(var.file)
	}

	return (MPbal)
}


MEI_get_to_production = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMEI", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		MEI = MEI_calc(source_code)
	} else {
		source(var.file)
	}

	return (MEI)
}

MEC_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEC", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		MEC = MEC_calc(source_code)
	} else {
		source(var.file)
	}

	return (MEC)	
}


NEma_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEma", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEma = NEma_total_calc(source_code)
	} else {
		source(var.file)
	}

	return (NEma)
}


NEga_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEga", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEga = NEga_total_calc(source_code)
	} else {
		source(var.file)
	}

	return (NEga)
}


NEla_get_to_production = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEl", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEla = NEl_total_calc(source_code)
	} else {
		source(var.file)
		NEla = NEl
	}
	
	return (NEla)
}


REM_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sREM", calc_temp)

	if (!file.exists(var.file)) {
		MEC = MEC_get_to_production(source_code)
		NEma = NEma_get_to_production(source_code)
		REM = NEma/MEC
		dump("REM", file = var.file)
	} else {
		source(var.file)
	}


	return (REM)
}


REM_calc_for_others = function(source_code) {

	REM = REM_calc(source_code)

	return (REM)
}


REG_calc = function(MEC, NEga) {

	source(source_code)

	var.file = sprintf("%sREG", calc_temp)

	if (!file.exists(var.file)) {
		NEga = NEga_get_to_production(source_code)
		MEC = MEC_get_to_production(source_code)
		REG = NEga/MEC
		dump("REG", file = var.file)
	} else {
		source(var.file)
	}
	
	return (REG)
}



REL_calc = function(MEC, NEla) {

	source(source_code)

	var.file = sprintf("%sREL", calc_temp)

	if (!file.exists(var.file)) {
		NEla = NEla_get_to_production(source_code)		
		MEC = MEC_get_to_production(source_code)
		REL = NEla/MEC 
		dump("REL", file = var.file)
	} else {
		source(var.file)
	}	

	return (REL)
}


MEproduction_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEproduction_avail", calc_temp)

	if (!file.exists(var.file)) {
		MEmr = MEmr_get_to_production(source_code)
		MEI = MEI_get_to_production(source_code)
		MEproduction_avail = MEI - MEmr
		dump("MEproduction_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (MEproduction_avail)
}


MEpreg_mm_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMPpreg_mm", calc_temp)

	if (!file.exists(var.file)) {
		MEpreg = MEpreg_get_to_production(source_code)
		MEmm = MEmm_get_to_production(source_code)
		MPpreg_mm = MEpreg + MEmm
		dump("MPpreg_mm", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MPpreg_mm) 
}


MEgandl_avail_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMEgandl_avail", calc_temp)

	if (!file.exists(var.file)) {
		MEproduction_avail = MEproduction_avail_calc(source_code)
		MEpreg = MEpreg_get_to_production(source_code)
		MEgandl_avail = MEproduction_avail - MEpreg 
		dump("MEgandl_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (MEgandl_avail)
}


MElact_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMElact_avail", calc_temp)

	if (!file.exists(var.file)) {
		MEgandl_avail = MEgandl_avail_calc(source_code)
		MEg_avail = MEg_avail_calc(source_code)
		MElact_avail = MEgandl_avail - MEg_avail 
		dump("MElact_avail", file = var.file)
	} else {
		source(var.file)
	}


	return (MElact_avail)
}


MEg_avail_calc = function(source_code) {

	source (source_code)

	var.file = sprintf("%sMEg_avail", calc_temp)

	if (!file.exists(var.file)) {
		MEgandl_avail = MEgandl_avail_calc(source_code)
		MElact = MElact_get_to_production(source_code)
		if (target_ADG > 0) {
			MEg_avail = max((MEgandl_avail - MElact), 0) 
		} else {
			MEg_avail = 0 
		}
		dump("MEg_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (MEg_avail)
}


NEg_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEg_avail",calc_temp)

	if (!file.exists(var.file)) {
		MEg_avail = MEg_avail_calc(source_code)
		REG = REG_calc(source_code)
		NEg_avail = MEg_avail * REG
		dump("NEg_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (NEg_avail)
}


MEgain_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEgain", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)	
		EqSBW = EqSBW_calc(source_code)
		NEg_avail = NEg_avail_calc(source_code)
		if (sex==1 | sex==2) {
			MEgain = 22.108*(EqSBW^(-0.8287)*(NEg_avail^1.105))
		} else {
			MEgain = 21.67*(EqSBW^(-0.8287)*(NEg_avail^1.105))
		}
		dump("MEgain", file = var.file)
	} else {
		source(var.file)
	}
		
	return (MEgain)
}


MEgain_calc_export_for_others = function(source_code) {

	MEgain = MEgain_calc(source_code)

	return (MEgain)
}


MEgain_prev_calc = function(source_code)  {

	source(source_code)

	var.file = sprintf("%sMEgain_prev", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)	
		EqEBW = EqEBW_calc(source_code)
		NEg_avail = NEg_avail_calc(source_code)
		MEgain_prev = 13.91 * (EqEBW^(-0.6837)) * (NEg_avail^0.9116)
		dump("MEgain_prev", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MEgain_prev)
}


MEmilk_calc = function(source_code) {

	source (source_code)

	var.file =sprintf("%sMEmilk", calc_temp)

	if (!file.exists(var.file)) {
		MElact_avail = MElact_get_to_production(source_code)
		MEmilk = MElact_avail * 0.644 / (0.3512+0.0962*MF)
		dump("MEmilk", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MEmilk)
}


MPproduction_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPproduction_avail", calc_temp)

	if (!file.exists(var.file)) {
		MPsup = MPsup_calc(source_code)
		MPm = MPm_get_to_production(source_code)
		MPproduction_avail = MPsup - MPm
		dump("MPproduction_avail", file = var.file)
	} else {
		source(var.file)
	}	

	return (MPproduction_avail)
}


MPpreg_mm_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPpreg_mm", calc_temp)

	if (!file.exists(var.file)) {
		MPpreg = MPpreg_get_to_production(source_code)
		MPmm = MPmm_get_to_production(source_code)
	 	MPpreg_mm = MPpreg + MPmm 
	 	dump("MPpreg_mm", file = var.file)
	} else {
		source(var.file)
	}

 	return (MPpreg_mm)
}


MPgandl_avail_calc  = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPgandl_avail", calc_temp)

	if (!file.exists(var.file)) {
		MPproduction_avail = MPproduction_avail_calc(source_code)
		MPpreg = MPpreg_get_to_production(source_code)
		MPgandl_avail = MPproduction_avail - MPpreg	
		dump("MPgandl_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (MPgandl_avail)
}


MPg_avail_calc = function(source_code) {

	source (source_code)

	var.file = sprintf("%sMPg_avail", calc_temp)

	if (!file.exists(var.file)) {
		MPgandl_avail = MPgandl_avail_calc(source_code)
		MPlact = MPlact_get_to_production(source_code)

		if (target_ADG > 0 ) {
			MPg_avail = max(MPgandl_avail - MPlact, 0)
		} else {
			MPg_avail = 0
		}
		dump("MPg_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (MPg_avail)
}


MPlact_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPlact_avail", calc_temp)

	if (!file.exists(var.file)) {
		MPgandl_avail = MPgandl_avail_calc(source_code)
		MPg_avail = MPg_avail_calc(source_code)
		MPlact_avail = MPgandl_avail - MPg_avail
		dump("MPlact_avail", file = var.file)
	} else {
		source(var.file)
	}

	return(MPlact_avail)
}


NPg_avail_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNPg_avail", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		EqSBWg = EqSBWg_calc (source_code)
		MPg_avail = MPg_avail_calc(source_code)
		NPg_avail = MPg_avail * (0.834 - EqSBWg*0.00114)
		dump("NPg_avail", file = var.file)
	} else {
		source(var.file)
	}
	
	return (NPg_avail)
}


MPgain_calc  = function(source_code){

	source(source_code)

	var.file = sprintf("%sMPgain", calc_temp)

	if (!file.exists(var.file)) {
		NPg_avail = NPg_avail_calc(source_code)
		NEg_avail = NEg_avail_calc(source_code)
		if (NPg_avail == 0) {
			MPgain = 0
		} else {
			MPgain = (NPg_avail + 29.4 * NEg_avail)/268
		}
		dump("MPgain", file = var.file)
	} else {
		source(var.file)
	}

	return (MPgain)
}



MPgain_calc_export_for_others = function(source_code) {

	MPgain = MPgain_calc (source_code)

	return (MPgain)
}


MPmilk_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPmilk", calc_temp)

	if (!file.exists(var.file)) {
		MPlact_avail = MPlact_avail_calc(source_code)
		MPmilk = MPlact_avail * 0.65 / (10*PP)
		dump("MPmilk", file = var.file)
	} else {
		source(var.file)
	}

	return (MPmilk)
}


MEreq_calc_for_others = function(source_code) {

	MEreq = MEreq_calc (source_code)

	return (MEreq)
}


MPreq_calc_for_others = function(source_code) {

	MPreq = MPreq_calc (source_code)

	return (MPreq)
}


MEbal_calc_for_others = function(source_code) {

	MEbal = MEbal_calc(source_code)

	return (MEbal)
}

MPbal_calc_for_others = function(source_code) {

	MPbal = MPbal_calc(source_code)

	return (MPbal)
}
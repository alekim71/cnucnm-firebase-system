#======================================================#
# Growth and pregnancy requirements calculation module #
# Date : 2014-10-21                                    #
# Written by Hyesun Park                               #
#======================================================#


SRW_calc = function (source_code) {

	# SRW Setting  : 400(22%), 435(25%), 462(27%), 478(28%)

	source(source_code)

	var.file = sprintf("%sSRW", calc_temp)

	if (!file.exists(var.file)) {
		SRW = 478	
		dump("SRW", file = var.file)
	} else {
		source(var.file)
	}

	return (SRW)
}


EBW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEBW", calc_temp)

	if (!file.exists(var.file)) {
		EBW = SBW * 0.891
		dump("EBW", file = var.file)
	} else {
		source(var.file)
	}

	return (EBW)
}


EqSBW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqSBW", calc_temp)

	if (!file.exists(var.file)) {
		SRW = SRW_calc(source_code)
		EqSBW = (SBW*SRW)/AFBW
		dump("EqSBW", file = var.file)
	} else {
		source(var.file)
	}

	return (EqSBW)
}


EqEBW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqEBW", calc_temp)

	if (!file.exists(var.file)) {
		EqSBW = EqSBW_calc(source_code)
		EqEBW = 0.891 * EqSBW
		dump("EqEBW", file = var.file)
	} else {
		source(var.file)
	}

	return (EqEBW)
}


TargetSWG_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTargetSWG", calc_temp)

	if (!file.exists(var.file)) {
		TargetSWG = target_ADG
		dump("TargetSWG", file = var.file)
	} else {
		source(var.file)
	}

	return (TargetSWG)
}


TargetEBG_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTargetEBG", calc_temp)

	if (!file.exists (var.file)) {
		TargetSWG = TargetSWG_calc(source_code)
		TargetEBG = TargetSWG * 0.956
		dump("TargetEBG", file = var.file)
	}  else {
		source(var.file)
	}

	return (TargetEBG)
}


NEgr_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEgr", calc_temp)

	if (!file.exists (var.file)) {
		EqSBW = EqSBW_calc(source_code)
		TargetSWG = TargetSWG_calc(source_code)
		if (sex==1|sex==2) {
			NEgr = 0.0606*EqSBW^0.75*TargetSWG^0.905
		} else {
			NEgr = 0.0618*EqSBW^0.75*TargetSWG^0.905
		}
		dump("NEgr", file = var.file)
	} else {
		source(var.file)
	}


	return (NEgr)
}


REG_get_to_growth = function (source_code) {
	
	source(source_code)

	var.file = sprintf("%sREG", calc_temp)

	if (!file.exists(var.file)) {
		source(production_prediction_module)
		source(intestinal_model_module)
		MEC = MEC_calc(source_code)
		NEga = NEga_total_calc(source_code)
		REG = REG_calc (MEC, NEga)
		dump("REG", file = var.file)
	} else {
		source(var.file)
	}

	return (REG)
}


MEgr_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEgr", calc_temp)

	if (!file.exists(var.file)) {
		NEgr = NEgr_calc(source_code)
		REG = REG_get_to_growth(source_code)
		MEgr = NEgr/REG
		dump("MEgr", file = var.file)
	} else {
		source(var.file)
	}

	return (MEgr)
}


NPg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNPg", calc_temp)

	if (!file.exists(var.file)) {
		TargetSWG = TargetSWG_calc(source_code)
		NEgr = NEgr_calc(source_code)
		if (TargetSWG==0) {
			NPg = 0
		} else {
			NPg = TargetSWG*(268-29.4*(NEgr/TargetSWG))
		}
		dump("NPg", file = var.file)
	} else {
		source(var.file)
	}


	return (NPg)
}


EqSBWg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqSBWg", calc_temp)

	if (!file.exists(var.file)) {
		EqSBW = EqSBW_calc(source_code)
		if (EqSBW >= 478) {
			EqSBWg = 478
		} else {
			EqSBWg = EqSBW		
		}
		dump("EqSBWg", file = var.file)
	} else {
		source(var.file)
	}

	return (EqSBWg)
}


MPg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPg", calc_temp)

	if (!file.exists(var.file)) {
		NPg = NPg_calc(source_code)
		EqSBWg = EqSBWg_calc(source_code)
		MPg = NPg/(0.834-EqSBWg*0.00114)
		dump("MPg", file = var.file)

	} else {
		source(var.file)
	}

	return (MPg)
}


MPmm_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPmm", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 259) {
			MPmm = 276.7
		} else {
			MPmm = 0 
		}
		dump("MPmm", file = var.file)
	} else {
		source(var.file)
	}
 

	return (MPmm)	
}


MEmm_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sMEmm", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEga = NEga_total_calc(source_code)
		if (DIP > 259) {
			MEmm = 1 /NEga
		} else {
			MEmm = 0 
		}
		dump("MEmm", file = var.file)
	} else {
		source(var.file)
	}

	return (MEmm)
}


TPW_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sTPW", calc_temp)

	if (!file.exists(var.file)) {
		if (breed_type == 1 ) {
			TPW = 0.6 * AFBW
		} else {
			TPW = 0.55 * AFBW
		}
		dump("TPW", file = var.file)
	} else {
		source(var.file)
	}

	return (TPW)
}


TCA_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTCA", calc_temp)

	if (!file.exists(var.file)) {
		TCA = TCAm * 30 
		dump("TCA", file = var.file)
	} else {
		source(var.file)
	}

	return (TCA)
}


TPA_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTPA", calc_temp)

	if (!file.exists(var.file)) {
		TCA = TCA_calc(source_code)
		TPA = TCA - 280
		dump("TPA", file = var.file)
	} else {
		source(var.file)
	}

	return (TPA)
}


Tage_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTage", calc_temp)

	if (!file.exists(var.file)) {
		Tage = age * 30  
		dump("Tage", file = var.file)
	} else {
		source(var.file)
	}

	return (Tage)
}


BPADG_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBPADG", calc_temp)

	if (!file.exists(var.file)) {
		TPW = TPW_calc(source_code)
		TPA = TPA_calc(source_code)
		Tage = Tage_calc(source_code)
		BPADG = (TPW - SBW)/(TPA - Tage)
		dump("BPADG", file = var.file)
	} else {
		source(var.file)
	}

	return (BPADG)
}


TCW_1_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTCW_1", calc_temp)

	if (!file.exists(var.file)) {
		if (breed_type == 3) {
			TCW_1 = AFBW * 0.85
		} else {
			TCW_1 = AFBW * 0.8 
		}
		dump("TCW_1", file = var.file)
	} else {
		source(var.file)
	}

	return (TCW_1)
}


TCW_2_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sTCW_2", calc_temp) 

	if (!file.exists(var.file)) {
		TCW_2 = AFBW * 0.92 
		dump("TCW_2", file = var.file)
	} else {
		source(var.file)
	}

	return (TCW_2)
}


TCW_3_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTCW_3", calc_temp)

	if (!file.exists(var.file)) {
		TCW_3 = AFBW * 0.96 
		dump("TCW_3", file = var.file)
	} else {
		source(var.file)
	}

	return (TCW_3)
}


TCW_4_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sTCW_4", calc_temp)

	if (!file.exists(var.file)) {
		TCW_4 = AFBW
		dump("TCW_4", file = var.file)
	} else {
		source(var.file)
	}

	return (TCW_4)
}


DIP_t_calc = function(source) {

	source(source_code)

	var.file = sprintf("%sDIP_t", calc_temp) 

	if (!file.exists(var.file)) {
		DIP_t = DIP
		dump("DIP_t", file = var.file)
	} else {
		source(var.file)
	}

	return (DIP_t)
}


APADG_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sAPADG", calc_temp) 

	if (!file.exists(var.file)) {
		TCW_1 = TCW_1_calc(source_code)
		APADG = (TCW_1 - SBW)/(280 - DIP)
		dump("APADG", file = var.file)
	} else {
		source(var.file)
	}

	return (APADG)
}


DtoP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDtoP", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 0) {
			DtoP = 280-DIP
		} else {
			DtoP = CIm*30 - DIM
		}
		dump("DtoP", file = var.file)
	} else {
		source(var.file)
	}

	return (DtoP)
}


ACADG_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sACADG", calc_temp)

	if (!file.exists(var.file)) {
		DtoP = DtoP_calc(source_code)
		if (lact_no >= 4) {
			ACADG = 0
		} else if (lact_no == 0) {
			ACADG = (387 - SBW)/DtoP
		} else if (lact_no == 1) {
			ACADG = (419 - SBW)/DtoP
		} else if (lact_no == 2)  {
			ACADG = (437 - SBW)/DtoP
		} else if (lact_no == 3) {
			ACADG = (455 - SBW)/DtoP
		} else {
			ACADG = Inf
		}
		dump("ACADG", file = var.file)
	} else {
		source(var.file)
	}

	return (ACADG)
}


breed_target_ADG_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sbreed_target_ADG", calc_temp)

	if (!file.exists(var.file)) {
		BPADG = BPADG_calc(source_code)
		APADG = APADG_calc(source_code)
		ACADG = ACADG_calc(source_code)
		if (sex==3) {
			if (DIP==0) {
				breed_target_ADG = BPADG
			} else {
				breed_target_ADG = APADG
			} 	
		} else {
			if (sex == 4) {
				breed_target_ADG = ACADG
			} else {
				breed_target_ADG = 0 
			}
		}
		dump("breed_target_ADG", file = var.file)
	} else {
		source(var.file) 
	}

	return (breed_target_ADG)
}



ADGpreg_k_calc = function (source_code) {

	if (DIP < 190)  {
		ADGpreg_k = 100
	} else {
		ADGpreg_k = 664
	} 

	return (ADGpreg_k)
}


ADGpreg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sADGpreg", calc_temp)

	if (!file.exists(var.file)) {
		ADGpreg_k = ADGpreg_k_calc(source_code)
		if (DIP > 0) {
			if (breed_type==3) {
		 		ADGpreg = CBW/45*ADGpreg_k
		 	} else {
		 		ADGpreg = CBW*(18.28*(0.02-0.0000286 * DIP)*exp(0.02 * DIP - 0.0000143 * DIP^2))
		 	}
		 } else {
		 	ADGpreg = 0 
		 }
		dump("ADGpreg", file = var.file)
	} else {
		source(var.file)
	}

	 return (ADGpreg)
}


CpW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCpW", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP>190) {
			if (breed_type ==3) {
				CpW = (CBW/45)*(18+((DIP-190)*0.665))
			} else {
				CpW = (CBW*0.01828)*(exp(0.02 * DIP - 0.0000143*DIP^2))
			} 
		} else {
			CpW = 0 
		}
		dump("CpW", file = var.file)
	} else {
		source(var.file)
	}

	return (CpW)
}


MEpreg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEpreg", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 190) {
			if (breed_type == 3) {
				MEpreg = (CBW/45)*(2*0.00159*DIP-0.0352)/0.14
			} else {
				MEpreg = (CBW*(0.05855-0.0000996*DIP)*exp(0.03233*DIP-0.0000275*DIP^2))/1000/0.13
			}
		} else {
			MEpreg = 0 
		}
		dump("MEpreg", file = var.file)
	} else {
		source(var.file)
	}

	return (MEpreg)
}


MPpreg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPpreg",calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 190) {
			if (breed_type == 3) {
				MPpreg = (CBW/45)*(0.69*DIP-69.2)/0.33
			} else {
				MPpreg = (CBW*(0.001669-0.00000211*DIP)*EXP(0.0278*DIP-0.0000176*DIP^2))*6.25/0.5
			}
		} else {
			MPpreg = 0
		}
		dump("MPpreg", file = var.file)
	} else {
		source(var.file)
	}
	return (MPpreg)
}


MEgr_calc_for_others = function (source_code) {

	MEgr = MEgr_calc (source_code)

	return (MEgr)
}


MPg_calc_for_others = function (source_code) {

	MPg = MPg_calc (source_code)

	return (MPg)
}


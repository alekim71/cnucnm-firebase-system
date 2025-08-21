#===================================#
# Prediction DMI calculation module #
# Date : 2014-10-23                 #
# Written by Hyesun Park            #
#===================================#



DMIpred_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIpred", calc_temp)

	if (!file.exists(var.file)) {
		DMIdry = DMIdry_calc(source_code)
		DMilact = DMIlact_calc(source_code)
		DMIbeefcow = DMIbeefcow_calc(source_code)
		DMIcalf = DMIcalf_calc(source_code)
		DMIyear = DMIyear_calc(source_code)
		if (animal_type == 3) {
			DMIpred = DMIdry
		} else if (animal_type == 2) {
			DMIpred = DMilact
		} else if (animal_type == 0) {
			DMIpred = DMIbeefcow
		} else {
			if (age < 12) {
				DMIpred = DMIcalf
			} else {
				DMIpred = DMIyear 
			}
		}
		dump("DMIpred", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIpred)
}



DMIpred_calc_export_for_other = function(source_code) {

	DMIpred = DMIpred_calc(source_code)

	return (DMIpred)
}


CpW_get_to_intake = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCpW", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		CpW = CpW_calc (source_code)
	} else {
		source(var.file)
	}

	return (CpW)
}


SBWpreg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sSBWpreg", calc_temp)

	if (!file.exists(var.file)) {
		CpW = CpW_get_to_intake(source_code)		
		if (DIP > 0) {
			SBWpreg = SBW-CpW
		} else {
			SBWpreg = SBW
		}
		dump("SBWpreg", file = var.file)
	} else {
		source(var.file)
	}

	return (SBWpreg)
}


 CETI_get_to_intake = function(source_code) {

 	source(source_code)

 	var.file = sprintf("%sCETI", calc_temp)

 	if (!file.exists(var.file)) {
	 	source(maintain_requirement_module)
	 	CETI = CETI_calc(source_code)
 	} else {
 		source(var.file)
 	}

 	return (CETI)
 }


DMINC_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMINC",calc_temp)

	if (!file.exists(var.file)) {
		CETI = CETI_get_to_intake(source_code)
		DMINC = (119.62-0.9708*CETI)/100
		dump("DMINC", file = var.file)
	} else {
		source(var.file)
	}

	return (DMINC)
}


DMIAF_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIAF", calc_temp)

	if (!file.exists(var.file)) {
		DMINC = DMINC_calc(source_code)
		if (Tc <= -20) {
			DMIAF = 1.16
		} else if (Tc <= 20) {
			DMIAF = 1.0433-0.0044*Tc+0.0001*Tc^2
		} else {
			if (NC == 1) {
				DMIAF = (1-DMINC)*0.75+DMINC
			} else {
				DMIAF = DMINC
			}
		dump("DMIAF", file = var.file)
		}
	} else {
		source(var.file)
	}

	return (DMIAF)
}


MudDMI_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMudDMI", calc_temp)

	if (!file.exists(var.file)) {
		MudDMI =1-0.01*MUD
		dump("MudDMI", file = var.file)
	} else {
		source(var.file)
	}

	return (MudDMI) 
}


Preg_adj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPreg_adj", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 259) {
			Preg_adj = 0.8
		} else {
			Preg_adj = 1
		}
		dump("Preg_adj", file = var.file)
	} else {
		source(var.file)
	}

	return (Preg_adj)
}


DMIdry_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIdry", calc_temp)

	if (!file.exists(var.file)) {
		SBWpreg = SBWpreg_calc(source_code)
		DMIAF = DMIAF_calc(source_code)
		MudDMI = MudDMI_calc(source_code)
		Preg_adj = Preg_adj_calc(source_code)
		DMIdry = 0.02*SBWpreg*DMIAF*MudDMI*Preg_adj
		dump("DMIdry", file = var.file)
	} else {
		source(var.file)
	}
	return (DMIdry)
}


Milkbeef_get_to_intake = function(source_code){

	source(source_code)

	var.file = sprintf("%sMilkbeef", calc_temp)

	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
		Milkbeef = Milkbeef_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	
	return (Milkbeef)
}


Milkadj_get_to_intake = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMilkadj", calc_temp)

	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
		Milkadj = Milkadj_calc (source_code)
	} else {
		source(var.file)
	}
	
	return (Milkadj)
}


FCM_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFCM", calc_temp)

	if (!file.exists(var.file)) {
		Milkadj = Milkadj_get_to_intake(source_code)
		FCM = 0.4*Milkadj+15*Milkadj*MF/100
	} else { 
		source(var.file)
	}

	return (FCM)
}


dietndf_get_to_intake = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdietndf", calc_temp)

	if (!file.exists(var.file)) {
		source(rumen_model_module)
		dietndf = dietndf_calc (source_code)
	} else {
		source(var.file)
	}

	return (dietndf)
}


PKMK_calc = function() {

	PKMK = 2 

	return (PKMK)
}
 
P_lag_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sP_lag", calc_temp)

	if (!file.exists(var.file)) {
		P_lag_values = c(2.36, 2.36, 3.67)
		PKMK = PKMK_calc() 
		P_lag = P_lag_values[PKMK]
		dump("P_lag", file = var.file)
	} else {
		source(var.file)
	}
	
	return (P_lag)
}


Lag_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLag", calc_temp)

	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
		WOL = WOL_calc(source_code) # lactation req 
		PKMK = PKMK_calc()
		P_lag = P_lag_calc(source_code)
		if (WOL < 16) {
			Lag = 1-exp(-(0.564-0.124*PKMK)*(WOL+P_lag))
		} else {
			Lag = 1 
		}
		dump("Lag", file = var.file)
	} else {
		source(var.file)
	}

	return (Lag)
}


NEma_get_to_intake = function(source_code) {

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


dual_milk_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdual_milk", calc_temp)

	if (!file.exists(var.file)) {
		Milkadj = Milkadj_get_to_intake(source_code)
		if (Milkadj > 15) {
			dual_milk = 1.7
		} else {
			dual_milk = 0 
		}
		dump("dual_milk", file = var.file)
	} else {
		source(var.file)
	}

	return (dual_milk)
}


DMIlact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIlact", calc_temp)

	if (!file.exists(var.file)) {
		FCM = FCM_calc(source_code)
		dietndf = dietndf_get_to_intake(source_code)
		DMIAF = DMIAF_calc(source_code)
		MudDMI = MudDMI_calc(source_code)
		Lag = Lag_calc(source_code)
		NEma = NEma_get_to_intake(source_code)
		dual_milk = dual_milk_calc(source_code)

		if (breed_type == 3) {
			DMIlact = (4.103+0.112*FBW^0.75+0.284*FCM-0.119*dietndf) * DMIAF*MudDMI*Lag
		} else if (breed_type==2) {
				DMIlact = FBW^0.75*(0.1462*NEma-0.0517*NEma^2-0.0074) + 0.305*FCM + dual_milk
		} else {
			DMIlact = 0
		}
		dump("DMIlact", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIlact)
}


NEma_div_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEma_div", calc_temp)

	if (!file.exists(var.file)) {
		NEma = NEma_get_to_intake(source_code)
		if (NEma < 1) {
			NEma_div = 0.95
		} else {
			NEma_div = NEma
		}
		dump("NEma_div", file = var.file)
	} else {
		source(var.file)
	}

	return (NEma_div)
}


Beefcow_preg_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBeefcow", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 94) {
			Beefcow_preg = 0.04631
		} else {
			Beefcow_preg = 0.0384 
		}
		dump("Beefcow_preg", file = var.file)
	} else {
		source(var.file)
	}

	return (Beefcow_preg)
}


DMIbeefcow_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIbeefcow", calc_temp)

	if (!file.exists(var.file)) {
		NEma = NEma_get_to_intake(source_code)
		Beefcow_preg = Beefcow_preg_calc(source_code)
		DMIAF = DMIAF_calc(source_code)
		MudDMI = MudDMI_calc(source_code)
		Milkadj = Milkadj_get_to_intake(source_code)
		NEma_div = NEma_div_calc(source_code)
		DMIbeefcow = SBW^0.75*((0.04997*NEma^2+Beefcow_preg)/NEma_div)*DMIAF*MudDMI+0.2*Milkadj
		dump("DMIbeefcow", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIbeefcow)
}


BI_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBI", calc_temp)

	if (!file.exists(var.file)) {
		if (breed_type==3){
			BI = 1.08
		} else if (breed_type == 2) {
			BI = 1.04
		} else {
			BI = 1 
		}
		dump("BI", file = var.file)
	} else {
		source(var.file)
	}

	return (BI)
}


EqSBW_get_to_intake = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqSBW", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		EqSBW = EqSBW_calc(source_code)
	} else {
		source(var.file)
	}

	return (EqSBW)

}


BFAT_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBFAT", calc_temp)

	if (!file.exists(var.file)) {
		EqSBW = EqSBW_get_to_intake(source_code)
		if (EqSBW <= 350) {
			BFAT = 1
		} else if (350 < EqSBW & EqSBW <=400) {
			BFAT = 0.97
		} else if (400 < EqSBW & EqSBW <=450) {
			BFAT = 0.9
		} else if (450 < EqSBW & EqSBW <=500) {
			BFAT = 0.82
		} else if (500 < EqSBW & EqSBW <=550) {
			BFAT = 0.73
		} else if (550 < EqSBW) {
			BFAT = 0.73
		} else {
			BFAT = Inf
		}
		dump("BFAT", file = var.file)
	} else {
		source(var.file)
	}

	return (BFAT)
}


ADTV_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sADTV", calc_temp)

	if (!file.exists(var.file)) {
		if (additive == 3 | additive==4) {
			ADTV = 1
		} else {
			ADTV = 0.94
		}
		dump("ADTV", file = var.file)
	} else {
		source(var.file)
	}
	
	return (ADTV)
}


DMIadj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIadj", calc_temp)

	if (!file.exists(var.file)) {
		BI = BI_calc(source_code)
		BFAT = BFAT_calc(source_code)
		#ADTF = ADTV_calc(source_code)
		ADTV = ADTV_calc(source_code)

		if (animal_type == 4) {
			DMIadj = 1
		} else {
			DMIadj = BI*BFAT*ADTV
		}
		dump("DMIadj", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIadj)
}


DMIcalf_calc = function(source_code) {

	source(source_code)

	var.file  = sprintf("%sDMIcalf", calc_temp)

	if (!file.exists(var.file)) {
		NEma = NEma_get_to_intake(source_code)
		DMIadj = DMIadj_calc(source_code)
		DMIAF = DMIAF_calc(source_code)
		NEma_div = NEma_div_calc(source_code)
		MudDMI = MudDMI_calc(source_code)
		DMIcalf = SBW^0.75*((0.2435*NEma-0.0466*NEma^2-0.1128)/NEma_div)*DMIadj*DMIAF*MudDMI
		dump("DMIcalf", file = var.file)
	} else {
		source(var.file)
	}
	
	return (DMIcalf)
}


DMIyear_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMIyear", calc_temp) 

	if (!file.exists(var.file)) {
		SBWpreg = SBWpreg_calc(source_code)
		NEma = NEma_get_to_intake(source_code)
		DMIadj = DMIadj_calc(source_code)
		DMIAF = DMIAF_calc(source_code)
		MudDMI = MudDMI_calc(source_code)
		Preg_adj = Preg_adj_calc(source_code)
		NEma_div = NEma_div_calc(source_code)
		DMIyear = SBWpreg^0.75*((0.2435*NEma-0.0466*NEma^2-0.0869)/NEma_div)*DMIadj*DMIAF*MudDMI*Preg_adj
		dump("DMIyear", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIyear)
}

#=============================================#
# Maintenancy requirements calculation module #
# Date : 2014-10-20                           #
# Written by Hyesun Park                      #
#=============================================#

FHP_calc = function(source_code)  {

	source(source_code)

	var.file = sprintf("%sFHP", calc_temp) 

	if (!file.exists(var.file)) {

		if (animal_type == 2 | animal_type ==3) {
			FHP = 0.073
		} else if (animal_type ==4) {
			FHP = 0.078
		} else if (breed_type==4 & sex == 2) {
			FHP = 0.078
		} else {
			FHP = 0.07
		} 
		dump("FHP", file = var.file)
	} else {
		source(var.file)
	}
	return (FHP)
}


COMP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCOMP", calc_temp)

	if (!file.exists(var.file)) {
		COMP = 0.8 + (BCS_beef-1) * 0.05 
		dump("COMP", file = var.file)
	} else {
		source(var.file)
	}

	return (COMP)
}


NEmrcs_calc = function (source_code)  {

	source(source_code)

	var.file = sprintf('%sNEmrcs', calc_temp)

	if (!file.exists(var.file)) {

		MErcs = MErcs_calc(source_code)
		NEma = NEma_get_to_maintain(source_code)
		ME = ME_get_to_maintain(source_code)
		NEmrcs = MErcs * NEma / ME
		dump("NEmrcs", file = var.file)
	} else {
		source(var.file)
	}

	return (NEmrcs)
}


REa_calc = function(source_code) {

	source(source_code)

	var.file = sprintf('%sREa', calc_temp)

	if (!file.exists(var.file)) {

		DMI = DMI_get_from_rumen(source_code)
		Im = Im_calc(source_code)
		NEga = NEga_get_to_maintain(source_code)

		if (animal_type == 1 | animal_type == 4) {
			REa = (DMI-Im)*NEga
		} else {
			REa = 0 
		}
		dump("REa", file = var.file)
	} else {
		source(var.file)
	}

	return (REa)
}


NEmr_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEmr", calc_temp)

	if (!file.exists (var.file)) {
		FHP = FHP_calc(source_code)
		COMP = COMP_calc(source_code)
		Temp_adj = Temp_adj_calc(source_code)
		ACT = ACT_calc(source_code) 
		NEmrcs = NEmrcs_calc(source_code)
		NEmrhs = NEmrhs_calc(source_code)
		NEmr = (((SBW^0.75)*((FHP*COMP)+Temp_adj))+ACT+NEmrcs)*NEmrhs
		dump("NEmr", file = var.file)
	} else {
		source(var.file)
	}

	return (NEmr)
}


MEmr_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMEmr", calc_temp)

	if (!file.exists(var.file)) {
		MEmrb = MEmrb_calc(source_code)
		UreaCost = UreaCost_calc(source_code)
		MEmr = MEmrb + UreaCost		
		dump("MEmr", file = var.file)
	} else {
		source(var.file)
	}

	return (MEmr)
}


PETI_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sPETI", calc_temp)

	if (!file.exists(var.file)) {
		if (Tp > 20) {
			PETI = 27.88-(0.456*Tp)+(0.010754*Tp^2)-(0.4905*RHP)+(0.00088*RHP^2)+(1.1507*1000/3600*WS)-(0.126447*(1000/3600*WS)^2)+(0.019876*Tp*RHP)-(0.046313*Tp*1000/3600*WS)+(0.4167*HRS) 
		} else { 
			PETI = Tp 
		}
		dump("PETI", file = var.file)
	} else {
		source(var.file)
	}

	return (PETI)
}


Temp_adj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTemp_adj", calc_temp)

	if (!file.exists(var.file)) {
		PETI = PETI_calc(source_code)
		Temp_adj = ((88.426-(0.758*PETI)+(0.0116*PETI^2))-77)/1000
		dump("Temp_adj", file = var.file)
	} else {
		source(var.file)
	}

	return (Temp_adj)
}


ACT_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sACT", calc_temp)

	if (!file.exists(var.file)) {
		ACT = (0.1*standing_hour+0.062*position_change+0.621*flat_distance/1000+6.69*slop_distance/1000)*FBW/1000
		dump("ACT", file = var.file)
	} else {
		source(var.file)
	}

	return (ACT)
}


TI_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sTI", calc_temp)

	if (!file.exists(var.file)) {

		if (age < 1 ) {
			TI = 22.5 
		} else if ( 1 <= age  & age < 6 ) {
			TI = 5.1875 
		} else if (6 <= age & age < 12 ) {
			TI = 5.1875+(0.3125*BCS_beef)
		} else { 
			TI = 5.25+(0.75*BCS_beef)
		} 
		dump("TI", file = var.file)
	} else {
		source(var.file)
	}
	
	return (TI)
}



MudME_calc = function(source_code) {

	source(source_code) 

	var.file = sprintf("%sMudME", calc_temp)

	if (!file.exists(var.file)) {
		if (HCcode > 2 ) {
			MudME = 0.8 - (HCcode - 2)*0.3
		} else {
			MudME = 1 - (HCcode -1)*0.2 
		}
		dump("MudME", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MudME)
}


HideME_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sHideME", calc_temp)

	if (!file.exists(var.file)) {
		HideME = 0.8 + (HIDE-1) * 0.2 
		dump("HideME", file = var.file)
	} else {
		source(var.file)
	}

	return (HideME)
}


EI_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sEI", calc_temp)

	if (!file.exists(var.file)) {
		MudME = MudME_calc(source_code)
		HideME = HideME_calc(source_code)
		EI = (7.36-0.296*WS+2.55*HAIR)*MudME*HideME
		dump("EI", file = var.file)
	} else {
		source(var.file)
	}

	return (EI) 
}


IN_calc = function(source_code){ 

	source(source_code)

	var.file = sprintf("%sIN", calc_temp)

	if (!file.exists(var.file)) {
		TI = TI_calc(source_code)
		EI = EI_calc(source_code)
		IN = TI + EI 
		dump("IN", file = var.file)
	} else {
		source(var.file)
	}
 
	return (IN)
}


SA_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sSA", calc_temp)

	if (!file.exists(var.file)) {
		SA = 0.09 * SBW ^0.67 		
		dump("SA", file = var.file)
	} else {
		source(var.file)
	}

	return (SA)
}


ME_get_to_maintain = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEC", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		ME = MEC_calc(source_code)		
	} else {
		source(var.file)
		ME = MEC
	}

	return (ME)
}


DMI_get_from_rumen = function(source_code) { 	

	source(source_code)

	var.file = sprintf("%sDMI", calc_temp)

	if (!file.exists(var.file)) {
		source(rumen_model_module)
		DMI = DMI_intake_calc(source_code)
	} else {
		source(var.file)
	}

	return (DMI)
}


NEmrb_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEmrb", calc_temp)

	if (!file.exists(var.file)) {
		FHP = FHP_calc(source_code)		
		COMP = COMP_calc (source_code)
		Temp_adj = Temp_adj_calc(source_code)
		ACT = ACT_calc(source_code)
		NEmrb = ((SBW^0.75*((FHP*COMP)+Temp_adj))+ACT)
		dump("NEmrb", file = var.file)
	} else {

		source(var.file) 
	}

	return (NEmrb)
}


NEma_get_to_maintain = function(source_code) {


	source(source_code)

	var.file = sprintf("%sNEma", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEma = NEma_total_calc(source_code)
	} else {
		source(var.file)
	}
	
	return(NEma)
}


ionophore_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sionophore", calc_temp) 

	if (!file.exists(var.file)) {

		if (additive==2 | additive==4) {
			ionophore = 1
		} else {
			ionophore = 0 
		} 
		dump("ionophore", file = var.file)

	} else {

		source(var.file)
	}


	return (ionophore)
}


ionophore_factor_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sionophore_factor", calc_temp)

	if (!file.exists(var.file)) {
		ionophore = ionophore_calc(source_code)
		if (animal_type==1|animal_type==4) {
			ionophore_factor = max(1,1.12*ionophore)
		} else {
			ionophore_factor = 1
		}	 
		dump("ionophore_factor", file = var.file)
	} else {
		source(var.file)
	}

	return (ionophore_factor)
}


Im_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sIm", calc_temp)

	if (!file.exists(var.file)) {
		NEmrb = NEmrb_calc(source_code)
		NEma = NEma_get_to_maintain(source_code) 
		ionophore_factor = ionophore_factor_calc(source_code)
		Im = NEmrb/(NEma * ionophore_factor)
		dump("Im", file = var.file)
	} else {
		source(var.file)
	}

	return (Im)
}


NEga_get_to_maintain = function (source_code) {

	source(source_code)

	var.file = sprintf("%sNEga", calc_temp)

	if (!file.exists (var.file)) {
		source(intestinal_model_module)
		NEga = NEga_total_calc(source_code)
	} else {
		source(var.file)
	}

	return(NEga)
}


NEla_get_to_maintain = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEl", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		NEla = NEl_total_calc(source_code)
	} else {
		source(var.file)
		NEla = NEl
	}

	return(NEla)
}


NEproduction_calc = function (source_code) { 

	source(source_code)

	var.file = sprintf("%sNEproduction", calc_temp)

	if (!file.exists(var.file)) {
		DMI = DMI_get_from_rumen(source_code)			
		Im = Im_calc(source_code)
		if (animal_type==1 | animal_type==4) {
			NEga = NEga_get_to_maintain(source_code)
			NEproduction = (DMI-Im) * NEga
		} else if (animal_type == 0 | animal_type==2) {
			NEla = NEla_get_to_maintain(source_code)
			NEproduction = (DMI-Im) * NEla
		} else {
			NEma = NEma_get_to_maintain(source_code)
			NEproduction = (DMI-Im) * NEma
		}
		dump("NEproduction", file = var.file)
	} else {
		source(var.file)
	}

	return (NEproduction)
}


HE_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sHE", calc_temp)

	if (!file.exists(var.file)) {
		DMI = DMI_get_from_rumen(source_code)
		NEproduction = NEproduction_calc(source_code)
		SA = SA_calc(source_code)
		ME = ME_get_to_maintain(source_code)
		HE = (ME * DMI - NEproduction)/SA
		dump("HE",file = var.file)
	} else {
		source(var.file)
	}

	return (HE)
}


LCT_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLCT", calc_temp)

	if (!file.exists(var.file)) {
		IN = IN_calc(source_code)
		HE = HE_calc(source_code)
		LCT = 39 - (IN * HE * 0.85) 
		dump("LCT", file = var.file)
	}  else {
		source(var.file)
	}

	return (LCT)
}


MErcs_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMErcs", calc_temp)

	if (!file.exists(var.file)) {
		LCT = LCT_calc (source_code)
		SA = SA_calc(source_code)
		IN = IN_calc(source_code)			
	 	if (LCT > Tc) {
			MErcs = SA*(LCT-Tc) /IN
		} else {
			MErcs = 0
		}	
		dump("MErcs", file = var.file)
	} else {
		source(var.file)
	}

	return (MErcs)
}


HRS_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sHRS", calc_temp)

	if (!file.exists(var.file)) {
		if (HRS_code == 1) {
			HRS = 0 
		} else if (HRS_code == 2) {
			HRS = 6 
		} else {
			HRS = 12 
		} 
		dump("HRS", file = var.file)
	} else {
		source(var.file)
	}

	return (HRS)
}


CETI_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCETI", calc_temp)

	if (!file.exists(var.file)) {
		HRS = HRS_calc(source_code)
		CETI = 27.88-(0.456*Tc)+(0.010754*Tc^2)-(0.4905*RHC)+0.00088*RHC^2+(1.1507*1000/3600*WS)-(0.126447*(1000/3600*WS)^2)+(0.019876*Tc*RHC)-(0.046313*Tc*1000/3600*WS)+(0.4167*HRS)
		dump("CETI", file = var.file)
	} else {
		source(var.file)
	}

 	return (CETI)
}


NEmrhs_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEmrhs", calc_temp)

	if (!file.exists(var.file)) {
		CETI = CETI_calc(source_code)
		if (CETI > 20) {
			NEmrhs = 1.09857-(0.01343*CETI)+(0.000457*CETI^2)
		} else {
			NEmrhs = 1
		} 
		dump("NEmrhs", file = var.file)
	} else {
		source(var.file)
	}
	
	return (NEmrhs)
}


MEmrb_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sMEmrb", calc_temp) 

	if (!file.exists(var.file)) {
		NEmr = NEmr_calc(source_code)
		REM = REM_get_to_maintain(source_code)
		MEmrb = NEmr/REM		
		dump("MEmrb", file = var.file)
	} else {
		source(var.file)
	}
 
	return (MEmrb)
}


REM_get_to_maintain = function (source_code) {

	source(source_code)

	var.file = sprintf("%sREM", calc_temp)

	if (!file.exists(var.file)) {
		source(production_prediction_module)
		REM = REM_calc_for_others(source_code)
	} else {
		source(var.file)
	}

	return (REM)
}



RNB_get_to_maintain = function (source_code) {

	source(source_code)

	var.file = sprintf("%sRNB", calc_temp)

	if (!file.exists(var.file)) {
		source(rumen_model_module)
		BACTNBALANCE = BACTNBALANCE_calc(source_code)
	} else {
		source(var.file)
	}


	return (BACTNBALANCE)
}


RECYCLEDN_get_to_maintain = function(source_code) {

	source(source_code)

	var.file = sprintf("%sRECYCLEDN", calc_temp)

	if (!file.exists(var.file)) {
		source(rumen_model_module)
		RECYCLEDN = RECYCLEDN_calc(source_code)				
	} else {
		source(var.file)
	}

	return(RECYCLEDN)
}


MPbal_get_to_maintain = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPbal", calc_temp)

	if (!file.exists(var.file)) {
		source(production_prediction_module)
		MPbal = MPbal_calc_for_others(source_code)
	} else {
		source(var.file)
	}
	return (MPbal)
}


excess_N_from_MP_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sexcess_N_from_MP", calc_temp)

	if (!file.exists(var.file)) {
		MPbal = MPbal_get_to_maintain(source_code)
		excess_N_from_MP = MPbal/6.25 
		dump("excess_N_from_MP", file = var.file)
	} else {
		source(var.file)
	}

	return (excess_N_from_MP)
}


UreaCost_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sUreaCost", calc_temp) 

	if (!file.exists(var.file)) {
		RNB = RNB_get_to_maintain(source_code)
		RECYCLEDN = RECYCLEDN_get_to_maintain(source_code)
		excess_N_from_MP = excess_N_from_MP_calc(source_code)			
		if (RNB < RECYCLEDN) {		
			UreaCost = excess_N_from_MP * 0.0073
		} else {
			UreaCost = (RNB - RECYCLEDN + excess_N_from_MP) * 0.0073
		}
		dump("UreaCost", file = var.file)
	}  else {
		source(var.file) 
	}
	
	return (UreaCost)
}


FPN_calc = function (source_code) {

	source(source_code)

	var.file = sprintf('%sFPN', calc_temp)

	if (!file.exists (var.file)) {
		source(intestinal_model_module)
		IDM = IDM_calc (source_code)
		FPN = 0.09 * IDM 
		dump("FPN", file = var.file)
	} else {
		source(var.file)
	}

	return (FPN)
}


SPA_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sSPA", calc_temp)

	if (!file.exists(var.file)) {
		SPA = 0.2*SBW^0.6/0.67
		dump("SPA", file = var.file)
	} else {
		source(var.file)
	}

	return (SPA)
}


UPA_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sUPA", calc_temp)

	if (!file.exists(var.file)) {
		UPA = 2.75*SBW^0.5/0.67
		dump("UPA", file = var.file)
	} else {
		source(var.file)
	}

	return (UPA)
}


MPm_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPm", calc_temp) 

	if (!file.exists(var.file)) {
		SPA = SPA_calc(source_code)
		UPA = UPA_calc(source_code)
		FPN = FPN_calc(source_code)
		MPm = SPA + UPA + FPN 
		dump("MPm", file = var.file)
	} else {
		source(var.file)
	}

	return (MPm)
}


MEmr_calc_for_others = function (source_code) {

	MEmr = MEmr_calc (source_code)

	return (MEmr)
}


MPm_calc_others = function(source_code) {

	MPm = MPm_calc (source_code)

	return (MPm)
}


NEmr_export_to_other_function = function(source_code) {

	NEmr = NEmr_calc (source_code)

	return (NEmr)

}

#=========================================#
# Mineral requirement calculation module  #
# Date : 2014-10-22                       #
# Written by Hyesun Park                  #
#=========================================#


DMI_get_to_mineral = function(source_code) {

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


Req_Ca_calc = function (source_code) {

	source(source_code)
	var.file = sprintf("%sReq_Ca", calc_temp)

	if (!file.exists(var.file)) {
		Fecal_Ca = Fecal_Ca_calc(source_code)
		Urinary_Ca =  Urinary_Ca_calc(source_code)
		Req_Ca = Fecal_Ca + Urinary_Ca
		dump("Req_Ca", file=var.file)
	} else {
		source(var.file)
	}

	return (Req_Ca)
}

Fecal_Ca_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sFecal_Ca", calc_temp) 

	if (!file.exists(var.file)) {
		if (DIM > 0) {
			Fecal_Ca = 3.1 * FBW/100
		} else {
			Fecal_Ca = 1.54*FBW/100
		}
		dump("Fecal_Ca", file = var.file)
	} else {
		source(var.file)
	}

	return (Fecal_Ca)
}


Urinary_Ca_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sUrinary_Ca", calc_temp) 

  	if (!file.exists(var.file)) {
		Urinary_Ca = 0.08 * FBW / 100
		dump("Urinary_Ca", file = var.file)
	} else {
		source(var.file)
	}

	return (Urinary_Ca)
}


ReqM_Ca_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqM_Ca", calc_temp)

	if (!file.exists(var.file)){
		if (DIP > 190) {
			ReqM_Ca = 0.02456*exp((0.05581-(0.00007*DIP))*DIP)-0.02456*exp((0.05581-(0.00007*(DIP-1)))*(DIP-1))
		} else {
			ReqM_Ca = 0 
		}
		dump("ReqM_Ca", file = var.file)
	} else {
		source(var.file)
	}

	return (ReqM_Ca)
}


ReqL_Ca_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqL_Ca", calc_temp)

	if (!file.exists(var.file)) {
		if (DIM > 0) {
			ReqL_Ca = 1.22 * MY 		
		} else {
			ReqL_Ca = 0
		}
		dump("ReqL_Ca", file = var.file)
	} else {
		source(var.file)
	}

	return (ReqL_Ca)
}


ReqG_Ca_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqG_ca", calc_temp)

	if (!file.exists(var.file)) {
		if (target_ADG > 0) {
			ReqG_Ca = (9.83*(MW^0.22)*(FBW^(-0.22)))*(target_ADG)
		} else {
			ReqG_Ca = 0 
		}
		dump("ReqG_Ca", file = var.file)
	} else {
		source(var.file)
	}
	
	return (ReqG_Ca)
}


Reqtotal_Ca_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqtotal_Ca", calc_temp)

	if (!file.exists(var.file)) {
		Req_Ca = Req_Ca_calc(source_code)
		ReqM_Ca = ReqM_Ca_calc(source_code)
		ReqL_Ca = ReqL_Ca_calc(source_code)
		ReqG_Ca = ReqG_Ca_calc(source_code)
		Reqtotal_Ca = Req_Ca + ReqM_Ca + ReqL_Ca + ReqG_Ca
		dump("Reqtotal_Ca", file = var.file)
	} else {
		source(var.file)
	}

	return (Reqtotal_Ca)
}


Feed_Ca_calc = function(source_code) {

	source(source_code) 

	var.file = sprintf("%sFeed_Ca", calc_temp)

	if (!file.exists(var.file)) {
		Reqtotal_Ca = Reqtotal_Ca_calc(source_code)
		Feed_Ca = Reqtotal_Ca / 0.4
		dump("Feed_Ca", file = var.file)
	} else {
		source(var.file)
	}
	
	return (Feed_Ca)	
}


Req_P_calc = function(Fecal_P, Urinary_P) {

	source(source_code)

	var.file = sprintf("%sReq_P", calc_temp)

	if (!file.exists(var.file)) {
		Fecal_P = Fecal_P_calc(source_code)
		Urinary_P = Urinary_P_calc(source_code)
		Req_P = Fecal_P + Urinary_P
		dump("Req_P", file = var.file)
	} else {
		source(var.file)
	}
	
	return (Req_P)
}


Fecal_P_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFecal_P", calc_temp) 

	if (!file.exists(var.file)) {
		DMI = DMI_get_to_mineral(source_code)
		if (sex == 4) {
			Fecal_P = DMI
		} else {
			Fecal_P = 0.8 * DMI
		}
		dump("Fecal_P", file = var.file)
	} else {
		source(var.file)
	}

	return (Fecal_P)
}


Urinary_P_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sUrinary_P", calc_temp)

	if (!file.exists(var.file)) {
		Urinary_P = 0.002 * FBW 
		dump("Urinary_P", file = var.file)
	} else {
		source(var.file)
	}

	return (Urinary_P)
}


ReqM_P_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqM_P", calc_temp)

	if (!file.exists(var.file)) {
		if (DIP > 190) {
			ReqM_P = 0.02743*exp((0.05527-(0.000075*DIP))*DIP)-0.02743*exp((0.05527-(0.000075*(DIP-1)))*(DIP-1))
		} else {
			ReqM_P = 0 
		}
		dump("ReqM_P", file = var.file)
	} else {
		source(var.file)
	}
	
	return (ReqM_P)
}


ReqL_P_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqL_P", calc_temp)

	if (!file.exists(var.file)) {
		if (DIM > 0) {
			ReqL_P = 0.9 * MY
		} else {
			ReqL_P = 0 
		}
		dump("ReqL_P", file = var.file)
	} else {
		source(var.file)
	}

	return (ReqL_P)
}


ReqG_P_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqG_P", calc_temp)

	if (!file.exists(var.file)) {
		if (target_ADG > 0) {
			ReqG_P = (1.2+(4.635*(MW^0.22)*(FBW^(-0.22))))*(target_ADG)
		} else {
			ReqG_P = 0 
		}
		dump("ReqG_P", file = var.file)
	} else {
		source(var.file)
	}
	
	return (ReqG_P)
}


Reqtotal_P_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sReqtotal_P", calc_temp)

	if (!file.exists(var.file)) {
		Req_P = Req_P_calc(source_code)
		ReqM_P = ReqM_P_calc(source_code)
		ReqL_P = ReqL_P_calc(source_code)
		ReqG_P = ReqG_P_calc(source_code)
		Reqtotal_P = Req_P + ReqM_P + ReqL_P + ReqG_P
		dump("Reqtotal_P", file = var.file)
	} else {
		source(var.file)
	}

	return (Reqtotal_P)	
}


Feed_P_calc = function (source_code) {

	source (source_code)

	var.file = sprintf("%sFeed_P", calc_temp)

	if (!file.exists(var.file)) {
		Reqtotal_P = Reqtotal_P_calc(source_code)
		Feed_P = Reqtotal_P / 0.67 
		dump("Feed_P", file = var.file)
	} else {
		source(var.file)
	}

	return (Feed_P)
}


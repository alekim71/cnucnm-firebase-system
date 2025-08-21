
#===========================================#
# Lactation requirement calculation module  #
# Date : 2014-10-22                         #
# Written by Hyesun Park                    #
#===========================================#


PKYD_get = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPKYD", calc_temp)
	if (!file.exists(var.file)) {
		source(input_database)
		breed_data = breed_table[[breed_code]]
		PKYD = as.numeric(breed_data [5])
		dump("PKYD", file = var.file)
	} else {
		source(var.file)
	}

	return (PKYD)
}


PKYDadj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPKYDadj", calc_temp)

	if (!file.exists(var.file)) {
		PKYD = PKYD_get(source_code)
		PKYDadj = (0.125*RelMilkProd + 0.375) * PKYD
		dump("PKYDadj", file = var.file)
	} else {
		source(var.file)
	}

	return (PKYDadj)	
}


PKW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPKW", calc_temp)

	if (!file.exists(var.file)) {
		#  Hanwoo : 8.5  (Lactation for beef)
		PKW = 8.5 
		dump("PKW", file = var.file)
	} else {
		source(var.file)
	}
	
	return (PKW)
}


IRC_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sIRC", calc_temp)
	if (!file.exists(var.file)) {
		PKYDadj = PKYDadj_calc(source_code)
		PKW = PKW_calc(source_code)
		IRC = 1/(PKYDadj*(1/PKW)*exp(1))
		dump("IRC", file = var.file)
	} else {
		source(var.file)
	}
	
	return (IRC)
}


WOL_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sWOL", calc_temp)

	if (!file.exists(var.file)) {
		WOL = DIM/74
		dump("WOL", file = var.file)
	} else {
		source(var.file)
	}
	
	return (WOL)
}


Milkbeef_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMilkbeef", calc_temp)

	if (!file.exists(var.file)) { 
		WOL = WOL_calc(source_code)
		IRC = IRC_calc(source_code)
		PKW = PKW_calc(source_code)
		Milkbeef = WOL/(IRC*exp((1/PKW)*WOL))
		dump("Milkbeef",file = var.file)
	} else {
		source(var.file)		
	}

	return (Milkbeef)
}


Milkadj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMilkadj", calc_temp)

	if (!file.exists(var.file)) {
		Milkbeef =  Milkbeef_calc(source_code)
		if (breed_type == 3) {
			Milkadj = MY
		} else {
			if (age == 2) {
				Milkadj = 0.74 * Milkbeef
			} else {
				if (age == 3) {
					Milkadj = 0.88 * Milkbeef
				} else {
					Milkadj = Milkbeef
				}
			}
		}
		dump("Milkadj", file = var.file)
	} else {
		source(var.file)
	}

	return (Milkadj)
}


MFadj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMFadj", calc_temp) 

	if (!file.exists(var.file)) {
		source(input_database)
		MFP = as.numeric(breed_table[[breed_code]][6])
		if (breed_type == 3) {
			MFadj = MF
		} else {
			MFadj = MFP
		}
		dump("MFadj", file = var.file)
	} else {
		source(var.file)
	}

	return (MFadj)
}


PPadj_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPPadj", calc_temp) 
	
	if (!file.exists(var.file)) {
		source(input_database)
		TrueMPP = as.numeric(breed_table[[breed_code]][8])
		if (breed_type == 3) {
			PPadj = PP
		} else {
			PPadj = TrueMPP
		}
		dump("PPadj", file = var.file)
	} else {
		source(var.file)
	}

	return (PPadj)
}


LE_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLE", calc_temp) 

	if (!file.exists(var.file)) {
		Milkadj = Milkadj_calc(source_code)
		MFadj = MFadj_calc(source_code)
		LE = Milkadj * ((0.3512 + (0.0962*MFadj))/0.644)
		dump("LE", file = var.file)
	} else {
		source(var.file)
	}

	return(LE)
}


LP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLP", calc_temp)

	if (!file.exists(var.file)) {
		Milkadj = Milkadj_calc(source_code)
		PPadj = PPadj_calc(source_code)
		LP = 10*Milkadj*PPadj/0.65
		dump("LP", file = var.file)
	} else {
		source(var.file)
	}

	return (LP)
}


MElact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMElact", calc_temp)

	if (!file.exists(var.file)) {
		MElact = MY*((0.3512+(0.0962*MF))/0.644)
		dump("MElact", file = var.file)
	} else {
		source(var.file)
	}

	return (MElact)
}

#MP_lact=10*MY*99/00.5->0.65 corrected
MPlact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPlact", calc_temp)

	if (!file.exists(var.file)) {
		MPlact = 10 * MY * PP / 0.65
		dump("MPlact", file = var.file)
	} else {
		source(var.file)
	}

	return (MPlact)
}


Coef_A_calc = function(source_code) {

	source(source_code)

	var.file  = sprintf("%sCoef_A", calc_temp)

	if (!file.exists(var.file)) {
		if (lact_no > 1) {
			Coef_A = (14+RHA*2.204*0.01)/2.96
		} else {
			Coef_A = (RHA*2.204*0.01-20)/2.96
		}
		dump("Coef_A", file = var.file)
	} else {
		source(var.file)
	}

	return (Coef_A)
}


wood_table_get = function(source_code, coef_tag) {

	source(source_code)

	var.file = sprintf("%sCoef_%s", calc_temp, coef_tag)

	if (!file.exists(var.file)) {
		tag_list = c("A", "B", "C", "D")
		tag_index = grep(coef_tag, tag_list)
		wood_table = c(c(67.568, 0.08, -0.002, -0.001),
			c(79.054, 0.12, -0.004, -0.002), 
			c(79.054, 0.16, -0.005, -0.002)
			)
		wood_coefficient = wood_table[lact_no][tag_index]
		dump("wood_coefficient",file=var.file)
	} else {
		source(var.file)
	}

	
	return (wood_coefficient)
}


Milkpred_calc  = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMilkpred", calc_temp) 

	if (!file.exists(var.file)) {
		Coef_A = Coef_A_calc(source_code)
		Coef_B = wood_table_get(source_code, 'B')
		Coef_C = wood_table_get(source_code, 'C')
		Coef_D = wood_table_get(source_code, 'D')
		Milkpred = Coef_A * (DIM^Coef_B) * exp(Coef_C*DIM) * exp(Coef_D * DIP)
		dump("Milkpred", file = var.file)
	} else {
		source(var.file)
	}

	return (Milkpred)
}


PMF_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPMF", calc_temp)

	if (!file.exists(var.file)) {
		source(input_database)
		PMF = as.numeric(breed_table[[breed_code]][6])
		dump("PMF", file = var.file)
	} else {
		source(var.file)
	}

	return (PMF)
}


PMP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPMP", calc_temp)

	if (!file.exists(var.file)) {
		source(input_database)
		PMP = as.numeric(breed_table[[breed_code]][7])
		dump("PMP", file = var.file)
	} else {
		source(var.file)
	}

	return (PMP)
}


PQ_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPQ", calc_temp)

	if (!file.exists(var.file)) {
		PMF = PMF_calc(source_code)
		PQ = 1.01*PMF*(((DIM+1)/7)^(-0.13))*(exp(0.02*((DIM+1)/7)))
		dump("PQ", file = var.file)
	} else {
		source(var.file)
	}
		return (PQ)
}


PP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPP", calc_temp)

	if (!file.exists(var.file)) {
		PMP = PMP_calc(source_code)
		PP = 1.14*PMP*(((DIM+1)/7)^(-0.12))*(exp(0.01*((DIM+1)/7)))	
		dump("PP", file = var.file)
	} else {
		source(var.file)
	}

	return (PP)
}


LP_calc_for_others = function(source_code) {

	source(source_code)

	LP = LP_calc (source_code)

	return (LP)
}


Milkbeef_calc_for_others = function(source_code) {
	
	Milkbeef = Milkbeef_calc (source_code)

	return (Milkbeef)
}
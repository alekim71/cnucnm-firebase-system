#============================================#
# Amino acid requirements calculation module #
# Date : 2014-10-23                          #
# Written by Hyesun Park                     #
#============================================#


aminoacid_components_get = function() {

	# % CP 
	# MET, LYS, ARG, THR, LEU, ILE, VAL, HIS, PHE, TRP 
	tissue_component = c(1.970, 6.370, 3.300, 3.900, 6.700, 2.840, 4.030, 2.470, 3.530, 0.490)
	milk_components = c(2.710, 7.620, 3.400, 3.720, 9.180, 5.790, 5.890, 2.740, 4.750, 1.510)

	aminoacid_components = list(tissue_component, milk_components)

	return (aminoacid_components)
}


EqSBWg_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqSBWg", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		EqSBWg = EqSBWg_calc (source_code)		
	} else {
		source(var.file)
	}

	return (EqSBWg)
}


aminoacid_efficiency_database = function (source_code) {

	EqSBWg = EqSBWg_get_to_aarequired(source_code)

	# MET, LYS, ARG, THR, LEU, ILE, VAL, HIS, PHE, TRP 
	EAAM = c(85, 85, 85, 85, 66, 66, 66, 85, 85, 85)
	EAAG = rep((0.834-(0.00114*EqSBWg))*100 , 10)
	EAAP = c(35, 53, 38, 57, 42, 32, 32, 32, 48, 85)
	EAAL = c(100, 82, 35, 78, 72, 66, 62, 96, 98, 85)

	aminoacid_efficiency_table = list(EAAM, EAAG, EAAP, EAAL)

	return (aminoacid_efficiency_table)
}


Preg_eff_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%sPreg_eff", calc_temp)

	if (!file.exists(var.file)) {

		if (breed_type == 3){
			Preg_eff = 0.33
		} else {
			Preg_eff = 0.5 
		}
		dump("Preg_eff", file = var.file)
	} else { 
		source(var.file)
	}

	return (Preg_eff)
}


FPN_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file  = sprintf("%sFPN", calc_temp)

	if (!file.exists(var.file)) { 
		source(maintain_requirement_module)
		FPN = FPN_calc (source_code)
	} else {
		source(var.file)
	}

	return (FPN)	
}


SPA_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sSPA", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		SPA = SPA_calc(source_code)
	} else {
		source(var.file)
	}

	return (SPA)
}


UPA_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sUPA", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		UPA = UPA_calc(source_code) 
	} else {
		source(var.file)
	}

	return (UPA)
}


MPAA_calc = function(source_code) {

	# MET, LYS, ARG, THR, LEU, ILE, VAL, HIS, PHE, TRP 

	aminoacid_components = aminoacid_components_get()
	FPN = FPN_get_to_aarequired(source_code)
	UPA = UPA_get_to_aarequired(source_code)
	SPA = SPA_get_to_aarequired(source_code)

	aminoacid_efficiency_table = aminoacid_efficiency_database(source_code)

	tissue_component = aminoacid_components[[1]]
	EAAM = aminoacid_efficiency_table[[1]]

	MPAA = NULL 

	for (i in 1:10) {
		MPAA.data = tissue_component[i]*(FPN + ((UPA+SPA)*0.67)/(EAAM[i]*0.01))/100
		MPAA = c(MPAA, MPAA.data)
	}

	return (MPAA)
}


EqSBW_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEqSBW", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module) 
		EqSBW = EqSBW_calc(source_code)
	} else {
		source()
	}

	return (EqSBW)
}


NPg_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNPg", calc_temp)

	if (!file.exists(var.file)) {
		source(growth_requirement_module) 
		NPg = NPg_calc (source_code)
	} else {
		source(var.file)
	}

	return (NPg)
}


MPmm_get_to_aarequired = function(source_code) {

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


RPAA_calc = function(source_code) {

	# MET, LYS, ARG, THR, LEU, ILE, VAL, HIS, PHE, TRP 

	NPg = NPg_get_to_aarequired(source_code)
	MPmm = MPmm_get_to_aarequired(source_code)

	aminoacid_efficiency_table = aminoacid_efficiency_database(source_code)
	aminoacid_components = aminoacid_components_get()

	tissue_component = aminoacid_components[[1]]
	EAAG = aminoacid_efficiency_table[[2]]

	RPAA = NULL 

	for (i in 1:10) {
		RPAA.data = tissue_component[i]*(NPg + MPmm *0.28908)/(EAAG[i]*0.01)/100
		RPAA = c(RPAA, RPAA.data)
	}

	return (RPAA)
}


MPpreg_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPpreg", calc_temp) 

	if (!file.exists(var.file)) {
		source(growth_requirement_module)
		MPpreg = MPpreg_calc (source_code)
	} else {
		source(var.file)
	}

	return (MPpreg)
}


LPAA_calc = function(source_code) {

	MPpreg  = MPpreg_get_to_aarequired(source_code)
	Preg_eff = Preg_eff_calc(source_code)

	aminoacid_efficiency_table = aminoacid_efficiency_database(source_code)
	aminoacid_components = aminoacid_components_get()

	tissue_component = aminoacid_components[[1]]
	EAAP = aminoacid_efficiency_table[[3]]
	LPAA = NULL 

	for (i in 1:10) {
		LPAA.data = tissue_component[i]* MPpreg * Preg_eff/(EAAP[i]*0.01)/100
		LPAA = c(LPAA, LPAA.data)
	}

	return (LPAA)
}



LP_get_to_aarequired = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLP", calc_temp) 
	if (!file.exists(var.file)) {
		source(lactation_requirement_module)
		LP = LP_calc_for_others(source_code)
	} else {
		source(var.file)
	}

	return (LP)
}


YPAA_calc = function(source_code) {

	LP = LP_get_to_aarequired(source_code)
	aminoacid_efficiency_table = aminoacid_efficiency_database(source_code)
	aminoacid_components = aminoacid_components_get()

	milk_components = aminoacid_components[[2]]
	EAAL = aminoacid_efficiency_table[[4]]

	YPAA= NULL 

	for (i in 1:10) {
		YPAA.data = milk_components[i] * LP * 0.65/(EAAL[i]*0.01)/100
		YPAA = c(YPAA, YPAA.data)
	}

	return (YPAA)
}


total_AA_calc = function(source_code) {

	MPAA = MPAA_calc(source_code)
	RPAA = RPAA_calc(source_code)
	LPAA = LPAA_calc(source_code)
	YPAA = YPAA_calc(source_code)

	total_AA = NULL 

	for (i in 1:10) {
		total.data = sum(MPAA[i], RPAA[i], LPAA[i], YPAA[i])
		total_AA = c(total_AA, total.data)
	}

	return (total_AA)
}



aareq_calc_for_others = function (source_code) { 

	MPAA = MPAA_calc(source_code)
	RPAA = RPAA_calc(source_code)
	LPAA = LPAA_calc(source_code)
	YPAA = YPAA_calc(source_code)

	aareq_mat = rbind(MPAA, RPAA, LPAA, YPAA)
	colnames(aareq_mat) = c("MET", 'LYS', 'ARG', 'THR', 'LEU', 'ILE', 'VAL', 'HIS', 'PHE', 'TRP')
	rownames(aareq_mat) = c('MPAA', 'RPAA', 'LPAA', 'YPAA')

	return (aareq_mat)
} 
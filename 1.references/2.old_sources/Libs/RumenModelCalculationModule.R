#================================#
# Rumen model calculation module #
# Date : 2014-10-28              #
# Written by Hyesun Park         #
#================================#


feed_infor_get = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_feed_database)) {

		feed_db = read.csv(file=feed_library, header=T, row.names=1)
		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)
		feed_id_list = rownames(feed_data)

		subSet = NULL 

		for (i in 1:length(feed_id_list)) {
			feed_info = feed_db[feed_id_list[i],]
			subSet = rbind(subSet, feed_info)
		}
		write.csv(subSet, file=tmp_feed_database, quote=F, row.names=T)

	} else {
		subSet = read.csv(tmp_feed_database, header=T, row.names=1) 
	}

	return (subSet) 
}


dm_perc_get = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_dm_percent)) {

		source(feed_module)

		dm_perc_result = dm_perc_calc(source_code)
		dm_perc_result = dm_perc_result[1:nrow(dm_perc_result)-1,]
		
	} else {
		dm_perc_result = read.csv(file=tmp_dm_percent, header=T, row.names=1)
		dm_perc_result = dm_perc_result[1:nrow(dm_perc_result)-1, ]
	}

	return (dm_perc_result)
}


DMI_intake_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDMI", calc_temp)

	if (!file.exists(var.file)) {
		dm_perc = dm_perc_get(source_code)
		DMI = sum(as.numeric(dm_perc[,2]))
		dump("DMI", file = var.file)
	} else {
		source(var.file)
	}

	return (DMI) 
}


feed_info_total_calc = function(source_code) {

	feed_subSet = feed_infor_get(source_code)
	feed_contents = feed_subSet[,6:ncol(feed_subSet)]

	dm_perc = dm_perc_get(source_code)
	dm_perc.only = dm_perc[,1:2]
	
	dm_total = DMI_intake_calc(source_code)

	feed_id_list = rownames(feed_subSet)

	composition_sum = rep(0.0, ncol(feed_contents))

	for (i in (1:length(feed_id_list))) {		
		dm = as.numeric(dm_perc.only[i,2])
		feed_data = feed_contents[i,]

		for (j in (1:ncol(feed_data))) {
			compos_data = as.numeric(feed_data[j]) * dm/dm_total
			composition_sum [j] = composition_sum[j] + compos_data 
		}
	}

	return (composition_sum)
}


dietndf_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdietndf", calc_temp)

	if (!file.exists(var.file)) {
		dietndf= feed_info_total_calc(source_code)[2]
		dump("dietndf", file = var.file)
	} else {
		source(var.file)
	}

	return (dietndf)
}


dietCa_calc = function(source_code) {


	source(source_code)

	var.file = sprintf("%sdietCa", calc_temp)

	if (!file.exists(var.file)) {
		dietCa = feed_info_total_calc(source_code)[49]		
		dump("dietCa", file = var.file)
	} else {
		source(var.file)
	}

	return (dietCa)
}


dietP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdietP", calc_temp)

	if (!file.exists(var.file)) {
		dietP = feed_info_total_calc(source_code)[50]
		dump("dietP", file = var.file)
	} else {
		source(var.file)
	}

	return (dietP)
}



DCAB1_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDCAB1", calc_temp)

	if (!file.exists(var.file)) {
		feed_total_set = feed_info_total_calc(source_code)
		cl = feed_total_set[52]
		k = feed_total_set[53]
		Na = feed_total_set[54]
		S = feed_total_set[55]
		DCAB1 = (435*Na+256*k) - (282*cl+624*S)
		dump("DCAB1", file = var.file)
	} else {
		source(var.file)
	}

	return (DCAB1)
}


DCAB2_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDCAB2", calc_temp)

	if (!file.exists(var.file)) {
		feed_total_set = feed_info_total_calc(source_code)
		ca = feed_info_total_calc(source_code)[49]
		P = feed_info_total_calc(source_code)[50]
		mg = feed_info_total_calc(source_code)[51]
		cl = feed_total_set[52]
		k = feed_total_set[53]
		Na = feed_total_set[54]
		S = feed_total_set[55]
		DCAB2 = (0.15*500*ca+0.15*823*mg+453*Na+256*k)-(282*cl+0.25*624*S+0.5*968*P)
		dump("DCAB2", file = var.file)
	} else {
		source(var.file)
	}

	return (DCAB2)
}


Dietstarch_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietstartch", calc_temp)

	if (!file.exists(var.file)) {
		Dietstarch = feed_info_total_calc(source_code)[83]
		dump("Dietstarch", file = var.file)
	} else {
		source(var.file)
	}

	return (Dietstarch)
}


Dietsugar_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietsugar", calc_temp)

	if (!file.exists(var.file)) {
		Dietsugar = feed_info_total_calc(source_code)[84]
		dump("Dietsugar", file = var.file)
	} else {
		source(var.file)
	}

	return (Dietsugar)
}


Dietlactic_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietlactic", calc_temp)

	if (!file.exists(var.file)) {
		Dietlactic = feed_info_total_calc(source_code)[85]
		dump("Dietlactic", file = var.file)
	} else {
		source(var.file)
	}

	return (Dietlactic)
}


Dietacetic_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietacetic", calc_temp)

	if (!file.exists(var.file)) {
		Dietacetic = feed_info_total_calc(source_code)[86]
		dump("Dietacetic", file = var.file)
	} else {
		source(var.file)
	}

		return (Dietacetic)
}


Dietpropionic_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietpropionic", calc_temp)

	if (!file.exists(var.file)) {
		Dietpropionic = feed_info_total_calc(source_code)[87]
		dump("Dietpropionic", file = var.file)
	} else {
		source(var.file)
	}

	return (Dietpropionic)
}


Dietbutyric_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietbutyric", calc_temp)

	if (!file.exists(var.file)) {
		Dietbutyric = feed_info_total_calc(source_code)[88]
		dump("Dietbutyric", file = var.file)
	} else {
		source(var.file)
	}

	return (Dietbutyric)
}


DietIsobutyric_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietIsobutyric", calc_temp)

	if (!file.exists(var.file)) {
		DietIsobutyric = feed_info_total_calc(source_code)[89]
		dump("DietIsobutyric", file = var.file)
	} else {
		source(var.file)
	}

	return (DietIsobutyric)
}


protein_pool_calc = function(cp, sol.p, npn, ndfip, adfip) {

	protein.a = npn*(sol.p/100)*(cp/100)
	protein.b1 = (sol.p*cp)/100 - protein.a		 

	if (adfip > ndfip) {
		protein.b3 = (cp/100)*0
	} else {
		protein.b3 = (cp/100)*(ndfip - adfip)
	}

	protein.c = adfip*cp/100
	protein.b2 = cp - protein.a - protein.b1 - protein.b3 - protein.c 

	protein_pool = c(protein.a, protein.b1, protein.b2, protein.b3, protein.c)

	return (protein_pool)
}


total_cho_calc = function(cp, EE, Ash) {

	if (100-(cp+EE+Ash) > 0) {
		total.cho = 100 - (cp+EE+Ash)
	} else {
		total.cho = 0 
	}

	return (total.cho)
}


total_nfc_calc = function(total.cho, cho_pool.b2, cho_pool.c) {

	if (total.cho-(cho_pool.b2+cho_pool.c) < 0) {
		total.nfc = 0
	} else {
		total.nfc = total.cho - (cho_pool.b2+cho_pool.c)		
	}

	return (total.nfc)
}


cho_pool_calc = function(total.cho, cp, ndf, lignin, ndfip, starch){

	if (total.cho == 0){ 
		cho_pool.c = 0
	} else {
		cho_pool.c = (ndf*lignin*2.4)/100
	}

	if (total.cho == 0) {
		cho_pool.b2 = 0
	} else {
		cho_pool.b2 = ndf -(ndfip*cp)/100 - cho_pool.c
	}

	total.nfc = total_nfc_calc(total.cho, cho_pool.b2, cho_pool.c)

	cho_pool.b1 = starch * total.nfc / 100

	cho_pool.a = total.nfc - cho_pool.b1 
	cho_pool = c(cho_pool.a, cho_pool.b1, cho_pool.b2, cho_pool.c)

	return (cho_pool)
}


intake_carbprot_p_DM = function(source_code) {

	source (source_code)

	if (!file.exists(tmp_intake_p_dm)) { 

		feed_db = feed_infor_get(source_code)
		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)

		feed_id_list = rownames(feed_data)

		out_matrix = NULL

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			feed_name = as.character(feed_db[f_id,"Feed_name"])

			protein_pool = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'],  feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])

			total.protein = sum(protein_pool)

			EE = feed_db[f_id, 'Crude.fat...DM.']
			Ash = feed_db[f_id, 'Crude.ash...DM.']

			total.cho = total_cho_calc(feed_db[f_id, 'CP...DM.'], EE, Ash)
			cho_pool = cho_pool_calc (total.cho, feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'NDF...DM.'], feed_db[f_id, 'Lignin...NDF.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'Starch...NSC.'])
			total.nfc = total_nfc_calc(total.cho, cho_pool[3], cho_pool[4])
			total.f = sum(cho_pool, protein_pool, EE, Ash)	

			out_data = c(f_id, feed_name, cho_pool,  protein_pool, EE, Ash, total.f, total.cho, total.nfc, total.protein)	
			out_matrix = rbind(out_matrix, out_data)
		}

		colnames(out_matrix) = c('Feed_ID', 'Feed_name', 'CHO.pools.A', 'CHO.pools.B1', 'CHO.pools.B2', 'CHO.pools.C',  
			'Protein.pools.A', 'Protein.pools.B1', 'Protein.pools.B2', 'Protein.pools.B3', 'Protein.pools.C',
			'EE', 'Ash', 'Total.F', 'Total.CHO', 'Total.NFC', 'Total.protein')

		rownames(out_matrix) = feed_id_list
		if (nrow(out_matrix) >= 2) {
		    out_matrix = out_matrix[,2:ncol(out_matrix)]
		    write.csv(out_matrix, file=tmp_intake_p_dm, quote=F, row.names=T)		
		} else {
		   	write.csv(out_matrix, file=tmp_intake_p_dm, quote=F, row.names=F)		
		   }
	} else {
		out_matrix = read.csv(file = tmp_intake_p_dm, header=T, row.names=1)
	}
	return (out_matrix)
}


ionophore_get_to_rumen = function(source_code) {

	source(source_code)
	var.file = sprintf("%sionophore", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		ionophore = ionophore_calc (source_code)
	} else {
		source(var.file)
	}

	return (ionophore)
}


NEmr_get_to_rumen = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEmr", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		NEmr = NEmr_export_to_other_function(source_code)
	} else {
		source(var.file)
	}

	return (NEmr)
}


DMIfactor_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sDMIfactor", calc_temp)

	if (!file.exists(var.file)) {
		DMI = DMI_intake_calc (source_code)
		NEmr = NEmr_get_to_rumen(source_code)
		NEma1x = NEma1x_energy_calc(source_code)
		DMIfactor = DMI/(NEmr/NEma1x) - 1
		dump("DMIfactor", file = var.file)
	} else {
		source(var.file)
	}

	return (DMIfactor)
}


RECYCLEDN_calc = function(source_code) {

	source (source_code)

	var.file = sprintf("%sRECYCLEDN", calc_temp)

	if (!file.exists(var.file)){
		DietCP = as.numeric(DietCP_calc(source_code))
		TotalCP = as.numeric(TotalCP_calc(source_code))
		RECYCLEDN = ((121.74-12.01*DietCP + 0.3235*DietCP^2)/100)*TotalCP/6.25
		dump("RECYCLEDN", file = var.file)
	} else {
		source(var.file)
	}

	return (RECYCLEDN)
}



#########################
# DM intake calculation #
#########################

intake_total_value_calc = function(dm_perc, sum_value) {

	dm_total_perc = sum(as.numeric(dm_perc[,3]))
	intake_total_value = sum_value/dm_total_perc

	return (intake_total_value)
}


forage_intake_calc = function(feed_db, dm_perc, source_code) {

	forage_result = NULL

	feed_id_list = rownames(dm_perc) 

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		dm = as.numeric(dm_perc[f_id,2])

		if (feed_db[f_id,'Forage...'] == 100) {
			forage = dm
		} else {
			forage = 0
		}
		forage_result = c(forage_result, forage)
	}

	DMI = DMI_intake_calc(source_code)
	forage.total = sum(forage_result)/DMI
	
	forage_result = c(forage_result, forage.total)

	return (forage_result)
}


cp_intake_calc = function(feed_db, dm_perc) {

	cp_result = NULL 

	feed_id_list = rownames(dm_perc) 

	for (i in (1:length(feed_id_list))) {

		f_id = feed_id_list[i]
		dm = as.numeric(dm_perc[f_id,2])

		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])
		total.protein = sum(protein_pool)

		cp = dm * 1000*total.protein/100
		cp_result = c(cp_result, cp)
	}

	DMI = DMI_intake_calc(source_code)
	cp.total = sum(cp_result)/(DMI*1000)*100
	cp_result = c(cp_result, cp.total)

	return (cp_result)
} 


af_intake_calc = function(feed_db, dm_perc) {

	af_result = NULL

	feed_id_list = rownames(dm_perc) 

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		dm = as.numeric(dm_perc[f_id, 2])

		if (feed_db[f_id,'DM..AF.'] == 0) {
			af = 0
		} else {
			af = dm/(feed_db[f_id,'DM..AF.']/100) 
		}

		af_result = c(af_result, af)
	}

	af.total = sum(af_result)
	af_result = c(af_result, af.total)

	return (af_result)
}


foragendf_intake_calc = function(feed_db, dm_perc, source_code) {

	source(source_code)

	forage_result = forage_intake_calc (feed_db, dm_perc, source_code)

	foragendf_result = NULL 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		
		forage = forage_result[i]
		foragendf = forage*feed_db[f_id,'NDF...DM.']/100

		foragendf_result = c(foragendf_result, foragendf)
	}

	#foragendf.total = sum(foragendf_result)/FBW*100

	foragendf.total = sum(foragendf_result)
	foragendf_result = c(foragendf_result, foragendf.total)

	return (foragendf_result)
}


ndfn_intake_calc = function(feed_db, dm_perc) {

	ndfn_result = NULL 
	ndfn_sum = 0

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]

		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])		

		ndfn = feed_db[f_id,'NDF...DM.'] - protein_pool[4] 
		ndfn_sum = ndfn_sum + (feed.dm_perc * ndfn)

		ndfn_result = c(ndfn_result, ndfn)
	}

	ndfn.total = intake_total_value_calc(dm_perc, ndfn_sum)

	ndfn_result = c(ndfn_result, ndfn.total)

	return (ndfn_result)
} 


iadicp_intake_calc = function(feed_db, dm_perc) {

	iadicp_result = NULL 
	iadicp_sum = 0
	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])
		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])

		iadicp = (feed_db[f_id, 'Concentrate...']*(0.4*protein_pool[5])+feed_db[f_id,'Forage...']*(0.7*protein_pool[5]))/100
		iadicp_sum = iadicp_sum + (iadicp * feed.dm_perc)

		iadicp_result = c(iadicp_result, iadicp)
	}
	
	iadicp.total = intake_total_value_calc(dm_perc, iadicp_sum)

	iadicp_result = c(iadicp_result, iadicp.total)

	return (iadicp_result)
}


kdcp_intake_calc = function(feed_db, dm_perc) {

	kdcp_result = NULL 
	kdcp_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])

		kdcp = (feed_db[f_id,'Forage...']*(exp(-0.0012*protein_pool[5]))+feed_db[f_id, 'Concentrate...']*(1-(0.004*protein_pool[5])))/100
		kdcp_sum = kdcp_sum + (kdcp*feed.dm_perc)
		kdcp_result = c(kdcp_result, kdcp)
	}

	kdcp.total = intake_total_value_calc(dm_perc, kdcp_sum)

	kdcp_result = c(kdcp_result, kdcp.total)

	return (kdcp_result)
}


lignin_intake_calc = function(feed_db, dm_perc) {

	lignin_result = NULL
	lignin_sum = 0
	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		lignin = feed_db[f_id,'NDF...DM.']/100*feed_db[f_id, 'Lignin...NDF.']
		lignin_sum = lignin_sum + (lignin*feed.dm_perc)
		lignin_result = c(lignin_result, lignin)
	}

	lignin.total = intake_total_value_calc(dm_perc, lignin_sum)

	lignin_result = c(lignin_result, lignin.total)

	return (lignin_result)
}


digestfiber_intake_calc = function(feed_db, dm_perc) {

	ndfn_result = ndfn_intake_calc(feed_db, dm_perc)
	lignin_result = lignin_intake_calc(feed_db, dm_perc)

	digestfiber_result = NULL 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed_name = as.character(dm_perc[f_id,1])

		lignin = lignin_result[i]
		ndf.n = ndfn_result[i]

		if (feed_name == '' | feed_db[f_id, 'TDN...DM.'] == 0 | ndf.n == 0) {
			digestfiber = 0 
		} else {
			digestfiber = (ndf.n-lignin)*(1-(lignin/ndf.n)^(2/3))
		}

		digestfiber_result = c(digestfiber_result, digestfiber)
	}

	digestfiber_result = c(digestfiber_result, '')

	return (digestfiber_result)
}


tdn1x_intake_calc = function(feed_db, dm_perc) {

	tdn1x_result = NULL 

	ndfn_result = ndfn_intake_calc(feed_db, dm_perc)
	iadicp_result = iadicp_intake_calc(feed_db, dm_perc)
	kdcp_result = kdcp_intake_calc(feed_db, dm_perc)
	digestfiber_result = digestfiber_intake_calc(feed_db, dm_perc)

	tdn1x_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]

		feed_name = as.character(dm_perc[f_id,1])
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])
		total.protein = sum(protein_pool)

		dig.fiber = as.numeric(digestfiber_result[i])

		ndf.n = ndfn_result[i]
		iadicp = iadicp_result[i]
		kdcp = kdcp_result[i]

		if (feed_name == '' | feed_db[f_id, 'TDN...DM.'] == 0)  {			
			tdn1x = 0
		} else {
			tdn1x =0.98*(100-ndf.n-total.protein-feed_db[f_id, 'Crude.ash...DM.']-feed_db[f_id, 'Crude.fat...DM.']+iadicp)+kdcp*total.protein+2.7*(feed_db[f_id,'Crude.fat...DM.']-1)+(0.75*dig.fiber)-7
		}

		tdn1x_sum = tdn1x_sum + (tdn1x*feed.dm_perc)
		tdn1x_result = c(tdn1x_result, tdn1x)
	}

	tdn1x.total = intake_total_value_calc(dm_perc,  tdn1x_sum)

	tdn1x_result = c(tdn1x_result, tdn1x.total)

	return (tdn1x_result)
}


dtdn_intake_calc = function(feed_db, dm_perc) {

	dtdn_result = NULL
	tdn1x_result = tdn1x_intake_calc(feed_db, dm_perc)	
	dtdn_sum = 0 
	DMI = DMI_intake_calc(source_code)
	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])
		tdn1x = tdn1x_result[i]

		protein_pool  = protein_pool_calc(feed_db[f_id, 'CP...DM.'], feed_db[f_id, 'Sol.P...CP.'], feed_db[f_id, 'NPN...Sol.P.'], feed_db[f_id, 'NDICP...CP.'], feed_db[f_id, 'ADICP...CP.'])

		DMIfactor = DMIfactor_calc(source_code)
		
		if (tdn1x == 0) {
			dtdn = 0
		} else {
			dtdn = ((feed_db[f_id,'Concentrate...']*(1.01*tdn1x-1.77*DMIfactor-0.99))+(feed_db[f_id, 'Forage...']*(0.53+0.99*tdn1x-0.009*feed_db[f_id,'NDF...DM.']+0.00005*tdn1x*feed_db[f_id,'NDF...DM.']+0.009*DMIfactor-0.1*DMIfactor-0.13*feed_db[f_id,'NDF...DM.']*DMIfactor+0.0005*tdn1x*feed_db[f_id,'NDF...DM.']*DMIfactor)))/100	
		}

		dtdn_sum = dtdn_sum + (dtdn*feed.dm_perc) 
		dtdn_result = c(dtdn_result, dtdn)
	}

	dtdn.total = intake_total_value_calc(dm_perc, dtdn_sum)

	dtdn_result = c(dtdn_result, dtdn.total)

	return (dtdn_result)
}


DE_intake_calc = function(feed_db, dm_perc) {

	DE_result = NULL
	DE_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])
		DE = (feed_db[f_id, 'TDN...DM.']/100)*4.409
		DE_sum = DE_sum + (DE*feed.dm_perc)

		DE_result = c(DE_result, DE)		
	}

	DE.total = intake_total_value_calc(dm_perc, DE_sum)

	DE_result = c(DE_result, DE.total) 

	return (DE_result)
}


ME_intake_calc = function(feed_db, dm_perc, source_code) {

	source(source_code)

	DE_result = DE_intake_calc(feed_db, dm_perc)

	ME_result = NULL
	ME_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id, 3])

		DE = DE_result[i]

		if ((animal_type == 2|animal_type==3) & DE == 0) {
			ME = 0
		} else if ((animal_type == 2 | animal_type == 3) & DE != 0) {
			ME = (DE*1.01)-0.45
		} else if ((animal_type != 2 & animal_type != 3) & DE == 0) {			
			ME = 0 
		} else {
			ME = 0.82*DE 
		}

		ME_sum = ME_sum + (ME*feed.dm_perc)
		ME_result = c(ME_result, ME)
	}

	ME.total = intake_total_value_calc(dm_perc, ME_sum)

	ME_result = c(ME_result, ME.total)

	return (ME_result)
}


NEma_intake_calc = function(feed_db, dm_perc, source_code) {

	ME_result = ME_intake_calc(feed_db, dm_perc, source_code)

	NEma_result = NULL 
	NEma_sum = 0

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		ME = ME_result [i]

		if (ME == 0){
			NEma = 0
		} else {
			NEma = 1.37*ME-0.138*ME^2+0.0105*ME^3-1.12
		}

		NEma_sum  = NEma_sum + (NEma*feed.dm_perc)

		NEma_result = c(NEma_result, NEma)
	}

	NEma.total = intake_total_value_calc(dm_perc, NEma_sum)
	NEma_result = c(NEma_result, NEma.total)

	return (NEma_result)
}


NEga_intake_calc = function(feed_db, dm_perc, source_code) {

	ME_result = ME_intake_calc(feed_db, dm_perc, source_code)
	NEga_result = NULL
	NEga_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id, 3])

		ME = ME_result [i]

		if (ME==0) {
			NEga = 0
		} else {
			NEga = 1.42*ME-0.174*ME^2+0.0122*ME^3-1.65
		}

		NEga_sum = NEga_sum + (NEga*feed.dm_perc)
		NEga_result = c(NEga_result, NEga)
	}

	NEga.total = intake_total_value_calc(dm_perc, NEga_sum)

	NEga_result = c(NEga_result, NEga.total)

	return (NEga_result)
}


NEI_intake_calc = function(feed_db, dm_perc, source_code) {

	ME_result = ME_intake_calc(feed_db, dm_perc, source_code)
	NEI_result = NULL
	NEI_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		ME = ME_result[i] 
		NEI = ME * 0.644

		NEI_sum = NEI_sum + (NEI * feed.dm_perc)
		NEI_result = c(NEI_result, NEI)
	}

	NEI.total = intake_total_value_calc(dm_perc, NEI_sum)

	NEI_result = c(NEI_result, NEI.total)

	return (NEI_result)
}


UIP_intake_calc = function(feed_db, dm_perc) {

	DMI = DMI_intake_calc(source_code)
	UIP_result = NULL
	UIP_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed_name = as.character(dm_perc[f_id,1])
		feed.dm_perc = as.numeric(dm_perc[f_id, 3])

		DMIfactor = DMIfactor_calc(source_code)

		if (feed_name == '' ) {
			UIP = 0 
		} else {
			UIP = (feed_db[f_id, 'Concentrate...']*((0.167-0.007)+(1+0.01)*feed_db[f_id, 'RUP.1X...CP.']+(4.3+0.17)*DMIfactor+(-0.032+0.09)*feed_db[f_id, 'RUP.1X...CP.']*DMIfactor)+(feed_db[f_id, 'Forage...']*(0.167+1*feed_db[f_id, 'RUP.1X...CP.']+4.3*DMIfactor+(-0.032)*feed_db[f_id, 'RUP.1X...CP.']*DMIfactor)))/100
		}

		UIP_sum  = UIP_sum + (UIP*feed.dm_perc)
		UIP_result = c(UIP_result, UIP)
	}

	UIP.total = intake_total_value_calc(dm_perc, UIP_sum)
	UIP_result  = c(UIP_result, UIP.total)

	return (UIP_result)
}


peNDFfactor_intake_calc = function(feed_db, dm_perc) {

	peNDFfactor_result = NULL
	peNDFfactor_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id,3])
		feed_name = as.character(dm_perc[f_id,1])

		if (feed_name == '') {
			peNDF_factor = 0
		} else if (feed_name != '' & (feed_db[f_id, 'peNDF...NDF.'] < 20)) { 
			peNDF_factor = 1-(20-feed_db[f_id, 'peNDF...NDF.'])*0.025 
		} else { 
			peNDF_factor = 1 
		}

		peNDFfactor_sum = peNDFfactor_sum + (peNDF_factor*feed.dm_perc)
		peNDFfactor_result = c(peNDFfactor_result, peNDF_factor)
	}

	peNDFfactor.total = intake_total_value_calc(dm_perc, peNDFfactor_sum)
	peNDFfactor_result = c(peNDFfactor_result, peNDFfactor.total)

	return (peNDFfactor_result)
}


MP_intake_calc = function(feed_db, dm_perc) {

	dtdn_result = dtdn_intake_calc(feed_db, dm_perc)
	peNDFfactor_result = peNDFfactor_intake_calc(feed_db, dm_perc)
	UIP_result = UIP_intake_calc(feed_db, dm_perc)

	DMI = DMI_intake_calc(source_code)

	MP_result = NULL 
	MP_sum = 0 

	feed_id_list = rownames(dm_perc)

	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed.dm_perc = as.numeric(dm_perc[f_id, 3])

		dtdn = dtdn_result[i]
		peNDF_factor = peNDFfactor_result[i]
		UIP = UIP_result[i]

		MP = (dtdn/100*DMI*1000*0.13*0.64*peNDF_factor/100)+UIP/100*feed_db[f_id, 'CP...DM.']/100*DMI*1000*0.8
		MP_sum = MP_sum + (MP*feed.dm_perc)
		MP_result = c(MP_result, MP)
	}

	MP.total = intake_total_value_calc(dm_perc, MP_sum)
	MP_result = c(MP_result, MP.total)

	return (MP_result)
}


nbalance_intake_calc = function(source_code, feed_db, dm_perc) {

	UIP_result = UIP_intake_calc(feed_db, dm_perc)
	DMI = DMI_intake_calc(source_code)
	recycledn = RECYCLEDN_calc(source_code)	

	peNDFfactor_result = peNDFfactor_intake_calc(feed_db, dm_perc)

	nbalance_result = NULL
	nbalance_sum = 0 

	feed_id_list = rownames(dm_perc)


	for (i in (1:length(feed_id_list))) {

		f_id  = feed_id_list[i]
		feed_name = as.character(dm_perc[f_id,1])
		feed.dm_perc = as.numeric(dm_perc[f_id,3])

		peNDF_factor = peNDFfactor_result[i]
		UIP = UIP_result[i]

		if (feed_name == '') {
			nbalance = 0
		} else {
			nbalance = ((1-UIP/100)*DMI*1000*feed_db[f_id, 'CP...DM.']/100)/6.25+recycledn-(feed_db[f_id, 'TDN...DM.']/100*DMI*1000*0.13*peNDF_factor/100*0.16)
		}

		nbalance_sum = nbalance_sum + (nbalance * feed.dm_perc)
		nbalance_result = c(nbalance_result, nbalance)
	}

	nbalance.total = intake_total_value_calc(dm_perc, nbalance_sum)
	nbalance_result = c(nbalance_result, nbalance.total)

	return (nbalance_result)
}


intake_dm_calc = function(source_code) {

	if (!file.exists(tmp_dm_intake)) {

		feed_db = feed_infor_get(source_code)
		dm_perc =  dm_perc_get(source_code)		

		forage = forage_intake_calc (feed_db, dm_perc, source_code)
	
		cp = cp_intake_calc(feed_db, dm_perc)

		af = af_intake_calc(feed_db, dm_perc) 
		forage.ndf = foragendf_intake_calc(feed_db, dm_perc, source_code)
		ndf.n = ndfn_intake_calc(feed_db, dm_perc)
		iadicp = iadicp_intake_calc(feed_db, dm_perc)
		kdcp = kdcp_intake_calc(feed_db, dm_perc)
		lignin = lignin_intake_calc(feed_db, dm_perc)
		dig.fiber = digestfiber_intake_calc(feed_db, dm_perc)
		tdn1x = tdn1x_intake_calc(feed_db, dm_perc)		

		dtdn = dtdn_intake_calc(feed_db, dm_perc)
		DE = DE_intake_calc(feed_db, dm_perc)

		ME = ME_intake_calc(feed_db, dm_perc, source_code)

		NEma = NEma_intake_calc(feed_db, dm_perc, source_code)
		NEga = NEga_intake_calc(feed_db, dm_perc, source_code)

		NEI = NEI_intake_calc(feed_db, dm_perc, source_code)
		UIP = UIP_intake_calc(feed_db, dm_perc)
		peNDF_factor = peNDFfactor_intake_calc(feed_db, dm_perc)
		MP = MP_intake_calc(feed_db, dm_perc)
		nbalance = nbalance_intake_calc(source_code, feed_db, dm_perc)

		DMI = DMI_intake_calc(source_code)
		DMI_perc = sum(as.numeric(dm_perc[,3]))
		dm_perc = rbind(dm_perc, c('Total', DMI, DMI_perc))

		intake_dm = cbind(dm_perc, forage, cp, af, forage.ndf, ndf.n, iadicp, kdcp, lignin, dig.fiber, 
					tdn1x, dtdn, DE, ME, NEma, NEga, NEI, UIP, peNDF_factor, MP, nbalance)

		colnames(intake_dm) = c('Feed_name', 'DM', 'DMperc', 'Forage', 'CP', 'AF', 'ForageNDF', 'NDFn', 'IADICP', 'KDcp', 'Lignin', 
				'DigestibleFiber', 'TDN1x', 'dTDN', 'DE', 'ME', 'NEma', 'NEga', 'NEl', 'UIP', 'peNDFfactor', 'MP', 'Nbalance')
		
		write.csv(intake_dm, file=tmp_dm_intake, quote=F, row.names=T )

	} else {
		intake_dm = read.csv(tmp_dm_intake, header=T, row.names=1)
	}

	return (intake_dm)
}


FDMI_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFDMI", calc_temp)

	if (!file.exists(var.file)) {
		feed_db = feed_infor_get(source_code)
		dm_perc = dm_perc_get(source_code)	
		forage = forage_intake_calc (feed_db, dm_perc, source_code)
		FDMI = sum(forage[1:(length(forage)-1)])
		dump("FDMI", file = var.file)
	} else {
		source(var.file)
	}
	
	return (FDMI)
}


tdn1x_energy_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%stdn1x", calc_temp)

	if (!file.exists(var.file)) {
		feed_db = feed_infor_get(source_code)
		dm_perc = dm_perc_get(source_code)
		tdn1x_list = tdn1x_intake_calc(feed_db, dm_perc)
		tdn1x = tdn1x_list[length(tdn1x_list)]
		dump("tdn1x", file = var.file)
	} else {
		source(var.file)
	}
	
	return (tdn1x)
}


de1x_energy_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sde1x", calc_temp)

	if (!file.exists(var.file)) {
		tdn1x = tdn1x_energy_calc(source_code)
		de1x = tdn1x/100*4.409
		dump("de1x", file = var.file)
	} else {
		source(var.file)
	}

	return (de1x)
}


me1x_energy_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sme1x", calc_temp)

	if (!file.exists(var.file)) {
		de1x = de1x_energy_calc(source_code)
		if (animal_type == 2 | animal_type ==3) {
			me1x = (de1x*1.01) - 0.45
		} else {
			me1x = (0.82*de1x)
		}
		dump("me1x", file = var.file)
	} else {
		source(var.file)
	}

	return (me1x)
}


NEma1x_energy_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEma1x", calc_temp)

	if  (!file.exists(var.file)) {
		me1x = me1x_energy_calc(source_code)
		NEma1x = 1.37*me1x - 0.138*me1x^2+0.0105*me1x^3-1.12
		dump("NEma1x", file = var.file)
	} else {
		source(var.file)
	}

	return (NEma1x)
}


DietForage_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietForage", calc_temp)

	if (!file.exists(var.file)) {
		intake_dm = intake_dm_calc(source_code)
		forage = as.numeric(intake_dm[,'Forage'])
		forage_total = forage[length(forage)]
		DietForage = forage_total * 100 
		dump("DietForage", file = var.file)
	} else {
		source(var.file)
	}

	return (DietForage)
}


DietCP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietCP", calc_temp)

	if (!file.exists(var.file)) {
		dm_perc = dm_perc_get(source_code)
		feed_db = feed_infor_get(source_code)
		cp = cp_intake_calc(feed_db, dm_perc)
		DietCP = cp[length(cp)]
		dump("DietCP", file = var.file)
	} else {
		source(var.file)
	}

	return (DietCP)
}


dietdry_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdietdry", calc_temp)

	if (!file.exists(var.file)) {
		intake_dm = intake_dm_calc(source_code)	
		DMI = DMI_intake_calc(source_code)
		af = as.numeric(intake_dm[,'AF'])
		af_total = af[length(af)]
		dietdry = DMI/af_total * 100 
		dump("dietdry", file = var.file)
	} else {
		source(var.file)
	}

	return (dietdry)
}


FNDFIpBW_calc  = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFNDFIpBW", calc_temp)

	if (!file.exists(var.file)) {
		intake_dm = intake_dm_calc(source_code)	
		forage.ndf = as.numeric(intake_dm[,'ForageNDF'])
		forage.ndf_total = forage.ndf[length(forage.ndf)]
		FNDFIpBW = forage.ndf_total/FBW*100
		dump("FNDFIpBW", file = var.file)
	} else {
		source(var.file)
	}
	
	return (FNDFIpBW)
}


DietLignin_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietLignin",calc_temp)

	if (!file.exists(var.file)) {
		intake_dm = intake_dm_calc(source_code)	
		lignin = as.numeric(intake_dm[,'Lignin'])	
		DietLignin = lignin[length(lignin)]
		dump("DietLignin", file = var.file)
	} else {
		source(var.file)
	}

	return (DietLignin)
}


DietLigNDF_calc = function(source_code){

	source(source_code)

	var.file = sprintf("%sDietLigNDF", calc_temp)

	if (!file.exists(var.file)) {
		DietLignin = DietLignin_calc (source_code)
		dietndf = dietndf_calc(source_code)
		DietLigNDF = DietLignin/dietndf * 100 
		dump("DietLigNDF", file = var.file)
	} else {
		source(var.file)
	}


	return (DietLigNDF)
}


dTDN_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sdTDN", calc_temp)

	if (!file.exists(var.file)) {
		intake_dm = intake_dm_calc(source_code)	
		dTDN = as.numeric(intake_dm[,'dTDN'])
		dTDN = dTDN[length(dTDN)]
		dump("dTDN", file = var.file)
	} else {
		source(var.file)
	}

	return (dTDN)
}


intake_carbprot_p_day = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_intake_p_day)) {

		intake_carbprot_p_DM_table = intake_carbprot_p_DM(source_code)

		feed_db = feed_infor_get(source_code)
		dm_perc =  dm_perc_get(source_code)

		intake_carbprot_table = NULL 
		intake_carbprot_total = c('000', 'total', rep(0, 18))

		feed_id_list = rownames(dm_perc)

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(dm_perc[f_id,1])
			f_dm = as.numeric(dm_perc[f_id,2])

			f_ca = as.numeric(feed_db[f_id, 'Ca....'])
			f_ca_bio = as.numeric(feed_db[f_id, 'Ca.Bio'])
			f_p = as.numeric(feed_db[f_id, 'P....'])
			f_p_bio = as.numeric(feed_db[f_id, 'P.Bio'])
			f_k = as.numeric(feed_db[f_id, 'K....'])
			f_k_bio = as.numeric(feed_db[f_id, 'K.Bio'])

			cho.a = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'CHO.pools.A']) * 10,0)
			cho.b1 = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'CHO.pools.B1']) * 10,0)
			cho.b2 = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'CHO.pools.B2']) * 10,0)
			cho.c = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'CHO.pools.C']) * 10,0)

			prot.a = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Protein.pools.A']) * 10,0)
			prot.b1 = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Protein.pools.B1']) * 10,0)
			prot.b2 = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Protein.pools.B2']) * 10,0)
			prot.b3 = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Protein.pools.B3']) * 10,0)
			prot.c = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Protein.pools.C']) * 10,0)

			EE = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'EE']) * 10,0)
			Ash = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Ash']) * 10,0)
			total_f = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Total.F']) * 10,0)
			total_cho = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Total.CHO']) * 10,0) 
			total_nfc = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Total.NFC']) * 10,0)
			total_prot = round(f_dm * as.numeric(intake_carbprot_p_DM_table[f_id, 'Total.protein']) * 10,0)

			avail_ca = f_ca/100*f_ca_bio*f_dm*1000
			avail_p = f_p/100*f_p_bio*f_dm*1000
			avail_k = f_k/100*f_k_bio*f_dm*1000

			row_data = c(f_id, f_name, cho.a, cho.b1, cho.b2, cho.c, prot.a, prot.b1, prot.b2, prot.b3, prot.c, 
					EE, Ash, total_f, total_cho, total_nfc, total_prot, avail_ca, avail_p, avail_k)

			intake_carbprot_table = rbind(intake_carbprot_table, row_data)

			for (i in (3:length(row_data))) {					
				intake_carbprot_total[i] = as.numeric(intake_carbprot_total[i]) + as.numeric(row_data[i])
				}
			}
	
		intake_carbprot_table = rbind(intake_carbprot_table, intake_carbprot_total)

		colnames(intake_carbprot_table) = c('Feed_ID', 'Feed_name', 'CHO.pools.A', 'CHO.pools.B1', 'CHO.pools.B2', 'CHO.pools.C', 
			'Protein.pools.A', 'Protein.pools.B1', 'Protein.pools.B2', 'Protein.pools.B3', 'Protein.pools.C', 
			'EE', 'Ash', 'Total.F', 'Total.CHO', 'Total.NFC', 'Total.protein', 'Available.Ca', 'Available.P', 'Available.K')

		rownames(intake_carbprot_table) = intake_carbprot_table[,1]
		intake_carbprot_table = intake_carbprot_table[,2:ncol(intake_carbprot_table)]
		write.csv(intake_carbprot_table, file=tmp_intake_p_day, row.names=T, quote=F)
	} else {
		intake_carbprot_table = read.csv(file=tmp_intake_p_day, header=T, row.names=1)
	}

	return (intake_carbprot_table)
}


TotalCP_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sTotalCP", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		TotalCP = intake_table[nrow(intake_table), 'Total.protein']
		dump("TotalCP", file = var.file)
	} else {
		source(var.file)
	}


	return (TotalCP)
}


Casup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCasup", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		Casup = intake_table[nrow(intake_table), 'Available.Ca']
		dump("Casup", file = var.file)
	} else {
		source(var.file)
	}

	return (Casup)	
}

Psup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPsup", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		Psup = intake_table[nrow(intake_table),'Available.P']
		dump("Psup", file = var.file)
	} else {
		source(var.file)
	}
	
	return (Psup)
}


Ksup_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sKsup", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		Ksup = intake_table[nrow(intake_table),'Available.K']
		dump("Ksup", file = var.file)
	} else {
		source(var.file)
	}

	return (Ksup)
}


DietNFC_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietNFC", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		total_nfc = intake_table[nrow(intake_table),'Total.NFC']
		dm_perc = dm_perc_get(source_code)
		DMI = DMI_intake_calc(source_code)
		DietNFC = total_nfc/DMI*0.1
		dump("DietNFC", file = var.file)
	} else {
		source(var.file)
	}

	return (DietNFC)
}


DietSOLP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietSOLP", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		prot_value = sum(intake_table[nrow(intake_table), 'Protein.pools.A']) + sum(intake_table[nrow(intake_table), 'Protein.pools.B1'])
		TotalCP = TotalCP_calc(source_code)
		DietSOLP = prot_value/TotalCP*100
		dump("DietSOLP", file = var.file)
	} else {
		source(var.file)
	}

	return (DietSOLP)
}


DietA_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietA", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		cho.a = sum(intake_table[nrow(intake_table), 'CHO.pools.A'])
		total_f = intake_table[nrow(intake_table), 'Total.F']
		DietA = cho.a/total_f*100
		dump("DietA", file = var.file)
	} else {
		source(var.file)
	}
	
	return (DietA)
}


DietB1_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sDietB1", calc_temp)

	if (!file.exists(var.file)) {
		intake_table = intake_carbprot_p_day(source_code)
		cho.b1 = sum(intake_table[nrow(intake_table), 'CHO.pools.B1' ])
		total_f = intake_table[nrow(intake_table), 'Total.F']
		DietB1 = cho.b1/total_f*100
		dump("DietB1", file = var.file)
	} else {
		source(var.file)
	}

	
	return (DietB1)
}


rumen_passage_rate_calc = function(source_code) {

	source(source_code) 

	if (!file.exists(tmp_rumen_passage_rate)) {
		Kpc = Kpc_calc(source_code) 		
		Kpf = Kpf_calc(source_code) 
		AF = 1 

		feed_db = feed_infor_get(source_code)
		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)
		feed_ids = rownames(feed_data)

		passage_table = NULL 

		for (i in (1:length(feed_ids))) {

			f_id =  as.character(feed_ids[i])
			f_name = as.character(feed_db[f_id, 'Feed_name'])

			f_concentrate = as.numeric(feed_db[f_id, "Concentrate..."])
			f_forage = as.numeric(feed_db[f_id, "Forage..."    ])

			Kp = round((f_concentrate*Kpc+f_forage*Kpf)/100*AF, 4)

			rate.cho_a = as.numeric(feed_db[f_id, "CHO.A....hr."])/100
			rate.cho_b1 = as.numeric(feed_db[f_id, "CHO.B1....hr."])/100
			rate.cho_b2 = as.numeric(feed_db[f_id, "CHO.B2....hr."])/100
			rate.cho_c = as.numeric(feed_db[f_id, "CHO.C....hr."])/100

			rate.protein_a = as.numeric(feed_db[f_id, "Protein.A....hr."])/100
			rate.protein_b1 = as.numeric(feed_db[f_id, "Protein.B1....hr."])/100
			rate.protein_b2 = as.numeric(feed_db[f_id, "Protein.B2....hr."])/100
			rate.protein_b3 = as.numeric(feed_db[f_id, "Protein.B3....hr."])/100
			rate.protein_c = as.numeric(feed_db[f_id, "Protein.C....hr."])/100

			row_data = c(f_name, AF, Kp, rate.cho_a, rate.cho_b1, rate.cho_b2, rate.cho_c, rate.protein_a, rate.protein_b1, rate.protein_b2, rate.protein_b3, rate.protein_c)

			passage_table = rbind(passage_table, row_data)
		}

		colnames(passage_table) = c('Feed_name', 'Af', 'kp', 'CHO.A.rates', 'CHO.B1.rates', 'CHO.B2.rates', 'CHO.C.rates',
			'Protein.A.rates', 'Protein.B1.rates', 'Protein.B2.rates', 'Protein.B3.rates', 'Protein.C.rates')
		rownames(passage_table) = feed_ids 

		write.csv(passage_table, file=tmp_rumen_passage_rate, quote=F, row.names=T)
	} else {
		passage_table = read.csv(file=tmp_rumen_passage_rate, header=T, row.names=1)
	}

	return (passage_table)
}


FpBW_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sFpBW", calc_temp)

	if (!file.exists(var.file)) {
		FDMI = FDMI_calc(source_code)
		FpBW = FDMI/FBW*100
		dump("FpBW", file = var.file)
	} else {
		source(var.file)
	}

	return (FpBW)
}


CpBW_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sCpBW", calc_temp)

	if (!file.exists(var.file)) {
		DMI = DMI_intake_calc(source_code)
		FDMI = FDMI_calc(source_code)
		CpBW = (DMI-FDMI)/FBW *100
		dump("CpBW", file = var.file)
	} else {
		source(var.file)
	}
	
	return (CpBW)
}


Kpf_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sKpf", calc_temp)

	if (!file.exists(var.file)) {
		FpBW = FpBW_calc(source_code)
		FDMI = FDMI_calc(source_code)
		CpBW = CpBW_calc(source_code)
		Kpf = (2.365+0.214*FpBW+0.734*CpBW+0.069*FDMI)/100
		dump("Kpf", file = var.file)
	} else {
		source(var.file)
	}

		return (Kpf)
}

Kpc_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sKpc", calc_temp)

	if (!file.exists(var.file)) {
		FpBW = FpBW_calc(source_code)
		CpBW = CpBW_calc(source_code)
		Kpc = (1.169+1.375*FpBW+1.721*CpBW)/100
		dump("Kpc", file = var.file)
	} else {
		source(var.file )
	}
	
	return (Kpc)
}

Kpl_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sKpl", calc_temp)
	
	if (!file.exists(var.file)) {
		FpBW = FpBW_calc(source_code)
		CpBW = CpBW_calc(source_code)
		FDMI = FDMI_calc(source_code)
		Kpl = (4.524+0.223*FpBW+2.046*CpBW+0.344*FDMI)/100
		dump("Kpl", file = var.file)
	} else {
		source(var.file)
	}

	
	return (Kpl)
}


adj_rumen_passage_rate_by_ph_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_adj_rumen_passage_rate_by_ph)) {
		
		feed_db = feed_infor_get(source_code)
		dm_perc =  dm_perc_get(source_code)

		adj_rumen_passage_rate_by_ph = NULL

		feed_id_list = rownames(dm_perc)

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(dm_perc[f_id,1])
			f_dm = as.numeric(dm_perc[f_id,2]) 

			f_ndf = as.numeric(feed_db[f_id,"NDF...DM."])
			f_pendf = as.numeric(feed_db[f_id,"peNDF...NDF."])

			ndf = f_dm*f_ndf/100
			pendf = ndf*f_pendf/100

			row_data = c(f_name, f_dm, ndf, pendf)

			adj_rumen_passage_rate_by_ph  = rbind(adj_rumen_passage_rate_by_ph, row_data)
		}

		colnames(adj_rumen_passage_rate_by_ph) = c('Feed_name', 'Intake', 'NDF.kg.d.', 'peNDF.kg.d.')
		rownames(adj_rumen_passage_rate_by_ph) = feed_id_list

		write.csv(adj_rumen_passage_rate_by_ph, file = tmp_adj_rumen_passage_rate_by_ph, quote=F, row.names=T)
	} else {
		adj_rumen_passage_rate_by_ph = read.csv(file=tmp_adj_rumen_passage_rate_by_ph, header=T, row.names=1)
	}

	return (adj_rumen_passage_rate_by_ph)
}


KMsc_calc = function() {

	KMsc = 0.05

	return (KMsc)
}


YGsc_calc = function() {

	YGsc = 0.4

	return (YGsc)
}


rumen_passage_intake_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sintake_total", calc_temp)

	if (!file.exists(var.file)) {
		adj_rumen_passage_rate_by_ph = adj_rumen_passage_rate_by_ph_calc(source_code)
		intake_total = sum(as.numeric(adj_rumen_passage_rate_by_ph[,'Intake']))
		dump("intake_total", file = var.file)
	} else {
		source(var.file)
	}

	return (intake_total)
}


NDFI_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sNDFI", calc_temp)

	if (!file.exists(var.file)) {
		adj_rumen_passage_rate_by_ph = adj_rumen_passage_rate_by_ph_calc(source_code)
		NDFI = sum(as.numeric(adj_rumen_passage_rate_by_ph[,'NDF.kg.d.']))
		dump("NDFI", file = var.file)
	} else {
		source(var.file)
	}

	return (NDFI)
}


rumen_passage_pendf_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%spendf_total", calc_temp)

	if (!file.exists(var.file)) {
		adj_rumen_passage_rate_by_ph = adj_rumen_passage_rate_by_ph_calc(source_code)
		pendf_total = sum(as.numeric(adj_rumen_passage_rate_by_ph[,'peNDF.kg.d.']))
		dump("pendf_total", file = var.file)
	} else {
		source(var.file)
	}

	return (pendf_total)

} 


DietpeNDF_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sDietpeNDF", calc_temp)
	
	if (!file.exists(var.file)) {
		rumen_intake = rumen_passage_intake_total_calc(source_code)
		rumen_pendf = rumen_passage_pendf_total_calc(source_code)
		DietpeNDF = rumen_pendf/rumen_intake * 100 
		dump("DietpeNDF", file = var.file)
	} else {
		source(var.file)
	}

	return (DietpeNDF)
}


NDFdiet_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNDFdiet", calc_temp)

	if (!file.exists(var.file)) {
		intake_total = rumen_passage_intake_total_calc(source_code)
		NDFI = NDFI_calc(source_code)
		NDFdiet = NDFI/intake_total * 100 
		dump("NDFdiet", file =var.file)
	} else {
		source(source_code)
	}
	
	return (NDFdiet)
}


peNDF_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%speNDF", calc_temp)

	if (!file.exists(var.file)) {
		intake_total = rumen_passage_intake_total_calc(source_code)
		rumen_peNDF = rumen_passage_pendf_total_calc (source_code)
		peNDF = rumen_peNDF/intake_total * 100 
		dump("peNDF", file = var.file)
	} else {
		source(var.file)
	}

	return (peNDF)
}


pH_calc = function (source_code) {

	source(source_code)

	var.file = sprintf("%spH", calc_temp)

	if (!file.exists(var.file)){
		peNDF = peNDF_calc(source_code)
		if (peNDF < 24.5) {
			pH = 5.425+0.04229*peNDF
		} else {
			pH = 6.46
		}
		dump("pH", file = var.file)
	} else {
		source(var.file)
	}

	return (pH)
}


KMscprime_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sKMscprime", calc_temp)

	if (!file.exists(var.file)) {
		pH = pH_calc(source_code)
		KMscprime = 0.1409-0.0135*pH
		dump("KMscprime", file = var.file)
	} else {
		source(var.file)
	}

	return (KMscprime)
}


YGscprime_calc = function(source_code) {

	source(source_code)
	var.file = sprintf("%sYGscprime", calc_temp)

	if (!file.exists(var.file)) {
		pH = pH_calc (source_code)
		YGscprime = -0.1058+0.0752*pH 
		dump("YGscprime", file = var.file)
	} else {
		source(var.file)
	}
	
	return (YGscprime)
}


RelY_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sRelY", calc_temp)

	if (!file.exists(var.file)) {
		pH = pH_calc(source_code) 
		if (pH>5.7) {
			RelY = (1-exp(-5.624*(pH-5.7)^0.909))/0.9968 
		} else {
			RelY = 0
		}
		dump("RelY", file = var.file)
	} else {
		source(var.file)
	}

	return (RelY)
}


rumen_passage_rate_by_ph_calc = function(source_code) { 

	source(source_code)

	if (!file.exists(tmp_rumen_passage_rate_by_ph)) {

		rumen_passage_rate = rumen_passage_rate_calc (source_code)

		KMsc = KMsc_calc()
		YGsc = YGsc_calc()
		pH = pH_calc(source_code)
		RelY = RelY_calc(source_code)
		KMscprime = KMscprime_calc(source_code)
		YGscprime = YGscprime_calc(source_code)

		rumen_passage_rate_ph = NULL
		feed_id_list = rownames(rumen_passage_rate)

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(rumen_passage_rate[f_id,'Feed_name'])
			f_b2 = as.numeric(rumen_passage_rate[f_id,'CHO.B2.rates'])

			if (f_b2 == 0) {
				Y1 = 0 					
			} else {
				Y1 = 1/(KMsc/(f_b2-KMsc*YGsc)+1/YGsc)
			}

			if (pH > 5.7)  {
				Y = RelY * Y1
			} else {
				Y = 0
			}

			if (pH > 5.7) {
				b2_kd = KMscprime*Y*YGscprime/(YGscprime-Y)+KMscprime*YGscprime
			} else {
				b2_kd = 0 
			}

			final_b2_kd = min(f_b2, b2_kd)
		
			row_data = c( f_name, f_b2, Y1, Y, b2_kd, final_b2_kd) 
			rumen_passage_rate_ph = rbind(rumen_passage_rate_ph, row_data)
		}

		colnames(rumen_passage_rate_ph) = c('Feed_name', 'B2_kd', 'Y1', 'Y.', 'B2_kd.', 'Final_B2_kd')
		rownames(rumen_passage_rate_ph) = feed_id_list

		write.csv(rumen_passage_rate_ph, file=tmp_rumen_passage_rate_by_ph, quote=F, row.names=T)
	} else {
		rumen_passage_rate_ph = read.csv(file=tmp_rumen_passage_rate_by_ph, header=T, row.names=1)
	}

	return (rumen_passage_rate_ph)
}


rumen_degradation_calc = function(source_code) {

	source(source_code) 

	if (!file.exists(tmp_rumen_degradation)) {

		dm_perc = dm_perc_get(source_code)

		intake_carb_prot = intake_carbprot_p_day(source_code)
		passage_rate = rumen_passage_rate_calc(source_code) 
		passage_rate_ph = rumen_passage_rate_by_ph_calc(source_code)

		rumen_degradation_table = NULL 

		feed_id_list = rownames(dm_perc)

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(dm_perc[f_id,1])
			f_dm = as.numeric(dm_perc[f_id,2])

			kp = as.numeric(passage_rate[f_id, 'kp'])

			cho.a = as.numeric(intake_carb_prot [f_id, 'CHO.pools.A'])
			cho.b1 = as.numeric(intake_carb_prot [f_id, 'CHO.pools.B1'])
			cho.b2 = as.numeric(intake_carb_prot [f_id, 'CHO.pools.B2'])
			cho.c = as.numeric(intake_carb_prot [f_id, 'CHO.pools.C'])

			prot.a = as.numeric(intake_carb_prot [f_id, 'Protein.pools.A'])
			prot.b1 = as.numeric(intake_carb_prot [f_id, 'Protein.pools.B1'])
			prot.b2 = as.numeric(intake_carb_prot [f_id, 'Protein.pools.B2'])
			prot.b3 = as.numeric(intake_carb_prot [f_id, 'Protein.pools.B3'])
			prot.c = as.numeric(intake_carb_prot [f_id, 'Protein.pools.C'])

			rate.cho.a = as.numeric(passage_rate[f_id, 'CHO.A.rates'])
			rate.cho.b1 = as.numeric(passage_rate[f_id, 'CHO.B1.rates'])
			rate.cho.b2 = as.numeric(passage_rate_ph[f_id, 'Final_B2_kd'])
			rate.cho.c = as.numeric(passage_rate[f_id, 'CHO.C.rates'])

			rate.prot.a = as.numeric(passage_rate[f_id, 'Protein.A.rates'])
			rate.prot.b1 = as.numeric(passage_rate[f_id, 'Protein.B1.rates'])
			rate.prot.b2 = as.numeric(passage_rate[f_id, 'Protein.B2.rates'])
			rate.prot.b3 = as.numeric(passage_rate[f_id, 'Protein.B3.rates'])
			rate.prot.c = as.numeric(passage_rate[f_id, 'Protein.C.rates'])


			if (f_dm == 0) {
				rdca = 0 
				rdcb1 = 0
				rdcb2 = 0

				rdpa = 0
				rdpb1 = 0 
				rdpb2 = 0 
				rdpb3 = 0 
			
				reca = 0 
				recb1 = 0 
				recb2 = 0 
				recc = 0

				repb1 = 0 
				repb2 = 0
				repb3 = 0 
				repc = 0 			

			} else {
				rdca = cho.a*(rate.cho.a/(rate.cho.a+kp))
				rdcb1 = cho.b1 * (rate.cho.b1/(rate.cho.b1+kp))
				rdcb2 = cho.b2 * (rate.cho.b2/(rate.cho.b2+kp))

				rdpa = prot.a * (rate.prot.a/(rate.prot.a + kp))
				rdpb1 = prot.b1 * (rate.prot.b1/(rate.prot.b1+kp))
				rdpb2 = prot.b2 * (rate.prot.b2/(rate.prot.b2+kp))
				rdpb3 = prot.b3 * (rate.prot.b3/(rate.prot.b3+kp))

				reca = cho.a * (kp/(kp+rate.cho.a))
				recb1 = cho.b1 * (kp/(kp+rate.cho.b1))
				recb2 = cho.b2 * (kp/(kp+rate.cho.b2))
				recc = cho.c * (kp/(kp+rate.cho.c))

				repb1 = prot.b1 * (kp/(kp+rate.prot.b1))
				repb2 = prot.b2 * (kp/(kp+rate.prot.b2))
				repb3 = prot.b3 * (kp/(kp+rate.prot.b3))
				repc = prot.c * (kp/(kp+rate.prot.c))
			}

			rdpep = sum(rdpb1, rdpb2, rdpb3)

			row_data = c(f_name, rdca, rdcb1, rdcb2, rdpa, rdpb1, rdpb2, rdpb3, rdpep, reca, recb1, recb2, recc, repb1, repb2, repb3, repc)
			rumen_degradation_table = rbind (rumen_degradation_table, row_data)
		}

		colnames(rumen_degradation_table) = c('Feed_name', 'RDCA', 'RDCB1', 'RDCB2', 'RDPA', 'RDPB1', 'RDPB2', 'RDPB3', 'RDPEP', 
										'RECA', 'RECB1', 'RECB2', 'RECC', 'REPB1', 'REPB2', 'REPB3', 'REPC')
		rownames(rumen_degradation_table) = feed_id_list

		write.csv(rumen_degradation_table, file=tmp_rumen_degradation, quote=F, row.names=T)
	} else { 
		rumen_degradation_table = read.csv(file=tmp_rumen_degradation, header=T, row.names=1)
	}

	return (rumen_degradation_table)
}


RDCA_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDCA = sum(as.numeric(rumen_degr_table[,'RDCA']))

	return (RDCA)
}


RDCB1_calc = function(source_code) {
	
	rumen_degr_table = rumen_degradation_calc(source_code)
	RDCB1 = sum(as.numeric(rumen_degr_table[,'RDCB1']))

	return (RDCB1)
}


RDCB2_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDCB2 = sum(as.numeric(rumen_degr_table[,'RDCB2']))

	return (RDCB2)
}


RDPA_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDPA = sum(as.numeric(rumen_degr_table[,'RDPA']))

	return (RDPA)
}


RDPB1_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDPB1 = sum(as.numeric(rumen_degr_table[,'RDPB1']))

	return (RDPB1)
}


RDPB2_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDPB2 = sum(as.numeric(rumen_degr_table[,'RDPB2']))

	return (RDPB2)
}


RDPB3_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDPB3 = sum(as.numeric(rumen_degr_table[,'RDPB3']))

	return (RDPB3)
}

RDPEP_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RDPEP = sum(as.numeric(rumen_degr_table[,'RDPEP']))

	return (RDPEP)
}


RECA_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RECA = sum(as.numeric(rumen_degr_table[,'RECA']))

	return (RECA)
}


RECB1_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RECB1 = sum(as.numeric(rumen_degr_table[,'RECB1']))

	return (RECB1)
}


RECB2_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RECB2 = sum(as.numeric(rumen_degr_table[,'RECB2']))

	return (RECB2)
}


RECC_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	RECC = sum(as.numeric(rumen_degr_table[,'RECC']))

	return (RECC)
}


REPB1_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	REPB1 = sum(as.numeric(rumen_degr_table[,'REPB1']))

	return (REPB1)
}


REPB2_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	REPB2 = sum(as.numeric(rumen_degr_table[,'REPB2']))

	return (REPB2)
}


REPB3_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	REPB3 = sum(as.numeric(rumen_degr_table[,'REPB3']))

	return (REPB3)
}


REPC_calc = function(source_code) {

	rumen_degr_table = rumen_degradation_calc(source_code)
	REPC = sum(as.numeric(rumen_degr_table[,'REPC']))

	return (REPC)
}


DietDIP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDietDIP", calc_temp)

	if (!file.exists(var.file)) {
		rumen_degradation_table = rumen_degradation_calc(source_code)
		RDPA = sum(as.numeric(rumen_degradation_table[,'RDPA']))
		RDPB1 = sum(as.numeric(rumen_degradation_table[,'RDPB1']))
		RDPB2 = sum(as.numeric(rumen_degradation_table[,'RDPB2']))
		RDPB3 = sum(as.numeric(rumen_degradation_table[,'RDPB3']))	
		RDP = sum(RDPA, RDPB1, RDPB2, RDPB3)
		TotalCP  = as.numeric(TotalCP_calc(source_code))
		DietDIP = RDP/TotalCP * 100 
		dump("DietDIP", file = var.file)
	} else {
		source(var.file)
	}

	
	return (DietDIP)
}


KMnsc_calc = function() {

	KMnsc = 0.15 

	return (KMnsc)
}


YGnsc_calc = function() {

	YGnsc = 0.4 

	return (YGnsc)
}


YG1mod_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sYG1mod", calc_temp)

	if (!file.exists(var.file)) {
		peNDF = peNDF_calc (source_code)
		YGsc = YGsc_calc()
		if (peNDF < 20) {
			YG1mod = YGsc * (1-(20-peNDF)*0.025)
		} else {
			YG1mod = YGsc 
		}
		dump("YG1mod", file = var.file)
	} else {
		source(var.file)
	}

	return (YG1mod)
}


YG2mod_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sYG2mod", calc_temp)

	if (!file.exists(var.file)) {
		peNDF = peNDF_calc(source_code)
		YGnsc = YGnsc_calc()
		if (peNDF < 20) {
			YG2mod = YGnsc*(1-(20-peNDF)*0.025)
		} else {
			YG2mod = YGnsc
		}
		dump("YG2mod", file = var.file)
	} else {
		source(var.file)
	}

	return (YG2mod)
}


PepUpRate_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPepUpRate", calc_temp)

	if (!file.exists(var.file)) {
		source(maintain_requirement_module)
		ionophore = ionophore_calc(source_code)
		if (ionophore == 1){
			PepUpRate = 7*2/3
		} else {
			PepUpRate = 7
		}
		dump("PepUpRate", file = var.file)
	} else {
		source(var.file)
	}
	
	return (PepUpRate)
}


Ratio_calc = function(source_code) {

	RDPEP = RDPEP_calc(source_code)
	RDCA = RDCA_calc(source_code)
	RDCB1 = RDCB1_calc (source_code)

	value_1 = RDPEP/(RDPEP + RDCA + RDCB1)
	value_2 = 0.18

	Ratio = min(value_1, value_2)

	return (Ratio)
}


Imp_calc = function(source_code) {

	Ratio = Ratio_calc(source_code)

	Imp = exp(0.404*log(Ratio*100)+1.942)

	return(Imp)
}


NFCbact_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sNFCbact", calc_temp)

	if (!file.exists(var.file)) {
		ca_bact_yield = ca_bact_yield_calc(source_code)
		cb1_bact_yield = cb1_bact_yield_calc(source_code) 
		NFCbact = ca_bact_yield + cb1_bact_yield
		dump("NFCbact", file = var.file)
	} else {
		source(var.file)
	}

	return (NFCbact)
}


NFCBactMass_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sNFCBactMass", calc_temp)

	if (!file.exists(var.file)) {
		Kpf = Kpf_calc (source_code)
		NFCbact = NFCbact_calc(source_code)
		NFCBactMass = NFCbact/(Kpf*24)	
		dump("NFCBactMass", file = var.file)
	} else {
		source(var.file)
	}

	return (NFCBactMass)
}


NFCBactPepUp_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNFCBactPepUp", calc_temp)

	if (!file.exists(var.file)) {
		NFCBactMass = NFCBactMass_calc(source_code)
		PepUpRate = PepUpRate_calc(source_code)
		NFCBactPepUp = NFCBactMass * PepUpRate/100
		dump("NFCBactPepUp", file = var.file)
	} else {
		source(var.file)
	}

	return (NFCBactPepUp)
}


RDPEPh_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sRDPEPh", calc_temp)

	if (!file.exists(var.file)) {
		RDPEP = RDPEP_calc(source_code)
		RDPEPh = RDPEP/24
		dump("RDPEPh", file = var.file)
	} else {
		source(var.file)
	}

	return (RDPEPh)
}


GrowthTime_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sGrowthTime", calc_temp)

	if (!file.exists(var.file)){
		Kpl = Kpl_calc (source_code)
		GrowthTime = 1/(1-Kpl)
		dump("GrowthTime", file = var.file)		
	} else {
		source(var.file)
	}

	return (GrowthTime)
}


DisappTime_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sDisappTime", calc_temp)

	if (!file.exists(var.file)) {
		GrowthTime = GrowthTime_calc(source_code)
		RDPEPh = RDPEPh_calc(source_code)
		NFCBactPepUp = NFCBactPepUp_calc(source_code)
		DisappTime = log(((GrowthTime-1)*RDPEPh)/NFCBactPepUp+1)/log(1+(GrowthTime-1)/3600)/3600
		dump("DisappTime", file = var.file)	
	} else {
		source(var.file)
	}

	
	return (DisappTime)
}


PepX_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPepX", calc_temp)

	if (!file.exists(var.file)) {
		NFCBactPepUp = NFCBactPepUp_calc(source_code)
		DisappTime = DisappTime_calc(source_code)
		PepX = NFCBactPepUp*DisappTime
		dump("PepX", file = var.file)	
	} else {
		source(var.file)
	}
	
	return (PepX)
}


PeptideUp_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPeptideUP", calc_temp)

	if (!file.exists(var.file)) {
		PepX = PepX_calc(source_code)
		RDPEPh = RDPEPh_calc(source_code)
		if (PepX > RDPEPh) {
			PeptideUp = RDPEPh * 24
		} else {
			PeptideUp = PepX*24
		}
		dump("PeptideUP", file = var.file)
	} else {
		source(var.file)
	}

	return (PeptideUp)
}


PeptidePass_calc = function(source_code) {

	source(source_code)

	var.file = sprintf ("%sPeptidePass", calc_temp)

	if (!file.exists(var.file)) {
		RDPEP = RDPEP_calc(source_code)
		PeptideUp = PeptideUp_calc(source_code)
		PeptidePass = RDPEP - PeptideUp
		dump("PeptidePass", file = var.file)
	} else {
		source(var.file)
	}

	return (PeptidePass)
}


PeptideAcc_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPeptideAcc", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUp = PeptideUp_calc(source_code)
		PeptidePass = PeptidePass_calc(source_code)
		PeptideAcc = PeptideUp + PeptidePass 
		dump("PeptideAcc", file = var.file)
	} else {
		source(var.file)
	}

	return (PeptideAcc)
}


PeptideUpN_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPeptideUpN", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUp = PeptideUp_calc(source_code)
		PeptideUpN = PeptideUp/6.25
		dump("PeptideUpN", file = var.file)
	} else {
		source(var.file)
	}

	return (PeptideUpN)
}


PeptideReqN_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPeptideReqN", calc_temp)

	if (!file.exists(var.file)) {
		NFCbact = NFCbact_calc(source_code)
		PeptideReqN = 0.66 * NFCbact * 0.1
		dump("PeptideReqN", file =var.file)
	} else {
		source(var.file)
	}

	return (PeptideReqN)
}


PEPBALp_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPEPBALp", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUpN = PeptideUpN_calc(source_code)
		PeptideReqN = PeptideReqN_calc(source_code)
		PEPBALp = PeptideUpN / PeptideReqN * 100 
		dump("PEPBALp", file = var.file)
	} else {
		source(var.file)
	}

	return (PEPBALp)
}


PepBal_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sPepBal", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUpN = PeptideUpN_calc(source_code)
		PeptideReqN = PeptideReqN_calc(source_code)
		PepBal = PeptideUpN - PeptideReqN 
		dump("PepBal", file = var.file)
	} else {
		source(var.file)
	}

	return (PepBal)
}



NFC_NH3_REQ_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNFC_NH3_REQ", calc_temp)

	if (!file.exists(var.file)) {
		NFCbact = NFCbact_calc(source_code)
		NFC_NH3_REQ = 0.34*NFCbact*0.625/6.25
		dump("NFC_NH3_REQ", file = var.file)
	} else {
		source(var.file)
	}

	return (NFC_NH3_REQ)
}


NH3_BACT_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNH3_BACT",calc_temp)

	if (!file.exists(var.file)) {
		PepBal = PepBal_calc(source_code)
		NH3_BACT = max(0, PepBal)
		dump("NH3_BACT", file = var.file)
	} else {
		source(var.file)
	}
	
	return (NH3_BACT)
}


NH3_DIET_calc = function(source_code) {

	source(source_code)

	var.file =sprintf("%sNH3_DIET", calc_temp)

	if (!file.exists(var.file)) {
		RDPA = RDPA_calc (source_code)
		NH3_DIET = RDPA/6.25
		dump("NH3_DIET", file = var.file)
	} else {
		source(var.file)
	}

	return (NH3_DIET)
}


FC_NH3_AVAIL_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFC_NH3_AVAIL", calc_temp)

	if (!file.exists(var.file)) {
		NH3_BACT = NH3_BACT_calc(source_code)
		NH3_DIET = NH3_DIET_calc(source_code)
		RECYCLEDN = RECYCLEDN_calc(source_code)
		NFC_NH3_REQ = NFC_NH3_REQ_calc(source_code)
		FC_NH3_AVAIL = max(0, (NH3_BACT+NH3_DIET+RECYCLEDN-NFC_NH3_REQ))
		dump("FC_NH3_AVAIL", file = var.file)
	} else {
		source(var.file)
	}

	return (FC_NH3_AVAIL) 
}


FC_NH3_REQ_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFC_NH3_REQ", calc_temp) 

	if (!file.exists(var.file)) {
		FCbact = FCbact_calc(source_code)
		FC_NH3_REQ = FCbact*0.625/6.25
		dump("FC_NH3_REQ", file = var.file)
	} else {
		source(var.file)
	}

	return (FC_NH3_REQ)
}


BACTNBALANCE_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBACTNBALANCE", calc_temp) 

	if (!file.exists(var.file)) {
		PeptideUpN = PeptideUpN_calc(source_code)
		NH3_DIET = NH3_DIET_calc(source_code)
		RECYCLEDN = RECYCLEDN_calc(source_code)
		PeptideReqN = PeptideReqN_calc(source_code)
		NFC_NH3_REQ = NFC_NH3_REQ_calc(source_code)
		FC_NH3_REQ = FC_NH3_REQ_calc(source_code)
		BACTNBALANCE = (PeptideUpN+NH3_DIET+RECYCLEDN) - (PeptideReqN + NFC_NH3_REQ+FC_NH3_REQ)
		dump("BACTNBALANCE", file = var.file)
	} else {
		source(var.file)
	}

		return (BACTNBALANCE)
}


bact_avail_calc = function(source_code) { 

	source(source_code)

	var.file = sprintf("%sbact_avail", calc_temp)

	if (!file.exists(var.file)) {
		NH3_DIET = NH3_DIET_calc(source_code)
		RECYCLEDN = RECYCLEDN_calc(source_code)
		PeptideUpN = PeptideUpN_calc(source_code)
		bact_avail = NH3_DIET + RECYCLEDN + PeptideUpN 
		dump("bact_avail", file = var.file)
	} else {
		source(var.file)
	}

	return (bact_avail)
}


bact_req_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sbact_req", calc_temp)

	if (!file.exists(var.file)) {
		FC_NH3_REQ = FC_NH3_REQ_calc(source_code)
		PeptideReqN = PeptideReqN_calc(source_code)
		NFC_NH3_REQ = NFC_NH3_REQ_calc(source_code)
		bact_req = FC_NH3_REQ + PeptideReqN + NFC_NH3_REQ 
		dump("bact_req", file = var.file)
	} else {
		source(var.file)
	}

	return (bact_req)
}


RNB_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sRNB", calc_temp)

	if (!file.exists(var.file)) {
		bact_avail = bact_avail_calc(source_code)
		bact_req = bact_req_calc(source_code)
		RNB = bact_avail - bact_req 
		dump("RNB", file = var.file)
	} else {
		source(var.file)
	}

	return (RNB)
}


RNBp_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sRNBp", calc_temp)

	if (!file.exists(var.file)) {
		bact_avail = bact_avail_calc(source_code)
		bact_req = bact_req_calc(source_code)
		RNBp = bact_avail/bact_req * 100
		dump("RNBp", file = var.file)
	} else {
		source(var.file)
	}

	return (RNBp)
}


BactN_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sBactN", calc_temp)

	if (!file.exists(var.file))  {
		TotalBact = TotalBact_calc(source_code)
		BactN = TotalBact*0.625/6.25 
		dump("BactN", file = var.file)
	} else {
		source(var.file)
	}

	return (BactN)
}


MPreq_get = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPreq", calc_temp)

	if (!file.exists(var.file)) {
		source(production_prediction_module)
		MPreq = MPreq_calc_for_others(source_code)
	} else {
		source(var.file)
	}

	return (MPreq)
}


MPbact_get = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPbact", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		MPbact = MPbact_calc (source_code)
	} else {
		source(var.file)
	}
	
	return (MPbact)
}


MPfeed_get = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPfeed", calc_temp)

	if (!file.exists(var.file)) {
		source(intestinal_model_module)
		MPfeed = MPfeed_calc(source_code)
	} else {
		source(var.file)
	}

	return (MPfeed)
}


MPavail_get = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPavail", calc_temp)

	if (!file.exists(var.file)) {
		MP_feed = MPfeed_get(source_code)
		MPbact = MPbact_get(source_code)
		MPavail = MP_feed + MPbact 
		dump("MPavail", file = var.file)
	} else {
		source(var.file)
	}

	return (MPavail)
}


NIE_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNIE", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUpN = PeptideUpN_calc(source_code)
		NH3_DIET = NH3_DIET_calc(source_code)
		RECYCLEDN = RECYCLEDN_calc(source_code)
		BactN = BactN_calc(source_code)
		MPavail = MPavail_get(source_code)
		MPreq = MPreq_get (source_code)
		NIE = PeptideUpN + NH3_DIET + RECYCLEDN - BactN + (MPavail-MPreq)/6.25
		dump("NIE", file = var.file)
	} else {
		source(var.file)
	}

	return (NIE)
}


MP_from_bact_calc = function(source_code) {

	MPbact = MPbact_get(source_code)
	MP_from_bact = round(MPbact,0)

	return (MP_from_bact)
}


MP_from_RUP_calc = function(source_code) {

	MPfeed = MPfeed_get(source_code)

	MP_from_RUP = round(MPfeed, 0)

	return (MP_from_RUP)
}


RVMPb_calc = function(source_code) {

	MPavail = MPavail_get(source_code)
	MP_from_bact = MP_from_bact_calc(source_code)

	RVMPb = MP_from_bact/MPavail * 100 

	return (RVMPb)
}


RVMPu_calc = function(source_code) {

	MP_from_RUP = MP_from_RUP_calc(source_code)
	MPavail = MPavail_get(source_code) 

	RVMPu = MP_from_RUP / MPavail * 100 

	return (RVMPu) 
}


microbial_ferment_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_microbial_fermentation)) { 

		passage_rate = rumen_passage_rate_calc(source_code)
		rumen_degradation = rumen_degradation_calc(source_code)
		passage_rate_ph = rumen_passage_rate_by_ph_calc(source_code)

		KMsc = KMsc_calc()
		KMnsc = KMnsc_calc()
		YG1mod = YG1mod_calc(source_code)
		YG2mod = YG2mod_calc(source_code)
		Imp = Imp_calc (source_code)

		microbial_ferment = NULL 

		feed_id_list = rownames(passage_rate)

		for (i in (1:length(feed_id_list))) {
			f_id = feed_id_list[i]
			f_name = as.character(passage_rate[f_id,1])

			ca_growth_rate = as.numeric(passage_rate[f_id, 'CHO.A.rates'])
			rdca = as.numeric(rumen_degradation[f_id, 'RDCA'])

			if (ca_growth_rate == 0) {
				Y2j = 0
			} else {
				Y2j = 1/(KMnsc/ca_growth_rate + 1/YG2mod)
			}

			adj_Y2j = Y2j*(1+Imp/100)
			ca_bact_yield = adj_Y2j * rdca 

			cb1_growth_rate = as.numeric(passage_rate[f_id, 'CHO.B1.rates'])
			rdcb1 = as.numeric(rumen_degradation[f_id, 'RDCB1'])

			if(cb1_growth_rate == 0){
				Y3j = 0
			} else {
				Y3j = 1/(KMnsc/cb1_growth_rate+1/YG2mod)
			}

			adj_Y3j = Y3j * (1+ Imp/100)
			cb1_bact_yield = rdcb1 * adj_Y3j

			nsc_bact_yield = ca_bact_yield + cb1_bact_yield

			cb2_growth_rate = as.numeric(passage_rate_ph[f_id, 'Final_B2_kd'])
			rdcb2 = as.numeric(rumen_degradation[f_id, 'RDCB2'])

			if (cb2_growth_rate == 0) {
				Y1j = 0
			} else {
				Y1j = 1/(KMsc/cb2_growth_rate + 1/YG1mod)
			}

			cb2_bact_yield = Y1j * rdcb2 

			row_data = c(f_name, ca_growth_rate, Y2j, adj_Y2j, ca_bact_yield, cb1_growth_rate, Y3j, adj_Y3j, cb1_bact_yield, nsc_bact_yield, cb2_growth_rate, Y1j, cb2_bact_yield)
			microbial_ferment  = rbind(microbial_ferment, row_data)
		}

		colnames(microbial_ferment) = c('Feed_name', 'CA.growth_rate', 'CA.Y2j', 'CA.Adj_Y2j', 'CA.Bact_Yield.g.d.', 
										'CB1.growth_rate', 'CB1.Y3j', 'CB1.Adj_Y3j', 'CB1.Bact_Yield.g.d.', 'NSC_Bact_Yield.g.d.', 
									'CB2.growth_rate', 'CB2.Y1j', 'CB2.Bact_Yield.g.d.')
		rownames(microbial_ferment)  = feed_id_list

		write.csv(microbial_ferment, file = tmp_microbial_fermentation, quote=F, row.names=T)
	} else {
		microbial_ferment = read.csv(tmp_microbial_fermentation, header=T, row.names=1)
	}

	return (microbial_ferment)
}


ca_bact_yield_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sca_bact_yield", calc_temp)

	if (!file.exists(var.file)) {
		microbial_ferment = microbial_ferment_calc(source_code)
		ca_bact_yield = sum(as.numeric(microbial_ferment[,'CA.Bact_Yield.g.d.']))
		dump("ca_bact_yield", file = var.file)
	} else {
		source(var.file)
	}

	return (ca_bact_yield)	
}


cb1_bact_yield_calc = function(source_code){

	source(source_code)

	var.file = sprintf("%scb1_bact_yield", calc_temp)

	if (!file.exists(var.file)) {
		microbial_ferment = microbial_ferment_calc(source_code)
		cb1_bact_yield = sum(as.numeric(microbial_ferment[,'CB1.Bact_Yield.g.d.']))
		dump("cb1_bact_yield", file = var.file)
	} else {
		source(var.file)
	}

	return (cb1_bact_yield)
}


nsc_bact_yield_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%snsc_bact_yield", calc_temp)

	if (!file.exists(var.file)) {
		microbial_ferment = microbial_ferment_calc(source_code)
		nsc_bact_yield = sum(as.numeric(microbial_ferment[,'NSC_Bact_Yield.g.d.']))
		dump("nsc_bact_yield", file = var.file)
	} else {
		source(var.file)
	}

	return (nsc_bact_yield)
}


FCbact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFCbact", calc_temp)

	if (!file.exists(var.file)) {
		microbial_ferment = microbial_ferment_calc(source_code)
		FCbact = sum(as.numeric(microbial_ferment[,'CB2.Bact_Yield.g.d.']))
		dump("FCbact", file = var.file)
	} else {
		source(var.file)
	}
 
	return (FCbact)
}


TotalBact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTotalBact", calc_temp)

	if (!file.exists(var.file)) {
		ca_bact_yield = ca_bact_yield_calc(source_code)
		cb1_bact_yield = cb1_bact_yield_calc(source_code)
		FCbact = FCbact_calc(source_code)		
		TotalBact = ca_bact_yield + cb1_bact_yield + FCbact 
		dump("TotalBact", file = var.file)
	} else {
		source(var.file)
	}

	return (TotalBact)
}


TotalRDP_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTotalRDP", calc_temp)

	if (!file.exists(var.file)) {

		rumen_degradable_feed = rumen_degradable_feed_calc(source_code)
		TotalRDP = sum(as.numeric(rumen_degradable_feed[, 'RDPA'])) + sum(as.numeric(rumen_degradable_feed[,'RDPB1'])) + 
					sum(as.numeric(rumen_degradable_feed[, 'RDPB2'])) + sum(as.numeric(rumen_degradable_feed[, 'RDPB3'])) 
		dump("TotalRDP", file = var.file)
	} else {
		source(var.file)
	}

	return (TotalRDP)
}


TotalRUP_calc = function(source_code) {
	
	source(source_code)

	var.file = sprintf("%sTotalRUP", calc_temp)

	if (!file.exists(var.file)) {
		ruminal_feed_escaping = ruminal_feed_escaping_calc(source_code)
		repa_total = sum(as.numeric(ruminal_feed_escaping[,'REPA']))
		adj_repb1_total = sum(as.numeric(ruminal_feed_escaping[,'adjREPB1']))
		adj_repb2_total = sum(as.numeric(ruminal_feed_escaping[,'adjREPB2']))
		adj_repb3_total = sum(as.numeric(ruminal_feed_escaping[,'adjREPB3']))
		repc_total = sum(as.numeric(ruminal_feed_escaping[,'REPC']))
		TotalRUP = repa_total + adj_repb1_total + adj_repb2_total + adj_repb3_total + repc_total
		dump("TotalRUP", file = var.file)
	} else {
		source(var.file)
	}

	
	return (TotalRUP)
}


microbial_composition_database = function(source_code) {

	CHO.A.cons = 0.8 
	CHO.B.cons = 0.2
	Protein.A.cons = 0.15 
	Protein.B1.cons = 0.625
	Protein.C.cons = 0.25

	CHO.A = 0.211 * CHO.A.cons 
	CHO.B1 = 0.211 * CHO.B.cons 
	CHO.B2 = 0 
	CHO.C = 0 

	Protein.A = 0.625 * Protein.A.cons 
	Protein.B1 = 0.625 * Protein.B1.cons 
	Protein.B2 = 0
	Protein.C = 0.625 * Protein.C.cons 

	EE = 0.12 
	Ash = 0.044 

	microbial_composition = c(CHO.A, CHO.B1, CHO.B2, CHO.C, Protein.A, Protein.B1, Protein.B2, Protein.C, EE, Ash) 	
	
	return (microbial_composition)
}


NAllowableBact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNAllowableBact", calc_temp)

	if (!file.exists(var.file)) {
		PeptideUpN = PeptideUpN_calc(source_code)
		NH3_DIET = NH3_DIET_calc(source_code)
		RECYCLEDN = RECYCLEDN_calc(source_code) 
		NAllowableBact = (PeptideUpN + NH3_DIET + RECYCLEDN)/(0.625/6.25)
		dump("NAllowableBact", file = var.file)
	} else {
		source(var.file)
	}

	return (NAllowableBact)	
}


Ruminal_nitrogen_deficiency_adjustment_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_ruminal_nitrogen)) {

		microbial_ferment = microbial_ferment_calc(source_code)
		rumen_degradation = rumen_degradation_calc(source_code)
		carbprot_dm = intake_carbprot_p_DM(source_code) 

		total_bact = TotalBact_calc(source_code)
		NAllowableBact = NAllowableBact_calc(source_code)
		BACTNBALANCE = BACTNBALANCE_calc(source_code)

		ruminal_nitrogen = NULL 

		feed_id_list = rownames(microbial_ferment)

		for (i in (1:length(feed_id_list))) {

			f_id =  feed_id_list[i]
			f_name = as.character(microbial_ferment[f_id,'Feed_name'])

			EFCBact = as.numeric(microbial_ferment[f_id, 'CB2.Bact_Yield.g.d.'])
			ENFCBact = as.numeric(microbial_ferment[f_id, 'NSC_Bact_Yield.g.d.'])

			ETotalBact = EFCBact + ENFCBact
			EBactRatio = ETotalBact/total_bact 
			ENAllowableBact = NAllowableBact * EBactRatio

			if (BACTNBALANCE > 0) {
				BactRed = 0 
			} else if ((ETotalBact-ENAllowableBact) < 0) {
				BactRed = 0
			} else {
				BactRed = ETotalBact - ENAllowableBact
			}

			if (BACTNBALANCE > 0) {
				EFCBactRatio = 0 
			} else if (EFCBact > 0) {
				EFCBactRatio = EFCBact/ETotalBact
			} else {
				EFCBactRatio = 0 
			}

			if (BACTNBALANCE > 0) {
				FCBactRed = 0
				NFCBact = 0 
			} else {
				FCBactRed = BactRed * EFCBactRatio
				NFCBact = ENFCBact - BactRed * (1-EFCBactRatio)
			}

			if (BACTNBALANCE > 0) {
				FCRed = 0 
			} else if (FCBactRed == 0) {
				FCRed = 0 
			} else {
				FCRed = FCBactRed / as.numeric(microbial_ferment[i,'CB2.Y1j'])
			}

			if (BACTNBALANCE > 0) {
				rdcb2 = 0 
			} else {
				rdcb2 = as.numeric(rumen_degradation[f_id,'RDCB2']) - FCRed
			}

			if (BACTNBALANCE > 0) {
				recb2 = 0 
			} else {
				recb2 = as.numeric(rumen_degradation[f_id, 'RECB2']) + FCRed
			}

			if (BACTNBALANCE > 0) {
				ProtB3Red = 0
			} else {
				ProtB3Red = FCRed * as.numeric(carbprot_dm[f_id,'Protein.pools.B3']) / 100 
			}

			if (BACTNBALANCE > 0) {
				rdpb3 = 0
			} else {
				rdpb3 = max(0, as.numeric(rumen_degradation[f_id, 'RDPB3']))
			}

			row_data = c(f_name, EFCBact, ENFCBact, ETotalBact, EBactRatio, ENAllowableBact, BactRed, EFCBactRatio, FCBactRed, NFCBact, FCRed, rdcb2, recb2, ProtB3Red, rdpb3)
			ruminal_nitrogen = rbind(ruminal_nitrogen, row_data)
 		}

 		colnames(ruminal_nitrogen) = c('Feed_name', 'EFCBact', 'ENFCBact', 'ETotalBact', 'EBactRatio', 'NAllowableBact', 'BactRed', 
 			'EFCBactRatio', 'FCBactRed', 'NFCBact', 'FCRed', 'RDCB2', 'RECB2', 'ProtB3Red', 'RDPB3')
 		rownames(ruminal_nitrogen) = feed_id_list
 		write.csv(ruminal_nitrogen, file=tmp_ruminal_nitrogen, quote=F, row.names=T)

 	} else { 
 		ruminal_nitrogen = read.csv(file=tmp_ruminal_nitrogen, header=T, row.names=1 )
 	}
 	return (ruminal_nitrogen)
}


EAllowableBact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sEAllowableBact", calc_temp)

	if (!file.exists(var.file)) { 
		ruminal_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code)
		EFCBact_total = sum(as.numeric(ruminal_nitrogen[,'EFCBact']))
		ENFCBact_total = sum(as.numeric(ruminal_nitrogen[,'ENFCBact']))
		EAllowableBact = EFCBact_total + ENFCBact_total
		dump("EAllowableBact", file = var.file)
	} else {
		source(var.file)
	}

	return (EAllowableBact)
}


FCRedRatio_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sFCRedRatio", calc_temp)

	if (!file.exists(var.file)) {

		BACTNBALANCE = BACTNBALANCE_calc(source_code) 

		ruminal_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code) 

		FCRed_total = sum(as.numeric(ruminal_nitrogen[,'FCRed']))
		RDCB2_total = sum(as.numeric(ruminal_nitrogen[,'RDCB2']))

		if (BACTNBALANCE > 0) {
			FCRedRatio = 0 
		} else {
			FCRedRatio = 100 * FCRed_total / RDCB2_total
		}
		dump("FCRedRatio", file = var.file)
	} else {
		source(var.file)
	}

	return (FCRedRatio)
}


adj_ruminal_feed_degradation_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_adj_ruminal_feed_degradation)) { 
		rumen_degradation = rumen_degradation_calc(source_code)
		peptidepass = PeptidePass_calc(source_code)
		RDPEP = RDPEP_calc(source_code)

		adj_ruminal_feed_degradation = NULL 

		feed_id_list= rownames(rumen_degradation)

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(rumen_degradation[f_id, 'Feed_name'])
			RDPB1 = as.numeric(rumen_degradation[f_id,'RDPB1'])
			RDPB2 = as.numeric(rumen_degradation[f_id,'RDPB2'])
			RDPB3 = as.numeric(rumen_degradation[f_id, 'RDPB3'])
		
			adj_rdpb1 = max(0, (RDPB1-peptidepass*RDPB1/RDPEP))
			adj_rdpb2 = max(0, (RDPB2-peptidepass*RDPB2/RDPEP))
			adj_rdpb3 = max(0, (RDPB3-peptidepass*RDPB3/RDPEP))

			row_data = c(f_name, adj_rdpb1, adj_rdpb2, adj_rdpb3)

			adj_ruminal_feed_degradation = rbind(adj_ruminal_feed_degradation, row_data)
		}

		colnames(adj_ruminal_feed_degradation) = c('Feed_name', 'AdjRDPB1', 'RDPB2', 'RDPB3')
		rownames(adj_ruminal_feed_degradation) = feed_id_list 

		write.csv(adj_ruminal_feed_degradation, file=tmp_adj_ruminal_feed_degradation, quote=F, row.names=T)
	} else {
		adj_ruminal_feed_degradation = read.csv(tmp_adj_ruminal_feed_degradation, row.names=1, header = T)
	}

	return (adj_ruminal_feed_degradation)
}



ruminal_feed_escaping_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_ruminal_feed_escaping)) {

		rumen_degradation = rumen_degradation_calc(source_code)
		rumen_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code)
		intake_carb_prot = intake_carbprot_p_day(source_code)
		rumen_passage_rate = rumen_passage_rate_calc(source_code)
		peptidepass = PeptidePass_calc(source_code)
		RDPEP = RDPEP_calc (source_code)

		dm_perc = dm_perc_get(source_code)
		
		feed_id_list = rownames(dm_perc) 

		ruminal_feed_escaping = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(rumen_degradation[f_id,1])

			FCRed = as.numeric(rumen_nitrogen[f_id, 'FCRed'])
			dm = as.numeric(dm_perc[f_id, 2])
			ProtB3Red = as.numeric(rumen_nitrogen[f_id, 'ProtB3Red'])

			kp = as.numeric(rumen_passage_rate[f_id, 'kp'])
			prot.a = as.numeric(intake_carb_prot[f_id, 'Protein.pools.A'])
			prot.a.rate = as.numeric(rumen_passage_rate[f_id, 'Protein.A.rates'])

			reca = as.numeric(rumen_degradation[i, 'RECA'])		
			recb1 = as.numeric(rumen_degradation[i, 'RECB1'])
			adj_recb2 = as.numeric(rumen_degradation[i,'RECB2']) + FCRed
			recc = as.numeric(rumen_degradation[i, 'RECC'])

			if (dm == 0) {
				repa = 0
			} else {
				repa = prot.a / (kp +prot.a.rate)
			}

			adj_repb1 = as.numeric(rumen_degradation[i, 'REPB1'])  + peptidepass * as.numeric(rumen_degradation[i, 'RDPB1']) / RDPEP 
			adj_repb2 = as.numeric(rumen_degradation[i, 'REPB2'])  + peptidepass * as.numeric(rumen_degradation[i, 'RDPB2']) / RDPEP 
			adj_repb3 = as.numeric(rumen_degradation[i, 'REPB3'])  + peptidepass * as.numeric(rumen_degradation[i, 'RDPB3']) / RDPEP + ProtB3Red

			repc = as.numeric(rumen_degradation[i, 'REPC'])

			row_data = c(f_name, reca, recb1, adj_recb2, recc, repa, adj_repb1, adj_repb2, adj_repb3, repc) 
			ruminal_feed_escaping = rbind(ruminal_feed_escaping, row_data)
		}

		colnames(ruminal_feed_escaping) = c( 'Feed_name', 'RECA', 'RECB1', 'adjRECB2', 'RECC', 'REPA', 'adjREPB1', 'adjREPB2', 'adjREPB3', 'REPC')
		rownames(ruminal_feed_escaping) = feed_id_list
		write.csv(ruminal_feed_escaping, file=tmp_ruminal_feed_escaping, quote=F, row.names=T)
	} else {
		ruminal_feed_escaping = read.csv(file=tmp_ruminal_feed_escaping, row.names=1, header=T)
	}
	return (ruminal_feed_escaping)
}


microbial_composition_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_microbial_composition)) { 
		ruminal_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code)

		microbial_compos = NULL 

		feed_id_list= rownames(ruminal_nitrogen)

		for (i in (1:length(feed_id_list))) {
			f_id = feed_id_list[i]
			f_name = as.character(ruminal_nitrogen[i,1])

			NAllowableBact = as.numeric(ruminal_nitrogen[f_id, 'NAllowableBact'])
			EFCBact = as.numeric(ruminal_nitrogen[f_id, 'EFCBact'])
			ENFCBact = as.numeric(ruminal_nitrogen[f_id, 'ENFCBact'])

			REBTP = 0.625*0.6*min(NAllowableBact, EFCBact+ENFCBact)
			REBCW = 0.625*0.25*min(NAllowableBact, EFCBact+ENFCBact)
			REBNA = 0.625*0.15*min(NAllowableBact, EFCBact+ENFCBact)
			REBCA = 0.211*0.8*min(NAllowableBact, EFCBact+ENFCBact)
			REBCB1 = 0.211*0.2*min(NAllowableBact, EFCBact+ENFCBact)

			REBCHO = REBCA + REBCB1
			REBFAT = 0.12 * min(NAllowableBact, EFCBact+ENFCBact)
			REBASH = 0.044 * min(NAllowableBact, EFCBact+ENFCBact)

			row_data = c(f_name, REBTP, REBCW, REBNA, REBCA, REBCB1, REBCHO, REBFAT, REBASH)
			microbial_compos = rbind(microbial_compos, row_data)
		}

		colnames(microbial_compos) = c('Feed_name', 'REBTP', 'REBCW', 'REBNA', 'REBCA', 'REBCB1', 'REBCHO', 'REBFAT', 'REBASH')
		rownames(microbial_compos)  = feed_id_list 
		write.csv(microbial_compos, file=tmp_microbial_composition, quote=F, row.names=T)
	} else {
		microbial_compos = read.csv(file=tmp_microbial_composition, header=T, row.names=1)
	}

	return (microbial_compos)
}


REBTP_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBTP_total = sum(as.numeric(ruminal_compos[,'REBTP']))

	return (REBTP_total)
}


REBCW_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBCW_total = sum(as.numeric(ruminal_compos[,'REBCW']))

	return (REBCW_total)	
}


REBNA_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBNA_total = sum(as.numeric(ruminal_compos[,'REBNA']))

	return (REBNA_total)	
}


REBCA_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBCA_total = sum(as.numeric(ruminal_compos[,'REBCA']))

	return (REBCA_total)	
}


REBCB1_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBCB1_total = sum(as.numeric(ruminal_compos[,'REBCB1']))

	return (REBCB1_total)	
}


REBCHO_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBCHO_total = sum(as.numeric(ruminal_compos[,'REBCHO']))

	return (REBCHO_total)	
}


REBFAT_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBFAT_total = sum(as.numeric(ruminal_compos[,'REBFAT']))

	return (REBFAT_total)	
}


REBASH_total_calc = function(source_code) {

	ruminal_compos = microbial_composition_calc(source_code)
	REBASH_total = sum(as.numeric(ruminal_compos[,'REBASH']))

	return (REBASH_total)	
}


microbial_compos_total_calc = function(source_code) {

	microbial_compos_total = REBTP_total_calc(source_code) + REBCW_total_calc(source_code) + REBNA_total_calc(source_code) + 
						 REBCA_total_calc(source_code) + REBCB1_total_calc(source_code) + REBFAT_total_calc(source_code) + REBASH_total_calc(source_code)

	return (microbial_compos_total)
}


rumen_degradable_feed_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_rumen_degradable_feed)) {

		rumen_degradation = rumen_degradation_calc(source_code)
		rumen_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code)
		adj_ruminal_feed_degradation = adj_ruminal_feed_degradation_calc(source_code)

		rumen_degradable_feed = NULL 

		feed_id_list = rownames(rumen_degradation)

		for (i in (1:length(feed_id_list))) {
			f_id = feed_id_list[i]
			f_name = as.character(rumen_degradation[f_id,1])
			rdca = as.numeric(rumen_degradation[f_id, 'RDCA'])
			rdcb1 = as.numeric(rumen_degradation[f_id, 'RDCB1'])
			rdcb2 = min(as.numeric(rumen_degradation[f_id, 'RDCB2']), as.numeric(rumen_nitrogen[f_id, 'RDCB2']))

			rdpa = as.numeric(rumen_degradation[f_id, 'RDPA'])
			rdpb1 = as.numeric(rumen_degradation[f_id, 'RDPB1'])
			rdpb2 = as.numeric(adj_ruminal_feed_degradation[f_id, 'RDPB2'])
			rdpb3 = as.numeric(adj_ruminal_feed_degradation[f_id, 'RDPB3'])

			row_data = c(f_name, rdca, rdcb1, rdcb2, rdpa, rdpb1, rdpb2, rdpb3)
		rumen_degradable_feed = rbind(rumen_degradable_feed, row_data)
		}

		colnames(rumen_degradable_feed) = c('Feed_name', 'RDCA', 'RDCB1', 'RDCB2', 'RDPA', 'RDPB1', 'RDPB2', 'RDPB3')
		rownames(rumen_degradable_feed) = feed_id_list 

		write.csv(rumen_degradable_feed, file=tmp_rumen_degradable_feed, quote=F, row.names=T)
	} else {
		rumen_degradable_feed = read.csv(file=tmp_rumen_degradable_feed, row.names=1, header =T)
	}
	return (rumen_degradable_feed)
}


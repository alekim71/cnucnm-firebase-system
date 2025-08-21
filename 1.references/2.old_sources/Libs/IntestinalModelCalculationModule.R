#=====================================#
# Intestinal model calculation module #
# Date : 2014-11-10                   #
# Written by Hyesun Park              #
#=====================================#


feed_database_get = function(source_code) {

	if (!file.exists(tmp_feed_database)) {

		source(source_code)		
	
		feed_db = read.csv(file=feed_library, header=T, row.names=1)
		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)
		feed_id_list = rownames(feed_data)

		subSet = NULL 

		for (i in 1:length(feed_id_list)) {
			feed_info = feed_db[feed_id_list[i],]
			subSet = rbind(subSet, feed_info)
			}

		write.csv(subSet, file=tmp_feed_database, quote=F)
	} else {
		subSet = read.csv(file=tmp_feed_database, header=T, row.names=1)
	}

	return (subSet)  
}


feed_dm_calc = function(source_code) {

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


intestinal_digestibilities_calc = function(source_code) {

	if (!file.exists(tmp_intestinal_digestibilites)) {

		feed_database = feed_database_get(source_code)
		feed_id_list = rownames(feed_database)

		intestinal_digestibilities = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = as.character(feed_id_list[i])
			f_name = as.character(feed_database[f_id, 'Feed_name'])

			cho.a =  feed_database[f_id, 'ID.CHO.A....']
			cho.b1 = feed_database[f_id, 'ID.CHO.B1....']
			cho.b2 = feed_database[f_id, 'ID.CHO.B2....']
			cho.c = feed_database[f_id, 'ID.CHO.C....']

			prot.a = feed_database[f_id, 'ID.Protein.A....']
			prot.b1 = feed_database[f_id, 'ID.Protein.B1....']
			prot.b2 = feed_database[f_id, 'ID.Protein.B2....']
			prot.b3 = feed_database[f_id, 'ID.Protein.B3....']
			prot.c = feed_database[f_id, 'ID.Protein.C....']

			fat = feed_database[f_id, 'ID.Fat....']
			ash = feed_database[f_id, 'ID.Ash....']

			row_data = c(f_name, cho.a, cho.b1, cho.b2, cho.c, prot.a, prot.b1, prot.b2, prot.b3, prot.c, fat, ash) 
			intestinal_digestibilities = rbind (intestinal_digestibilities, row_data)
		}

		colnames(intestinal_digestibilities) = c('Feed_name', 'CHO.pools.A', 'CHO.pools.B1', 'CHO.pools.B2', 'CHO.pools.C', 
									'Protein.pools.A', 'Protein.pools.B1', 'Protein.pools.B2', 'Protein.pools.B3', 'Protein.pools.C', 'Fat', 'Ash')
		rownames(intestinal_digestibilities) = feed_id_list
		write.csv(intestinal_digestibilities, file=tmp_intestinal_digestibilites, quote=F, row.names=T)

	} else {
		intestinal_digestibilities = read.csv(file=tmp_intestinal_digestibilites, header=T, row.names=1)
	}

	return (intestinal_digestibilities)
}


total_intestinal_supply_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_total_intestinal_supply)) {

		source(rumen_model_module)

		ruminal_feed_escaping = ruminal_feed_escaping_calc(source_code)
		microbial_composition = microbial_composition_calc(source_code)
		
		feed_id_list = rownames(ruminal_feed_escaping) 

		total_intestinal_supply = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = ruminal_feed_escaping[f_id, 'Feed_name']

			reca = ruminal_feed_escaping[f_id, 'RECA']
			recb1 = ruminal_feed_escaping[f_id, 'RECB1']
			adj_recb2 = ruminal_feed_escaping[f_id, 'adjRECB2']
			recc = ruminal_feed_escaping[f_id, 'RECC']

			repa = ruminal_feed_escaping[f_id, 'REPA']
			adj_repb1 = ruminal_feed_escaping[f_id, 'adjREPB1']
			adj_repb2 = ruminal_feed_escaping[f_id, 'adjREPB2']
			adj_repb3 = ruminal_feed_escaping[f_id, 'adjREPB3']

			repc = ruminal_feed_escaping[f_id, 'REPC']

			rebtp = microbial_composition[f_id, 'REBTP']	
			rebcw = microbial_composition[f_id, 'REBCW']
			rebna = microbial_composition[f_id, 'REBNA']
			rebca = microbial_composition[f_id, 'REBCA']
			rebcb1 = microbial_composition[f_id, 'REBCB1']
			rebcho = microbial_composition[f_id, 'REBCHO']
			rebfat = microbial_composition[f_id, 'REBFAT']
			rebash = microbial_composition[f_id, 'REBASH']

			row_data = c(f_name, reca, recb1, adj_recb2, recc, repa, adj_repb1, adj_repb2, adj_repb3, repc, rebtp, rebcw, rebna, rebca, rebcb1, rebcho, rebfat, rebash)

			total_intestinal_supply = rbind(total_intestinal_supply, row_data)
		}

		colnames(total_intestinal_supply) = c('Feed_name', 'RECA', 'RECB1', 'adjRECB2', 'RECC', 
											'REPA', 'adjREPB1', 'adjREPB2', 'adjREPB3','REPC',
											'REBTP', 'REBCW', 'REBNA', 'REBCA', 'REBCB1', 'REBCHO', 'REBFAT', 'REBASH')
		rownames(total_intestinal_supply) = feed_id_list
		write.csv(total_intestinal_supply, file=tmp_total_intestinal_supply, quote=F, row.names=T)
	} else {
		total_intestinal_supply = read.csv(file=tmp_total_intestinal_supply, header=T, row.names=1)
	}

	return (total_intestinal_supply)
}
 

MPbact_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPbact", calc_temp)

	if (!file.exists(var.file)) {
		total_intestinal_supply = total_intestinal_supply_calc(source_code)
		MPbact = sum(as.numeric(total_intestinal_supply[,'REBTP']))
		dump("MPbact", file = var.file)
	} else {
		source(var.file)
	}

	return (MPbact)
}


prediction_intestinal_digestion_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_prediction_intestinal_digestion)) {

		intestinal_digestibilities = intestinal_digestibilities_calc(source_code)
		total_intestinal_supply = total_intestinal_supply_calc(source_code)

		feed_database  = feed_database_get(source_code)
		feed_dm_data = feed_dm_calc(source_code)

		feed_id_list = rownames(feed_database)

		prediction_intestinal_digestion = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list [i]

			f_name = as.character(feed_database[f_id, 'Feed_name'])
			feed_fat = as.numeric(feed_database[f_id, 'Crude.fat...DM.'])
			feed_dm = as.numeric(feed_dm_data[f_id, 2])

			protein.b1 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B1'])
			protein.b2 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B2'])
			protein.b3 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B3'])

			adj_repb1 = as.numeric(total_intestinal_supply[f_id, 'adjREPB1'])
			adj_repb2 = as.numeric(total_intestinal_supply[f_id, 'adjREPB2'])
			adj_repb3 = as.numeric(total_intestinal_supply[f_id, 'adjREPB3'])

			digpb1 = protein.b1 * adj_repb1 / 100 
			digpb2 = protein.b2 * adj_repb2 / 100 
			digpb3 = protein.b3 * adj_repb3 / 100 

			digfp = sum(digpb1, digpb2, digpb3)

			digbtp = as.numeric(total_intestinal_supply[f_id, 'REBTP'])
			digbna = as.numeric(total_intestinal_supply[f_id, 'REBNA'])

			digp = sum(digfp, digbtp, digbna)

			cho.pools.a = as.numeric(intestinal_digestibilities[f_id, 'CHO.pools.A'])
			cho.pools.b1 = as.numeric(intestinal_digestibilities[f_id, 'CHO.pools.B1'])
			cho.pools.b2 = as.numeric(intestinal_digestibilities[f_id, 'CHO.pools.B2'])

			reca = as.numeric(total_intestinal_supply[f_id, 'RECA'])
			recb1 = as.numeric(total_intestinal_supply[f_id, 'RECB1'])
			adj_recb2 = as.numeric(total_intestinal_supply[f_id, 'adjRECB2'])

			digfc = cho.pools.a * reca/100 + cho.pools.b1*recb1/100 + cho.pools.b2*adj_recb2/100

			rebcho = as.numeric(total_intestinal_supply[f_id, 'REBCHO'])
			digbc = rebcho * 0.95
			digc = sum(digfc, digbc)

			refat = feed_dm * feed_fat * 10 

			fat = as.numeric(intestinal_digestibilities[f_id, 'Fat'])
			digff = refat * fat / 100 

			rebfat = as.numeric(total_intestinal_supply[f_id, 'REBFAT'])
			digbf = rebfat * 0.95

			digf = sum(digff, digbf)

			row_data = c(f_name, digpb1, digpb2, digpb3, digfp, digbtp, digbna, digp, digfc, digbc, digc, refat, digff, digbf, digf)

			prediction_intestinal_digestion = rbind(prediction_intestinal_digestion, row_data)
		}

		colnames(prediction_intestinal_digestion) = c('Feed_name', 'DIGPB1', 'DIGPB2', 'DIGPB3', 'DIGFP', 'DIGBTP', 'DIGBNA', 'DIGP', 
						'DIGFC', 'DIGBC', 'DIGC', 'REFAT', 'DIGFF', 'DIGBF', 'DIGF')
		rownames(prediction_intestinal_digestion) = feed_id_list
		write.csv(prediction_intestinal_digestion, file=tmp_prediction_intestinal_digestion, quote=F, row.names=T)

	} else {
		prediction_intestinal_digestion = read.csv(file=tmp_prediction_intestinal_digestion, header=T, row.names=1)
	}
	return (prediction_intestinal_digestion)
}


MPfeed_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMPfeed", calc_temp)

	if (!file.exists(var.file)) {
		prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)
		MPfeed = sum(as.numeric(prediction_intestinal_digestion[,'DIGFP']))
		dump("MPfeed", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MPfeed)
}


DIGP_calc = function(source_code) { 

	prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)
	digp = sum(as.numeric(prediction_intestinal_digestion[,'DIGP']))

	return (digp)
}


DIGC_calc = function(source_code) { 

	prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)
	digc = sum(as.numeric(prediction_intestinal_digestion[, 'DIGC']))

	return (digc)
}


DIGF_calc = function(source_code) {

	prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)
	digf = sum(as.numeric(prediction_intestinal_digestion[,'DIGF']))

	return (digf)
}


fecal_output_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_fecal_output)) {
		source(rumen_model_module)

		intestinal_digestibilities = intestinal_digestibilities_calc(source_code)
		total_intestinal_supply = total_intestinal_supply_calc(source_code)
		prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)

		intake_carbprot = intake_carbprot_p_day(source_code) #Ash only 

		feed_dm_data = feed_dm_calc (source_code)
		feed_id_list = rownames(feed_dm_data)

		fecal_output = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(feed_dm_data[f_id, 1])

			f_dm = as.numeric(feed_dm_data[f_id, 2])
			protein.pools.b3 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B3'])
			adj_repb3 = as.numeric(total_intestinal_supply[f_id, 'adjREPB3'])

			fepb3 = (1-protein.pools.b3/100)*adj_repb3
			fepc = as.numeric(total_intestinal_supply[f_id, 'REPC'])
			fefp = sum(fepb3, fepc)

			cho.pools.b1 = as.numeric(intestinal_digestibilities[f_id, 'CHO.pools.B1'])
			cho.pools.b2 = as.numeric(intestinal_digestibilities[f_id, 'CHO.pools.B2'])

			recb1 = as.numeric(total_intestinal_supply[f_id, 'RECB1'])
			recb2 = as.numeric(total_intestinal_supply[f_id, 'adjRECB2'])

			fecb1 = (1-cho.pools.b1/100)*recb1
			fecb2 = (1-cho.pools.b2/100)*recb2

			fecc = as.numeric(total_intestinal_supply[f_id, 'RECC'])
			fefc = sum(fecb1, fecb2, fecc)

			ash.intake = as.numeric(intake_carbprot [f_id, 'Ash'])
			ash.digest = as.numeric(intestinal_digestibilities[f_id, 'Ash'])

			fat.digest = as.numeric(intestinal_digestibilities[f_id, 'Fat'])
			fat.predict_digest = as.numeric(prediction_intestinal_digestion[f_id, 'REFAT'])

			fefa = ash.intake * (1-ash.digest/100)
			feff = fat.predict_digest * (1-fat.digest/100)

			febcw = as.numeric(total_intestinal_supply[f_id, 'REBCW'])
			febcp = febcw 

			rebcho = as.numeric(total_intestinal_supply[f_id, 'REBCHO'])
			rebfat = as.numeric(total_intestinal_supply[f_id, 'REBFAT'])
			rebash = as.numeric(total_intestinal_supply[f_id, 'REBASH'])

			febc = (1-0.95)*rebcho
			febf = (1-0.95)*rebfat 
			febash = (1-0.5)*rebash

			febact = sum(febcp, febc, febf, febash)
			fecho = sum(fefc, febc)

			feengf = 0.0119 * f_dm*1000
			feenga = 0.017 * f_dm*1000

			fefat = sum(feff, febf,feengf)
			feash = sum(fefa, febash, feenga)

			idm = (fefp +febcp + fecho + fefat + feash) / 0.91 

			feengp = idm*0.09 

			fengtotal = sum(feengp, feengf, feenga)

			feprot = fefp + febcp + feengp 

			row_data = c(f_name, fepb3, fepc, fefp, fecb1, fecb2, fecc, fefc, fefa, feff, febcw, febcp, febc, febf, febash, 
				febact, idm, feengp, feengf, feenga, fengtotal, fefat, feash, feprot, fecho)

			fecal_output = rbind(fecal_output, row_data)
		}

		colnames(fecal_output) = c('Feed_name', 'FEPB3', 'FEPC', 'FEFP', 'FECB1', 'FECB2', 'FECC', 'FEFC', 'FEFA', 'FEFF', 
							'FEBCW', 'FEBCP', 'FEBC', 'FEBF', 'FEBASH', 'FEBACT', 'IDM', 'FEENGP', 'FEENGF', 'FEENGA', 'FENGTotal', 
							'FEFAT', 'FEASH', 'FEPROT', 'FECHO')
		rownames(fecal_output) = feed_id_list


		write.csv(fecal_output, file=tmp_fecal_output, quote=F, row.names=T)
	} else {
		fecal_output = read.csv(file=tmp_fecal_output, header=T, row.names=1)
	}
	return (fecal_output)
}


FEFP_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFP = sum(as.numeric(fecal_output[,'FEFP']))

	return (FEFP)
}


FEFC_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFC = sum(as.numeric(fecal_output[,'FEFC']))

	return (FEFC)
}


FEFA_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFA = sum(as.numeric(fecal_output[,'FEFA']))

	return (FEFA)
}


FEFF_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFF = sum(as.numeric(fecal_output[,'FEFF']))

	return (FEFF)
}


FEBCW_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEBCW = sum(as.numeric(fecal_output[,'FEBCW']))

	return (FEBCW)
}


FEBACT_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEBACT = sum(as.numeric(fecal_output[,'FEBACT']))

	return (FEBACT)
}


FEFC_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFC = sum(as.numeric(fecal_output[,'FEFC']))

	return (FEFC)
}


FECHO_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FECHO = sum(as.numeric(fecal_output[,'FECHO']))

	return (FECHO)
}


IDM_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sIDM", calc_temp)

	if (!file.exists(var.file)) {
		fecal_output = fecal_output_calc(source_code)
		IDM = sum(as.numeric(fecal_output[,'IDM']))
		dump("IDM", file = var.file)
	} else {
		source(var.file)
	}

	return (IDM)
}


FENGTotal_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FENGTotal = sum(as.numeric(fecal_output[,'FENGTotal']))

	return (FENGTotal)
}


FEFAT_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEFAT = sum(as.numeric(fecal_output[,'FEFAT']))

	return (FEFAT)
}


FEASH_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEASH = sum(as.numeric(fecal_output[,'FEASH']))

	return (FEASH)
}


FEPROT_calc = function(source_code) {

	fecal_output = fecal_output_calc(source_code)

	FEPROT = sum(as.numeric(fecal_output[,'FEPROT']))

	return (FEPROT)	
}


total_digestible_nutrient_energy_protein_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_total_digest_nutrients)) {
		
		source(rumen_model_module)

		intake_carbprot = intake_carbprot_p_day(source_code)
		prediction_intestinal_digestion = prediction_intestinal_digestion_calc(source_code)
		fecal_output = fecal_output_calc(source_code)
		feed_dm_data = feed_dm_calc(source_code)
		feed_database = feed_database_get(source_code)

		feed_id_list = rownames(feed_dm_data)

		total_digestible_nutrient_energy_protein = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = as.character(feed_id_list[i])
			f_name = as.character(feed_dm_data[f_id,1])
			f_dm = as.numeric(feed_dm_data[f_id,2])

			feed_type = as.character(feed_database[f_id, 'Catergory'])

			diet_prot = as.numeric(intake_carbprot[f_id, 'Total.protein'])
			diet_cho = as.numeric(intake_carbprot[f_id, 'Total.CHO'])
			diet_fat = as.numeric(intake_carbprot[f_id, 'EE'])

			fe_prot = as.numeric(fecal_output[f_id, 'FEPROT'])
			fe_cho = as.numeric(fecal_output[f_id, 'FECHO'])
			fe_fat = as.numeric(fecal_output[f_id, 'FEFAT'])

			dig_prot = diet_prot - fe_prot
			dig_cho = diet_cho - fe_cho
			dig_fat = diet_fat - fe_fat 

			if (f_dm == 0 | feed_type == 'Non calory') {
				tdnapp = 0			
			} else {
				tdnapp = dig_prot + dig_cho + 2.25*dig_fat 
			}

			if (tdnapp == 0) {
				me_p_kg = 0
			} else if (animal_type == 2 | animal_type == 3) {
				me_p_kg = (tdnapp/1000)/f_dm*4.409*1.01-0.45 
			} else {
				me_p_kg = (tdnapp/1000)/f_dm*4.409*0.82
			}

			me_p_day = f_dm * me_p_kg

			if (me_p_kg == 0) {
				nel = 0 			
				nega = 0 
				nema = 0
			} else {
				nel = me_p_kg * 0.644
				nega = 1.42 * me_p_kg - 0.174*me_p_kg^2 + 0.0122*me_p_kg^3 - 1.65 
				nema = 1.37 * me_p_kg - 0.138*me_p_kg^2 + 0.0105*me_p_kg^3 - 1.12 
			}

			bact.digbna = as.numeric(prediction_intestinal_digestion[f_id, 'DIGBNA'])
			bact.digp  = as.numeric(prediction_intestinal_digestion[f_id,'DIGP'] )

			mp_p_day = bact.digp - bact.digbna

			if (f_dm == 0) {
				mp_p_kg = 0 
			} else {
				mp_p_kg = mp_p_day/f_dm
			}

			if (f_dm == 0) {
				tdnapp_perc = 0
			} else {
				tdnapp_perc = tdnapp/(f_dm*1000)
			}
		
			row_data = c(f_name, diet_prot, fe_prot, dig_prot, diet_cho, fe_cho, dig_cho, diet_fat, fe_fat, dig_fat,
						tdnapp, me_p_day, me_p_kg, nel, nega, nema, mp_p_day, mp_p_kg, tdnapp_perc )
			total_digestible_nutrient_energy_protein = rbind(total_digestible_nutrient_energy_protein, row_data)
		}

		colnames(total_digestible_nutrient_energy_protein) = c('Feed_name', 'DIETPROT', 'FEPROT', 'DIGPROT',
						'DIETCHO', 'FECHO', 'DIGCHO', 'DIETFAT', 'FEFAT', 'DIGFAT', 'TDNAPP.g.d.', 'ME.Mcal.d.', 'ME.Mcal.kg.',
						'NEl.Mcal.kg.', 'NEga.Mcal.kg.', 'NEma.Mcal.kg.', 'MP.g.d.', 'MP.g.kg.', 'TDNAPP...')
		rownames(total_digestible_nutrient_energy_protein) = feed_id_list
		write.csv(total_digestible_nutrient_energy_protein, file=tmp_total_digest_nutrients, quote=F, row.names=T)
	} else {
		total_digestible_nutrient_energy_protein = read.csv(file=tmp_total_digest_nutrients, header=T, row.names=1)
	}
	return (total_digestible_nutrient_energy_protein)
}


DMI_get = function(source_code) {

	feed_dm = feed_dm_calc (source_code)
	DMI = sum(as.numeric(feed_dm[,2]))

	return (DMI)
}


TDNAPP_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sTDNAPP", calc_temp)

	if (!file.exists(var.file)) {
		total_digestible_nutrient_energy_protein = total_digestible_nutrient_energy_protein_calc(source_code)
		tdnapp = sum(as.numeric(total_digestible_nutrient_energy_protein[,'TDNAPP.g.d.']))
		dump("Tdnapp", file = var.file)
	} else {
		source(var.file)
	}
	
	return (tdnapp)
}


MEI_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEI", calc_temp)

	if (!file.exists(var.file)) {
		total_digestible_nutrient_energy_protein = total_digestible_nutrient_energy_protein_calc(source_code)
		MEI = sum(as.numeric(total_digestible_nutrient_energy_protein[,'ME.Mcal.d.']))
		dump("MEI", file = var.file)
	} else {
		source(var.file)
	}


	
	return (MEI)
}


MEC_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMEC", calc_temp)

	if (!file.exists(var.file)) {
		MEI = MEI_calc(source_code)
		DMI = DMI_get (source_code)
		MEC = MEI/DMI
		dump("MEC", file = var.file)
	} else {
		source(var.file)
	}

	return (MEC)
}

NEl_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEl_total", calc_temp)

	if (!file.exists(var.file)) {
		MEC = MEC_calc(source_code)
		if (MEC==0) {
			NEl = 0
		} else {
			NEl = MEC * 0.644
		}
		dump("NEl", file = var.file)
	} else {
		source(var.file)
	}

	return (NEl)
}

NEga_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEga", calc_temp)

	if (!file.exists(var.file)) {
		MEC = MEC_calc(source_code) 
		if (MEC == 0 ){
			#NEga_total = 0 
			NEga = 0 
		} else {
			NEga = 1.42 *MEC - 0.174*MEC^2+0.0122*MEC^3-1.65
		}
		dump("NEga", file = var.file)
	} else {
		source(var.file)
	}
	
	return (NEga)
} 



NEma_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sNEma", calc_temp)

	if (!file.exists(var.file)) {
		MEC = MEC_calc (source_code)
		if (MEC ==0 ){
			NEma = 0 
		} else {
			NEma = 1.37*MEC-0.138*MEC^2+0.0105*MEC^3-1.12
		}
		dump("NEma",  file = var.file)
	} else {
		source(var.file)
	}

	return (NEma)
}


MP_d_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMP_d_total", calc_temp)

	if (!file.exists(var.file)) {
		total_digestible_nutrient_energy_protein = total_digestible_nutrient_energy_protein_calc(source_code)
		MP_d_total = sum(as.numeric(total_digestible_nutrient_energy_protein[,'MP.g.d.']))
		dump("MP_d_total", file=var.file)
	} else {
		source(var.file)
	}
	
	return (MP_d_total)
}


MP_kg_total_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMP_kg_total", calc_temp)

	if (!file.exists(var.file)) {
		MP_d_total = MP_d_total_calc(source_code) 
		DMI = DMI_get(source_code)
		MP_kg_total = MP_d_total/DMI
		dump("MP_kg_total", file = var.file)
	} else {
		source(var.file)
	}
	
	return (MP_kg_total)
}


AppTDN_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sAppTDN", calc_temp)

	if (!file.exists(var.file)) {
		total_digestible_nutrient_energy_protein = total_digestible_nutrient_energy_protein_calc(source_code)
		tdnapp = sum(as.numeric(total_digestible_nutrient_energy_protein[,'TDNAPP.g.d.']))
		DMI = DMI_get(source_code)
		if (DMI == 0) {
			AppTDN = 0 
		} else {
			AppTDN = tdnapp/(DMI*1000)
		}
		dump("AppTDN", file = var.file)
	} else {
		source(var.file)
	}

	return (AppTDN)
}


aminoacid_database_get = function() {

	noncell_wall = c(2.68, 8.20, 2.69, 5.16, 1.63, 5.59, 7.51, 5.88, 6.16, 6.96)
	cell_wall =    c(2.40, 5.60, 1.74, 4.20, 1.63, 3.30,5.90, 4.00,  4.70, 3.82)
	aminoacid_database = rbind(noncell_wall, cell_wall)

	colnames(aminoacid_database) = c('Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
	rownames(aminoacid_database) = c('Noncell_wall', 'Cell_wall')

	return (aminoacid_database)
}


aminoacid_composition_calc = function(source_code) {

	source(source_code) 

	if (!file.exists(tmp_aminoacid_composition)) {
		feed_database = feed_database_get(source_code)
		feed_id_list = rownames(feed_database)

		aminoacid_composition = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(feed_database[f_id, 'Feed_name'])

			met = as.numeric(feed_database[f_id, 'Methionine...UIP.'])
			lys = as.numeric(feed_database[f_id, 'Lysine...UIP.'])
			arg = as.numeric(feed_database[f_id, 'Arginine...UIP.'])
			thr = as.numeric(feed_database[f_id, 'Threonine...UIP.'])
			leu = as.numeric(feed_database[f_id, 'Leucine...UIP.'])
			ile = as.numeric(feed_database[f_id, 'Isoleucine...UIP.'])
			val = as.numeric(feed_database[f_id, 'Valine...UIP.'])
			his = as.numeric(feed_database[f_id, 'Histidine...UIP.'])
			phe = as.numeric(feed_database[f_id, 'Phenylalanine...UIP.'])
			trp = as.numeric(feed_database[f_id, 'Tryptophan...UIP.'])

			row_data = c(f_name, met, lys, arg, thr, leu, ile, val, his, phe, trp)

			aminoacid_composition = rbind(aminoacid_composition, row_data)
		}

		colnames (aminoacid_composition) = c('Feed_name', 'Met', 'Lys', 'Arg', 'Thr', 'Leu', 'Ile', 'Val', 'His', 'Phe', 'Trp')
		rownames (aminoacid_composition) = feed_id_list
		write.csv(aminoacid_composition, file=tmp_aminoacid_composition, quote=F, row.names=T)

	} else {
		aminoacid_composition = read.csv(file=tmp_aminoacid_composition, row.names=1, header=T)
	}

	return (aminoacid_composition)
}


bacterial_aminoacid_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_bacterial_amino_acid)) {

		total_intestinal_supply = total_intestinal_supply_calc(source_code)

		feed_id_list= rownames(total_intestinal_supply)
		aa_db = aminoacid_database_get ()

		bacterial_amino_acid = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(total_intestinal_supply[f_id, 'Feed_name'])
			f_rebtp = as.numeric(total_intestinal_supply[f_id, 'REBTP'])
			f_rebcw = as.numeric(total_intestinal_supply[f_id, 'REBCW'])

			bact_aa_met = as.numeric(aa_db['Cell_wall', 'Met']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Met'])/100
			bact_aa_lys = as.numeric(aa_db['Cell_wall', 'Lys']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Lys'])/100
			bact_aa_arg = as.numeric(aa_db['Cell_wall', 'Arg']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Arg'])/100
			bact_aa_thr = as.numeric(aa_db['Cell_wall', 'Thr']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Thr'])/100
			bact_aa_leu = as.numeric(aa_db['Cell_wall', 'Leu']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Leu'])/100
			bact_aa_ile = as.numeric(aa_db['Cell_wall', 'Ile']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Ile'])/100
			bact_aa_val = as.numeric(aa_db['Cell_wall', 'Val']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Val'])/100
			bact_aa_his = as.numeric(aa_db['Cell_wall', 'His']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'His'])/100
			bact_aa_phe = as.numeric(aa_db['Cell_wall', 'Phe']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Phe'])/100
			bact_aa_trp = as.numeric(aa_db['Cell_wall', 'Trp']) * f_rebcw /100 + f_rebtp * as.numeric(aa_db['Noncell_wall', 'Trp'])/100

			row_data = c(f_name, bact_aa_met, bact_aa_lys, bact_aa_his, bact_aa_phe, bact_aa_trp, bact_aa_thr, bact_aa_leu,  bact_aa_ile, bact_aa_val, bact_aa_arg)

			bacterial_amino_acid = rbind(bacterial_amino_acid, row_data)
		}

		colnames(bacterial_amino_acid) = c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(bacterial_amino_acid) = feed_id_list
		write.csv(bacterial_amino_acid, file=tmp_bacterial_amino_acid, quote=F, row.names=T)
	} else {
		bacterial_amino_acid = read.csv(file=tmp_bacterial_amino_acid, header=T, row.names=1)
	}

	return (bacterial_amino_acid)
}


bacterial_amino_acid_digestion_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_bacterial_amino_acid_digestion)) {

		total_intestinal_supply = total_intestinal_supply_calc(source_code)
		aa_db = aminoacid_database_get ()

		feed_id_list= rownames(total_intestinal_supply)

		bacterial_amino_acid_digestion = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(total_intestinal_supply[f_id, 'Feed_name'])
			f_rebtp = as.numeric(total_intestinal_supply[f_id, 'REBTP'])

			bact_aa_dig_met = as.numeric(aa_db['Noncell_wall', 'Met']) * f_rebtp / 100
			bact_aa_dig_lys = as.numeric(aa_db['Noncell_wall', 'Lys']) * f_rebtp / 100
			bact_aa_dig_his = as.numeric(aa_db['Noncell_wall', 'His']) * f_rebtp / 100
			bact_aa_dig_phe = as.numeric(aa_db['Noncell_wall', 'Phe']) * f_rebtp / 100
			bact_aa_dig_trp = as.numeric(aa_db['Noncell_wall', 'Trp']) * f_rebtp / 100
			bact_aa_dig_thr = as.numeric(aa_db['Noncell_wall', 'Thr']) * f_rebtp / 100
			bact_aa_dig_leu = as.numeric(aa_db['Noncell_wall', 'Leu']) * f_rebtp / 100
			bact_aa_dig_ile = as.numeric(aa_db['Noncell_wall', 'Ile']) * f_rebtp / 100
			bact_aa_dig_val = as.numeric(aa_db['Noncell_wall', 'Val']) * f_rebtp / 100
			bact_aa_dig_arg = as.numeric(aa_db['Noncell_wall', 'Arg']) * f_rebtp / 100

			row_data = c(f_name, bact_aa_dig_met, bact_aa_dig_lys, bact_aa_dig_his, bact_aa_dig_phe, bact_aa_dig_trp, 
						bact_aa_dig_thr, bact_aa_dig_leu, bact_aa_dig_ile, bact_aa_dig_val, bact_aa_dig_arg) 

			bacterial_amino_acid_digestion = rbind(bacterial_amino_acid_digestion, row_data)
		} 

		colnames(bacterial_amino_acid_digestion) = c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(bacterial_amino_acid_digestion) = feed_id_list

		write.csv(bacterial_amino_acid_digestion, file=tmp_bacterial_amino_acid_digestion, quote=F, row.names=T)
	} else {

		bacterial_amino_acid_digestion = read.csv(file=tmp_bacterial_amino_acid_digestion, row.names=1, header=T)
	}

	return (bacterial_amino_acid_digestion)
}


feed_amino_acid_supply_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_feed_amino_acid_supply)) {

		amino_acid_composition = aminoacid_composition_calc(source_code)
		total_intestinal_supply = total_intestinal_supply_calc(source_code)

		feed_id_list = rownames(total_intestinal_supply)

		feed_amino_acid_supply = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(total_intestinal_supply[f_id, 'Feed_name'])

			adj_repb1 = as.numeric(total_intestinal_supply[f_id, 'adjREPB1'])
			adj_repb2 = as.numeric(total_intestinal_supply[f_id, 'adjREPB2'])
			adj_repb3 = as.numeric(total_intestinal_supply[f_id, 'adjREPB3'])
			repc  = as.numeric(total_intestinal_supply[f_id, 'REPC'])

			rep_sum = sum(adj_repb1, adj_repb2, adj_repb3, repc)

			feed_supply_met = as.numeric(amino_acid_composition[f_id, 'Met']) * 0.01 * rep_sum 
			feed_supply_lys = as.numeric(amino_acid_composition[f_id, 'Lys']) * 0.01 * rep_sum 
			feed_supply_his = as.numeric(amino_acid_composition[f_id, 'His']) * 0.01 * rep_sum 
			feed_supply_phe = as.numeric(amino_acid_composition[f_id, 'Phe']) * 0.01 * rep_sum 
			feed_supply_trp = as.numeric(amino_acid_composition[f_id, 'Trp']) * 0.01 * rep_sum 
			feed_supply_thr = as.numeric(amino_acid_composition[f_id, 'Thr']) * 0.01 * rep_sum 
			feed_supply_leu = as.numeric(amino_acid_composition[f_id, 'Leu']) * 0.01 * rep_sum 
			feed_supply_ile = as.numeric(amino_acid_composition[f_id, 'Ile']) * 0.01 * rep_sum 
			feed_supply_val = as.numeric(amino_acid_composition[f_id, 'Val']) * 0.01 * rep_sum 
			feed_supply_arg = as.numeric(amino_acid_composition[f_id, 'Arg']) * 0.01 * rep_sum 			

			row_data = c(f_name, feed_supply_met, feed_supply_lys, feed_supply_his, feed_supply_phe, feed_supply_trp, 
					feed_supply_thr, feed_supply_leu, feed_supply_ile, feed_supply_val, feed_supply_arg)

			feed_amino_acid_supply = rbind(feed_amino_acid_supply, row_data)
		} 

		colnames(feed_amino_acid_supply) =  c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(feed_amino_acid_supply) = feed_id_list
		write.csv(feed_amino_acid_supply, file=tmp_feed_amino_acid_supply, quote=F, row.names=T)		
	} else {
		feed_amino_acid_supply = read.csv(file=tmp_feed_amino_acid_supply, row.names=1, header=T)
	}

	return (feed_amino_acid_supply)
}


feed_amino_acid_digestion_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_feed_amino_acid_digestion)) {

		aminoacid_composition = aminoacid_composition_calc(source_code)
		intestinal_digestibilities = intestinal_digestibilities_calc(source_code)
		total_intestinal_supply = total_intestinal_supply_calc(source_code)

		feed_id_list = rownames(aminoacid_composition)

		feed_amino_acid_digestion = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(aminoacid_composition[f_id, 'Feed_name'])

			protein.b1 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B1'])
			protein.b2 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B2'])			
			protein.b3 = as.numeric(intestinal_digestibilities[f_id, 'Protein.pools.B3'])

			adj_repb1 = as.numeric(total_intestinal_supply[f_id, 'adjREPB1'])
			adj_repb2 = as.numeric(total_intestinal_supply[f_id, 'adjREPB2'])
			adj_repb3 = as.numeric(total_intestinal_supply[f_id, 'adjREPB3'])

			feed_dig_met = as.numeric(aminoacid_composition[f_id, 'Met'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_lys = as.numeric(aminoacid_composition[f_id, 'Lys'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_his = as.numeric(aminoacid_composition[f_id, 'His'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_phe = as.numeric(aminoacid_composition[f_id, 'Phe'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_trp = as.numeric(aminoacid_composition[f_id, 'Trp'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_thr = as.numeric(aminoacid_composition[f_id, 'Thr'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_leu = as.numeric(aminoacid_composition[f_id, 'Leu'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_ile = as.numeric(aminoacid_composition[f_id, 'Ile'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_val = as.numeric(aminoacid_composition[f_id, 'Val'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)
			feed_dig_arg = as.numeric(aminoacid_composition[f_id, 'Arg'])/100 * (protein.b1/100*adj_repb1 + protein.b2/100*adj_repb2 + protein.b3/100*adj_repb3)

			row_data = c(f_name, feed_dig_met, feed_dig_lys, feed_dig_his, feed_dig_phe, feed_dig_trp, feed_dig_thr, feed_dig_leu, feed_dig_ile, feed_dig_val, feed_dig_arg)

			feed_amino_acid_digestion = rbind(feed_amino_acid_digestion, row_data)
		}

		colnames(feed_amino_acid_digestion) = c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(feed_amino_acid_digestion) = feed_id_list 

		write.csv(feed_amino_acid_digestion, file=tmp_feed_amino_acid_digestion, quote=F, row.names=T)
	} else {
		feed_amino_acid_digestion = read.csv(tmp_feed_amino_acid_digestion, header=T, row.names=1)
	}

	return (feed_amino_acid_digestion)
}


total_duodenal_amino_acid_supply_calc = function(source_code) {


	source(source_code)

	if (!file.exists(tmp_duodenal_supply)) {
	
		bacterial_amino_acid = bacterial_aminoacid_calc(source_code)		
		feed_amino_acid_supply = feed_amino_acid_supply_calc(source_code)

		feed_id_list= rownames(bacterial_amino_acid)

		total_duodenal_supply = NULL 

		for (i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(bacterial_amino_acid[f_id, 'Feed_name'])

			total_duodenal_met = as.numeric(bacterial_amino_acid[f_id, 'Met']) + as.numeric(feed_amino_acid_supply[f_id, 'Met'])
			total_duodenal_lys = as.numeric(bacterial_amino_acid[f_id, 'Lys']) + as.numeric(feed_amino_acid_supply[f_id, 'Lys'])
			total_duodenal_his = as.numeric(bacterial_amino_acid[f_id, 'His']) + as.numeric(feed_amino_acid_supply[f_id, 'His'])
			total_duodenal_phe = as.numeric(bacterial_amino_acid[f_id, 'Phe']) + as.numeric(feed_amino_acid_supply[f_id, 'Phe'])
			total_duodenal_trp = as.numeric(bacterial_amino_acid[f_id, 'Trp']) + as.numeric(feed_amino_acid_supply[f_id, 'Trp'])
			total_duodenal_thr = as.numeric(bacterial_amino_acid[f_id, 'Thr']) + as.numeric(feed_amino_acid_supply[f_id, 'Thr'])
			total_duodenal_leu = as.numeric(bacterial_amino_acid[f_id, 'Leu']) + as.numeric(feed_amino_acid_supply[f_id, 'Leu'])
			total_duodenal_ile = as.numeric(bacterial_amino_acid[f_id, 'Ile']) + as.numeric(feed_amino_acid_supply[f_id, 'Ile'])
			total_duodenal_val = as.numeric(bacterial_amino_acid[f_id, 'Val']) + as.numeric(feed_amino_acid_supply[f_id, 'Val'])
			total_duodenal_arg = as.numeric(bacterial_amino_acid[f_id, 'Arg']) + as.numeric(feed_amino_acid_supply[f_id, 'Arg'])

			row_data = c(f_name, total_duodenal_met, total_duodenal_lys, total_duodenal_his, total_duodenal_phe, total_duodenal_trp, 
				total_duodenal_thr,	total_duodenal_leu, total_duodenal_ile, total_duodenal_val, total_duodenal_arg)

			total_duodenal_supply = rbind(total_duodenal_supply, row_data)
		}

		colnames(total_duodenal_supply) =  c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(total_duodenal_supply) = feed_id_list

		write.csv(total_duodenal_supply, file=tmp_duodenal_supply, quote=F, row.names=T)
	} else {
		total_duodenal_supply = read.csv(file=tmp_duodenal_supply, row.names=1, header=T)
	}

	return(total_duodenal_supply)
}


total_metabolizable_supply_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_total_metabolizable_supply)) {

		feed_amino_acid_digestion = feed_amino_acid_digestion_calc(source_code)
		bact_amino_acid_digestion = bacterial_amino_acid_digestion_calc(source_code)	

		feed_id_list = rownames(feed_amino_acid_digestion) 

		total_metab_supply = NULL 

		for ( i in (1:length(feed_id_list))) {

			f_id = feed_id_list[i]
			f_name = as.character(feed_amino_acid_digestion[f_id, 'Feed_name'])

			total_metab_met = as.numeric(feed_amino_acid_digestion[f_id, 'Met']) + as.numeric(bact_amino_acid_digestion[f_id, 'Met'])
			total_metab_lys = as.numeric(feed_amino_acid_digestion[f_id, 'Lys']) + as.numeric(bact_amino_acid_digestion[f_id, 'Lys'])
			total_metab_his = as.numeric(feed_amino_acid_digestion[f_id, 'His']) + as.numeric(bact_amino_acid_digestion[f_id, 'His'])
			total_metab_phe = as.numeric(feed_amino_acid_digestion[f_id, 'Phe']) + as.numeric(bact_amino_acid_digestion[f_id, 'Phe'])
			total_metab_trp = as.numeric(feed_amino_acid_digestion[f_id, 'Trp']) + as.numeric(bact_amino_acid_digestion[f_id, 'Trp'])
			total_metab_thr = as.numeric(feed_amino_acid_digestion[f_id, 'Thr']) + as.numeric(bact_amino_acid_digestion[f_id, 'Thr'])
			total_metab_leu = as.numeric(feed_amino_acid_digestion[f_id, 'Leu']) + as.numeric(bact_amino_acid_digestion[f_id, 'Leu'])
			total_metab_ile = as.numeric(feed_amino_acid_digestion[f_id, 'Ile']) + as.numeric(bact_amino_acid_digestion[f_id, 'Ile'])
			total_metab_val = as.numeric(feed_amino_acid_digestion[f_id, 'Val']) + as.numeric(bact_amino_acid_digestion[f_id, 'Val'])
			total_metab_arg = as.numeric(feed_amino_acid_digestion[f_id, 'Arg']) + as.numeric(bact_amino_acid_digestion[f_id, 'Arg'])

			row_data = c(f_name, total_metab_met, total_metab_lys, total_metab_his, total_metab_phe, total_metab_trp, total_metab_thr,
						total_metab_leu, total_metab_ile, total_metab_val, total_metab_arg)

			total_metab_supply = rbind(total_metab_supply, row_data)
		}

		colnames(total_metab_supply) = c('Feed_name', 'Met', 'Lys', 'His', 'Phe', 'Trp', 'Thr', 'Leu', 'Ile', 'Val', 'Arg')
		rownames(total_metab_supply) = feed_id_list

		write.csv(total_metab_supply, file=tmp_total_metabolizable_supply, row.names=T, quote=F)
	} else {
		total_metab_supply = read.csv(file=tmp_total_metabolizable_supply, header=T, row.names=1)
	}

	return (total_metab_supply)
}


METsup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sMETsup", calc_temp)

	if (!file.exists(var.file)) {
		total_metab_supply = total_metabolizable_supply_calc(source_code)
		METsup = sum(as.numeric(total_metab_supply[,'Met']))
		dump("METsup", file = var.file)
	} else {
		source(var.file)
	}
	
	return (METsup)
}


LYSsup_calc = function(source_code) {

	source(source_code)

	var.file = sprintf("%sLYSsup", calc_temp)

	if (!file.exists(var.file)) {
		total_metab_supply = total_metabolizable_supply_calc(source_code)
		LYSsup = sum(as.numeric(total_metab_supply[,'Lys']))
		dump("LYSsup", file = var.file)
	} else {
		source(var.file)
	}

	return (LYSsup)
}
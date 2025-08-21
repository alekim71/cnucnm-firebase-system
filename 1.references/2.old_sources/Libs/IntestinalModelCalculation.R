#======================================#
# Intestinal model calculation execute #
# Date : 2014-11-10                    #
# Written by Hyesun Park               #
#======================================#



intestinal_model = function(source_code, intestinal_model_module, today) {

	source(source_code)
	source(intestinal_model_module)

	table_count = 0 

	out_dir = sprintf('%s\\intestinal_model', today)
	shell(sprintf('mkdir %s', out_dir)) 

	table_count = table_count + 1 
	intestinal_digestibility = intestinal_digestibilities_calc(source_code)
	write.csv(intestinal_digestibility, file=sprintf('%s/Table%d_Intestinal_digestibilities.csv', out_dir, table_count), row.names=T, quote=F) 

	table_count = table_count + 1 

	total_intestinal_supply = total_intestinal_supply_calc(source_code)

	MPbact = MPbact_calc(source_code)
	write.csv(total_intestinal_supply, file=sprintf('%s/Table%d_Total_intestinal_supply.csv', out_dir, table_count), row.names=T, quote=F) 
	write(sprintf('MP from bact,%.0f', MPbact), file =sprintf('%s/Table%d_Total_intestinal_supply.csv', out_dir, table_count), append = T)

	table_count = table_count + 1 
	prediction_intestinal_digestion = prediction_intestinal_digestion_calc (source_code)
	
	mpfeed = sum(as.numeric(prediction_intestinal_digestion[,'DIGFP']))
	digp = sum(as.numeric(prediction_intestinal_digestion[,'DIGP']))
	digc = sum(as.numeric(prediction_intestinal_digestion[, 'DIGC']))
	digf = sum(as.numeric(prediction_intestinal_digestion[,'DIGF']))

	write.csv(prediction_intestinal_digestion, file=sprintf('%s/Table%d_Prediction_intestinal_digestion.csv', out_dir, table_count), quote=F, row.names=T)
	write(sprintf(',,,,MP from feed,%.0f,g/d,,%.0f,,,%.0f,,,,%.0f', mpfeed, digp, digc, digf), file =sprintf('%s/Table%d_Prediction_intestinal_digestion.csv', out_dir, table_count), append=T)

	table_count = table_count + 1 

	fecal_output = fecal_output_calc(source_code)

	FEFP_total = sum(as.numeric(fecal_output[,'FEFP']))
	FEFC_total = sum(as.numeric(fecal_output[,'FEFC']))
	FEFA_total = sum(as.numeric(fecal_output[,'FEFA']))
	FEFF_total = sum(as.numeric(fecal_output[,'FEFF']))
	FEBCW_total = sum(as.numeric(fecal_output[,'FEBCW']))
	FEBACT_total = sum(as.numeric(fecal_output[,'FEBACT']))
	FECHO_total = sum(as.numeric(fecal_output[, 'FECHO']))
	IDM_total = sum(as.numeric(fecal_output[,'IDM']))
	FENGTotal = sum(as.numeric(fecal_output[,'FENGTotal']))
	FEFAT_total = sum(as.numeric(fecal_output[,'FEFAT']))
	FEASH_total = sum(as.numeric(fecal_output[,'FEASH'])) 	
	FEPROT_total = sum(as.numeric(fecal_output[,'FEPROT']))

	fecal_output_total_set = sprintf(',,,,%.0f,,,,%.0f,%.0f,%.0f,%.0f,,,,,%.0f,%.0f,,,,%.0f,%.0f,%.0f,%.0f,%.0f', 
		FEFP_total, FEFC_total, FEFA_total, FEFF_total, FEBCW_total, FEBACT_total, IDM_total, FENGTotal, FEFAT_total, FEASH_total, FEPROT_total, FECHO_total)

	write.csv(fecal_output, file=sprintf('%s/Table%d_Fecal_output.csv', out_dir, table_count), quote=F, row.names=T)
	write(fecal_output_total_set, file =sprintf('%s/Table%d_Fecal_output.csv', out_dir, table_count), append=T, sep=',')


	table_count = table_count + 1 

	total_digestible_nutrient = total_digestible_nutrient_energy_protein_calc(source_code)

	tdnapp_total = TDNAPP_total_calc(source_code)
	me_d_total = MEI_calc(source_code)
	me_kg_total = MEC_calc(source_code)
	nel_total = NEl_total_calc(source_code) 
	nega_total = NEga_total_calc(source_code)
	nema_total = NEma_total_calc(source_code)
	mp_d_total = MP_d_total_calc(source_code)
	mp_kg_total = MP_kg_total_calc(source_code)
	tdnapp_perc_total = AppTDN_calc(source_code) * 100

	total_digestible_nutrient_summary = sprintf(",,,,,,,,,,LEVEL 2 Diet Energy Values,%.0f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,%.0f,%.2f%%", 
			tdnapp_total, me_d_total, me_kg_total, nel_total,nega_total, nema_total, mp_d_total, mp_kg_total, tdnapp_perc_total)

	write.csv(total_digestible_nutrient, file=sprintf('%s/Table%d_Total_digestible_nutrients_and_energy_values_of_feedstuffs_and_metabolizable_protein.csv', out_dir, table_count), quote=F, row.names=T)
	write(total_digestible_nutrient_summary, file=sprintf('%s/Table%d_Total_digestible_nutrients_and_energy_values_of_feedstuffs_and_metabolizable_protein.csv', out_dir, table_count), append=T)

	table_count = table_count + 1 
	amino_acid_composition_rumen_micobial_cell = aminoacid_database_get()	
	write.csv(amino_acid_composition_rumen_micobial_cell, file=sprintf('%s/Table%d_Amino_acid_composition_rumen_micobial_cell.csv', out_dir, table_count), quote=F, row.names=T)
	
	table_count = table_count + 1 
	amino_acid_composition = aminoacid_composition_calc (source_code)
	write.csv(amino_acid_composition, file=sprintf('%s/Table%d_Amino_acid_composition_of_isoluble_protein.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1 
	bact_amino_supply = bacterial_aminoacid_calc (source_code)
	write.csv(bact_amino_supply, file=sprintf('%s/Table%d_Bacterial_amino_acid_supply_to_the_duodenum.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1 
	bact_amino_acid_digestion = bacterial_amino_acid_digestion_calc(source_code) 
	write.csv(bact_amino_acid_digestion, file=sprintf('%s/Table%d_Bacterial_amino_acid_digestion.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1
	feed_amino_acid_supply = feed_amino_acid_supply_calc(source_code) 
	write.csv(feed_amino_acid_supply, file=sprintf('%s/Table%d_Feed_amino_acid_supply.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1
	feed_amino_acid_digestion = feed_amino_acid_digestion_calc(source_code)
	write.csv(feed_amino_acid_digestion, file=sprintf('%s/Table%d_Feed_amino_acid_digestion.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1 
	total_duodenal_amino_acid_supply = total_duodenal_amino_acid_supply_calc(source_code)
	write.csv(total_duodenal_amino_acid_supply, file=sprintf('%s/Table%d_Total_duodenal_amino_acid_supply.csv', out_dir, table_count), quote=F, row.names=T)

	table_count = table_count + 1 
	total_metabolizable_supply = total_metabolizable_supply_calc(source_code)
	METsup = METsup_calc (source_code)
	LYSsup = LYSsup_calc (source_code)
	total_metabolizable_summary = sprintf('MetSup,%.0f\nLysSup,%.0f', METsup, LYSsup)
	write.csv(total_metabolizable_supply, file=sprintf('%s/Table%d_Total_metabolizable_amino_acid_supply.csv', out_dir, table_count), quote=F, row.names=T)
	write(total_metabolizable_summary,  file=sprintf('%s/Table%d_Total_metabolizable_amino_acid_supply.csv', out_dir, table_count), append=T)


}


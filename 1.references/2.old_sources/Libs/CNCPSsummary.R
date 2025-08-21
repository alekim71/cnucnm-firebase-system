

CNCPS_reports = function(source_code, out_dir) {

	# Import libraries 

	source(source_code)
	source(maintain_requirement_module)
	source(aminoacid_requirement_module)
	source(growth_requirement_module)
	source(lactation_requirement_module)
	source(production_prediction_module)
	source(intestinal_model_module)
	source(rumen_model_module)
	source(production_prediction_module)
	source(dmi_prediction_module)

	outfile = sprintf("%s/FinalReportSummary.csv", out_dir) 

	#========================#
	# Table1. Requirements   #
	#========================#

	aa_req_matrix = aareq_calc_for_others(source_code)
	aa_req_matrix_total = colSums(aa_req_matrix)

	main_me_req = MEmr_calc_for_others (source_code)
	main_mp_req = MPm_calc_others(source_code)
	main_met_req = aa_req_matrix ['MPAA', 'MET']
	main_lys_req = aa_req_matrix['MPAA', 'LYS']

	row_maintain = round(c(main_me_req, main_mp_req, main_met_req, main_lys_req, NULL, NULL, NULL),2)

	MEpreg = MEpreg_calc (source_code)	
	MPpreg = MPpreg_calc (source_code)
	MEmm = MEmm_calc (source_code) 
	MPmm = MPmm_calc (source_code)

	prg_me_req = MEpreg + MEmm 
	prg_mp_req = MPpreg + MPmm 
	prg_met_req = aa_req_matrix['LPAA', 'MET']
	prg_lys_req = aa_req_matrix['LPAA', 'LYS']

	row_pregnancy = round(c(prg_me_req, prg_mp_req, prg_met_req, prg_lys_req, NULL, NULL, NULL), 2)
	
	lct_me_req = MElact_calc (source_code)
	lct_mp_req = MPlact_calc (source_code)
	lct_met_req = aa_req_matrix['YPAA', 'MET']
	lct_lys_req = aa_req_matrix['YPAA', 'LYS']

	row_lactation = round(c(lct_me_req, lct_mp_req, lct_met_req, lct_lys_req, NULL, NULL, NULL)	, 2)

	grw_me_req = MEgr_calc_for_others(source_code)
	grw_mp_req = MPg_calc_for_others(source_code)
	grw_met_req = aa_req_matrix['RPAA', 'MET']
	grw_lys_req = aa_req_matrix['RPAA', 'LYS']

	row_growth = round(c(grw_me_req, grw_mp_req, grw_met_req, grw_lys_req, NULL, NULL, NULL), 2)

	total_me_required = MEreq_calc_for_others(source_code)
	total_mp_required = MPreq_calc_for_others(source_code)
	total_met_required = aa_req_matrix_total['MET'] 
	total_lys_required = aa_req_matrix_total['LYS'] 
	total_ca_required = NULL
	total_p_required = NULL
	total_k_required = NULL

	row_total_required = round(c(total_me_required , total_mp_required, total_met_required, total_lys_required, NULL, NULL, NULL), 2)

	total_me_supplied = MEsup_calc(source_code)
	total_mp_supplied = MPsup_calc(source_code)
	total_met_supplied = METsup_calc(source_code)
	total_lys_supplied = LYSsup_calc(source_code)
	total_ca_supplied = Casup_calc(source_code)
	total_p_supplied = Psup_calc(source_code)
	total_k_supplied = Ksup_calc(source_code)

	row_total_supplied = round(c(total_me_supplied, total_mp_supplied, total_met_supplied, total_lys_supplied, total_ca_supplied, total_p_supplied, total_k_supplied), 2)

	total_me_balance = MEbal_calc_for_others(source_code) 
	total_mp_balance = MPbal_calc_for_others(source_code) 

	total_met_balance =  total_met_supplied - total_met_required
	total_lys_balance = total_lys_supplied - total_lys_required  

	if (typeof(total_ca_required) == "NULL") {
		total_ca_balance = total_ca_supplied
	} else {
		total_ca_balance = total_ca_supplied - total_ca_required 
	}

	if (typeof(total_p_required) == "NULL")  {
		total_p_balance = total_p_supplied 
	} else {
		total_p_balance = total_p_supplied - total_p_required 
	}
	
	if (typeof(total_k_required) == "NULL") {
		total_k_balance = total_k_supplied 
	} else {
		total_k_balance = total_k_supplied - total_k_required 
	}

	row_total_balance = round(c(total_me_balance, total_mp_balance, total_met_balance, total_lys_balance, total_ca_balance, total_p_balance, total_k_balance), 2)


	write("", file=outfile)
	write("Summary Report\n\nRequirements\n,ME(Mcal/day),MP(g/day),MET(g/day),LYS(g/day),Ca(g/day),P(g/day),K(g/day)", file=outfile,)
	write(sprintf('Maintenancy,%s', paste(row_maintain, collapse=',')), file=outfile, append=T)
	write(sprintf('Pregnancy, %s', paste(row_pregnancy, collapse=',')), file=outfile, append=T)
	write(sprintf("Lactation,%s", paste(row_lactation, collapse=',')), file=outfile, append=T)
	write(sprintf("Allowable_Growth,%s", paste(row_growth, collapse=',')), file=outfile, append=T)
	write(sprintf("Total_required,%s", paste(row_total_required, collapse=',')), file=outfile, append=T)
	write(sprintf("Total_supplied,%s", paste(row_total_supplied, collapse=',')), file=outfile,append=T)
	write(sprintf("Balance,%s", paste(row_total_balance, collapse=',')), file=outfile, append=T)



	#=====================#
	# Table 2. Feed costs #
	#=====================#

	write("\n\nFeed Costs\nCost per Animal/day,,won/day\nCost per kg ME Allowable Gain/day,,won/kg day\nCost per MP Allowable Gain/day,,won/kg day\n\n", file=outfile, append=T)

	#=======================#
	# Table 3. Diet summary #
	#=======================#
	dm_perc = intake_dm_calc(source_code)
	feed_id_list = rownames(dm_perc)

	write('Diet summary\nFeed_ID,Feed_name,DM,AF', file=outfile, append=T)
	for (i in (1:(length(feed_id_list)-1))) {
		feed_id = feed_id_list[i]
		feed_name = as.character(dm_perc[feed_id, 'Feed_name'])
		feed_dm = round(as.numeric(dm_perc[feed_id, 'DM']), 2)
		feed_af = round(as.numeric(dm_perc[feed_id, 'AF']), 2)
		row_data = sprintf("%s,%s,%.2f,%.2f",feed_id, feed_name, feed_dm, feed_af)
		write(row_data, file=outfile, append=T)
	}

	write("\n\nDiet concentration\n", file=outfile, append=T)


	rational_dry_matter = dietdry_calc(source_code)
	ApparentTDN = AppTDN_calc(source_code) * 100 
	ME = MEC_calc(source_code)
	NEma = NEma_total_calc(source_code)
	NEga = 	NEga_total_calc(source_code)

	CP = DietCP_calc(source_code)
	SolubleProtein = DietSOLP_calc(source_code)
	DIP = DietDIP_calc(source_code)	

	NDF = dietndf_calc(source_code)
	peNDF = DietpeNDF_calc(source_code)
	phys_eff_ndf_bal = NULL 

	total_forage = DietForage_calc(source_code)
	total_NFC = DietNFC_calc(source_code)

	Ca = dietCa_calc(source_code)
	P = dietP_calc(source_code)
	DCAB1 = DCAB1_calc(source_code)
	DCAB2 = DCAB2_calc(source_code) 
	DietLignin = DietLignin_calc(source_code)
	DietLigninNDF = DietLigNDF_calc(source_code)

	FNDFIpBW = FNDFIpBW_calc(source_code)
	DietA = DietA_calc(source_code)
	DietB1 = DietB1_calc(source_code)

	write(sprintf("Ration Dry Matter,%.0f,%%AF", rational_dry_matter), file=outfile, append=T)
	write(sprintf("Apparent TDN,%.0f,%%DM", ApparentTDN), file=outfile, append=T)
	write(sprintf("ME,%.2f,Mcal/kg", ME), file=outfile, append=T)	
	write(sprintf("NEm,%.2f,Mcal/kg", NEma), file=outfile, append=T)	
	write(sprintf("NEg,%.2f,Mcal/kg", NEga), file=outfile, append=T)	
	write(sprintf("CP,%.1f,%%DM", CP), file=outfile, append=T)	
	write(sprintf("Soluble Protein,%.1f,%%CP", SolubleProtein), file=outfile, append=T)	
	write(sprintf("DIP,%.1f,%%", DIP), file=outfile, append=T)	
	write(sprintf("NDF,%.1f,%%DM", NDF), file=outfile, append=T)	
	write(sprintf("peNDF,%.1f,%%DM", peNDF), file=outfile, append=T)	
	write(sprintf("Physically Effective NDF Bal.,,kg/d"), file=outfile, append=T)	
	write(sprintf("Total Forage in Ration,%.1f,%%DM", total_forage), file=outfile, append=T)	
	write(sprintf("Total NFC,%.1f,%%DM", total_NFC), file=outfile, append=T)	
	write(sprintf("Ca,%.2f,%%DM", Ca), file=outfile, append=T)	
	write(sprintf("P,%.2f,%%DM", P), file=outfile, append=T)	
	write(sprintf("DCAB1(simple),%.0f,meq/kg", DCAB1), file=outfile, append=T)	
	write(sprintf("DCAB2(Complex),%.0f,meq/kg", DCAB2), file=outfile, append=T)	
	write(sprintf("Dietary Lignin(%%DM),%.1f,%%DM", DietLignin), file=outfile, append=T)
	write(sprintf("Dietary Lignin(%%NDF),%.1f,%%NDF", DietLigninNDF), file=outfile, append=T)	
	write(sprintf("Forage NDF Intake (%%BW),%.2f,%%BW",FNDFIpBW), file=outfile, append=T)	
	write(sprintf("CHO A fraction,%.2f,%%DM", DietA), file=outfile, append=T)	
	write(sprintf("CHO B1 fraction,%.2f,%%DM", DietB1), file=outfile, append=T)	

	write('\n\nSummary of Animal Inputs', file=outfile, append=T)

	source(input_database)
	animal_type_name = animal_type_list[animal_type]
	write(sprintf("Animal Type,%s", animal_type_name), file=outfile, append=T)
	write(sprintf("Age,%0f,Month", age), file=outfile, append=T)
	write(sprintf("Shrunk Body Weight,%0f,kg", SBW), file=outfile, append=T)
	write(sprintf("Mature Weight,%0f,kg", MW), file=outfile, append=T)
	write(sprintf("Condition Score(1-5),%0f", BCS), file=outfile, append=T)

	write("\n\nAnimal Performance", file=outfile, append=T)

	DMI = DMI_intake_calc(source_code)
	DMIpred = DMIpred_calc_export_for_other(source_code)

	MEgain = MEgain_calc_export_for_others(source_code)
	MPgain = MPgain_calc_export_for_others(source_code)

	feed_p_gain = DMI/(min(MEgain,MPgain))
	gain_p_feed = (min(MEgain,MPgain))/DMI

	write(sprintf('DMI-Actual,,%.2f,kg/d', DMI), file=outfile, append=T)
	write(sprintf('DMI-Predicted,,%.2f,kg/d', DMIpred), file=outfile, append=T)
	write(sprintf('ME Allowable Gain,,%.2f,kg/d', MEgain), file=outfile, append=T)
	write(sprintf('MP Allowable Gainn,,%.2f,kg/d', MPgain), file=outfile, append=T) 
	write("Feed efficiency\n", file=outfile, append=T)
	write(sprintf(',Feed/Gain,%.2f', feed_p_gain), file=outfile, append=T)
	write(sprintf(',Gain/Feed,%.2f', gain_p_feed), file=outfile, append=T) 

	write('\n\nRumen Values\n', file=outfile, append=T)
	MPbact = round(MPbact_calc(source_code), 0)
	MPfeed = round(MPfeed_calc(source_code), 0)

	RVMPb = RVMPb_calc(source_code)
	RVMPu = RVMPu_calc(source_code)

	PepBal = PepBal_calc(source_code)
	PEPBALp = PEPBALp_calc(source_code)

	RNB = RNB_calc(source_code)
	RNBp = 	RNBp_calc(source_code)
	FCRedRatio = FCRedRatio_calc(source_code)

	pH = pH_calc(source_code)
	NIE = NIE_calc(source_code)

	PredPUN = NULL 

	UreaCost = UreaCost_calc(source_code)

	write(sprintf('MP From Bact.,%.0f,g/d', MPbact), file=outfile, append=T)
	write(sprintf('MP From Undeg. Feed,%.0f,g/d', MPfeed), file=outfile, append=T)
	write(sprintf('MP From Bact.,%.0f,%%MP', RVMPb), file=outfile, append=T) 
	write(sprintf('MP From Undeg. Feed ,%.0f,%%MP Sup', RVMPu), file=outfile, append=T)
	write(sprintf('Peptide Balance,%.0f,g/d', PepBal), file=outfile, append=T)
	write(sprintf('%% Peptide Balance,%.0f,%%', PEPBALp), file=outfile, append=T)
	write(sprintf('Ruminal N Balance,%.0f,g/d', RNB), file=outfile, append=T)
	write(sprintf('%% Ruminal N Balance,%.0f,g/d', RNBp), file=outfile, append=T)
	write(sprintf('%% Reduction in FC Digestion,%.10f,%%', FCRedRatio), file=outfile, append=T)
	write(sprintf('Predicted Ruminal pH,%.2f', pH), file=outfile, append=T) 
	write(sprintf('Excess N Extracted,%.0f,g/d', NIE), file=outfile, append=T)
	write(sprintf('Predicted PUN,,mg/dl'), file=outfile, append=T)
	write(sprintf("Urea Cost,%.2f,Mcal/d", UreaCost), file=outfile, append=T)



	write('\n\nSummary of Environmenal Inputs\n', file=outfile, append=T)
	HCcode_name = hair_condition_list[HCcode]
	cowshed_code_name = cowshed_list[cowshed_code]

	write(sprintf('Previouse Temperature,%.0f,Celsius',Tp), file=outfile, append=T)
	write(sprintf('Current Temperature,%.0f,Celsius', Tc), file=outfile, append=T)
	write(sprintf('Humidity,%.0f,%%', RHC), file=outfile, append=T)
	write(sprintf('Wind speed,%.0f,Km/h', WS), file=outfile, append=T)
	write(sprintf('Coat Condition,%s status', HCcode_name), file=outfile, append=T)
	write(sprintf('Housing Type,%s', cowshed_code_name), file=outfile, append=T)



}
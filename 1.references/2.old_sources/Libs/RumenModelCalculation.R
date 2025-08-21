#=================================#
# Rumen model calculation execute #
# Date : 2014-10-28               #
# Written by Hyesun Park          #
#=================================#


rumen_model = function(source_code, rumen_model_module, today) {


	source(source_code)
	source(rumen_model_module)

	out_dir = sprintf('%s\\rumen_model', today)
	shell(sprintf('mkdir %s', out_dir)) 

	table_count = 0 

	feed_subset = feed_infor_get(source_code)
	feed_subset.total_calc = feed_info_total_calc(source_code)	
	feed_subset.total_calc = paste(c('', '', '', '', '', '', feed_subset.total_calc), collapse=',')

	table_count  = table_count + 1 
	write.csv(feed_subset, file=sprintf('%s/Table%d_FeedLibraryCalc.csv', out_dir, table_count), quote=F)
	write(feed_subset.total_calc, file=sprintf('%s/Table%d_FeedLibraryCalc.csv', out_dir, table_count), append=T)

	table_count = table_count + 1 
	intake_carbprot_t1 = intake_carbprot_p_DM(source_code)
	write.csv(intake_carbprot_t1, file=sprintf('%s/Table%d_Carbohydrate_and_protein_intake_perc_DM.csv', out_dir, table_count), quote=F, row.names=F) 

	table_count = table_count + 1 
	dm_intake = intake_dm_calc(source_code)
	write.csv(dm_intake, file=sprintf('%s/Table%d_Dry_matter_intake.csv', out_dir, table_count), quote=F, row.names=F)

	#Feed energy_contents 
	table_count = table_count + 1 
	tdn1x = sprintf("TDN 1x,%.2f,%%DM", tdn1x_energy_calc(source_code))
	de1x = sprintf("DE1x,%.2f,Mcal/kg", de1x_energy_calc(source_code))
	me1x = sprintf("ME1x,%.2f,Mcal/kg", me1x_energy_calc(source_code))
	nema1x = sprintf("NEma1x,%.2f,Mcal/kg", NEma1x_energy_calc(source_code))

	energy_table = c(tdn1x, de1x, me1x, nema1x)
	write(energy_table, file=sprintf('%s/Table%d_Feed_Enerygy_Contents.csv', out_dir, table_count))

	table_count = table_count + 1 
	intake_carbprot_t2 = intake_carbprot_p_day(source_code)
	write.csv(intake_carbprot_t2, file=sprintf('%s/Table%d_Intake_carbohydrate_and_protein_g_per_day.csv', out_dir, table_count), quote=F, row.names=F)

	table_count = table_count + 1 
	passage_rate = rumen_passage_rate_calc(source_code)
	write.csv(passage_rate, file=sprintf('%s/Table%d_Passage_rate.csv', out_dir, table_count), quote=F, row.names=F)	

	table_count = table_count + 1 
	rumen_passage_ph = rumen_passage_rate_by_ph_calc (source_code)
	write.csv(rumen_passage_ph, file=sprintf('%s/Table%d_Passage_rate_pH.csv', out_dir, table_count), quote=F, row.names=F)	

	table_count = table_count + 1 
	rumen_passage_ph_adj = adj_rumen_passage_rate_by_ph_calc(source_code)
	write.csv(rumen_passage_ph_adj, file=sprintf('%s/Table%d_adjusted_passage_rate_pH.csv', out_dir, table_count), quote=F, row.names=F)		


	table_count = table_count + 1 
	ndf_diet = NDFdiet_calc(source_code)
	peNDF = peNDF_calc (source_code)
	pH = pH_calc(source_code)
	KMsc = KMsc_calc ()
	YGsc = YGsc_calc ()

	KMscprime = KMscprime_calc(source_code)
	YGscprime = YGscprime_calc(source_code)
	RelY = RelY_calc(source_code)

	rumen_passage_ph_subset = c(
		sprintf('NDF Diet,%.2f,%%DM', ndf_diet), 
		sprintf('peNDF Diet,%.2f,%%DM', peNDF), 
		sprintf('pH prediction,%.2f', pH),
		sprintf('km1(KMsc),%.2f,g/g Hour', KMsc),
		sprintf('YG1(YGsc),%.2f,g/g Hour', YGsc), 
		sprintf('km1\',%.3f,g/g Hour', KMscprime), 
		sprintf('YG1\',%.3f,g/g Hour',YGscprime), 
		sprintf('RelY,%.3f', RelY)
		)

	write(rumen_passage_ph_subset, file=sprintf('%s/Table%d_rumen_passage_ph_subset.csv', out_dir, table_count))

	table_count = table_count + 1 
	rumen_degradation_table = rumen_degradation_calc(source_code)

	RDCA = RDCA_calc(source_code)
	RDCB1 = RDCB1_calc(source_code)
	RDCB2 = RDCB2_calc(source_code)

	RDPA = RDPA_calc(source_code)
	RDPB1 = RDPB1_calc(source_code)
	RDPB2 = RDPB2_calc(source_code)
	RDPB3 = RDPB3_calc(source_code)
	RDPEP = RDPEP_calc(source_code)

	DietDIP = DietDIP_calc(source_code)

	RECA = RECA_calc(source_code)
	RECB1 = RECB1_calc(source_code)
	RECB2 = RECB2_calc(source_code)
	RECC = RECC_calc(source_code)

	REPB1 = REPB1_calc(source_code)
	REPB2 = REPB2_calc(source_code)
	REPB3 = REPB3_calc(source_code)

	REPC = REPC_calc(source_code)
	REP = sum(REPB1, REPB2, REPB3, REPC)

	rumen_degradation_summary = sprintf(',Total,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\n\nDietDIP,%.1f,%%CP\nTotal RUP,%.0f,g/day', 
		RDCA, RDCB1, RDCB2, RDPA, RDPB1, RDPB2, RDPB3, RDPEP, RECA, RECB1, RECB2, RECC, REPB1, REPB2, REPB3, REPC, DietDIP, sum(REPB1,REPB2,REPB3, REPC))

	write.csv(rumen_degradation_table, file=sprintf('%s/Table%d_rumen_degradataion.csv', out_dir, table_count), quote=F, row.names=F)		
	write(rumen_degradation_summary, file=sprintf('%s/Table%d_rumen_degradataion.csv', out_dir, table_count), append=T )

	table_count = table_count + 1 
	write('Microbial Growth Equitions\n', file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count))
	write(sprintf('KM,%2f', KMsc), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T)
	write(sprintf('KM2(KMnsc),%.2f', KMnsc_calc()), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('YG1(max. Yeild FC),%.1f', YGsc), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('YG2(max.Yield NFC;YGnsc),%.1f', YGnsc_calc()), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('peNDF diet,%.2f', peNDF_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('YG1 (YG1mod),%.1f', YG1mod_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('YG2 (YG2mod),%.1f', YG2mod_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('INOPHORE,%.2f\n', ionophore_get_to_rumen(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDE UPTAKE(PepUpRate),%.1f', PepUpRate_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('REPEP,%.0f', RDPEP), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RDCA+RDCB1,%.0f', (RDCA + RDCB1)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RDPEP/RDPEP+RDCA+RDCB1(Ratio),%.2f', Ratio_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('IMP NSC YEILD(Imp),%.2f\n', Imp_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NFC BACT (NFCbact),%.0f', NFCbact_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NFCBACTMASS,%.0f', NFCBactMass_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NFCBACTPEPUP,%.0f', NFCBactPepUp_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RDPEPh,%.0f\n', RDPEPh_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('GROWTH TIME,%.2f', GrowthTime_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('DISAPP TIME,%.2f', DisappTime_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPX,%.0f', PepX_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDEUP,%.0f', PeptideUp_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDEPASS,%.0f', PeptidePass_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDEACC,%.0f', PeptideAcc_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDEUPN,%.0f', PeptideUpN_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPTIDEREQN,%0f', PeptideReqN_calc(source_code)),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Peptide balance,%.0f,%% req', PEPBALp_calc(source_code)),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('PEPBAL,%.2f', PepBal_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NFC_NH3_REQ,%0f', NFC_NH3_REQ_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NH3_BACT,%.0f', NH3_BACT_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NH3_DIET,%.0f', NH3_DIET_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RECYCLEDN,%.2f', RECYCLEDN_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('FC_NH3_AVAIL,%.0f', FC_NH3_AVAIL_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('FC_NH3_REQ,%.0f', FC_NH3_REQ_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('BACTNBALANCE,%.2f\n\n', BACTNBALANCE_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('NSC Bacterial Nitrogen Balance\n,Peptides,Ruminal NH3'), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Available,%.0f,%.0f', PeptideUpN_calc(source_code), (NH3_BACT_calc(source_code) + NH3_DIET_calc(source_code) + RECYCLEDN_calc(source_code))), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Required,%.0f,%.0f', PeptideReqN_calc(source_code), NFC_NH3_REQ_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Balance,%.0f,%.0f\n\n', PepBal_calc(source_code), FC_NH3_AVAIL_calc(source_code)),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('SC Bacterial Nitrogen Balance\n,Ruminal NH3'), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Available,%.0f', FC_NH3_AVAIL_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Required,%.0f', FC_NH3_REQ_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Balance,%.0f\n\n', BACTNBALANCE_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf(',TOTAL BACTERIAL N BALANCE'), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Available,%.0f', (NH3_DIET_calc(source_code)+RECYCLEDN_calc(source_code)+PeptideUpN_calc(source_code))),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Required,%.0f', (PeptideReqN_calc(source_code)+NFC_NH3_REQ_calc(source_code)+FC_NH3_REQ_calc(source_code))), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Balance,%0.f\n\n', ((NH3_DIET_calc(source_code)+RECYCLEDN_calc(source_code)+PeptideUpN_calc(source_code)) - (PeptideReqN_calc(source_code)+NFC_NH3_REQ_calc(source_code)+FC_NH3_REQ_calc(source_code)))),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RNBp,%.0f,%%\n', RNBp_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Bacterial Nitrogen(BactN),%.0f,g/d', BactN_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Nitrogen in Excess(EN; NIE),%.0f,g/d', NIE_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RDP,%.0f,g/day', TotalRDP_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('RUP,%.0f,g/day', TotalRUP_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('MP from bacteria,%.0f,g/day,%.5f,%%MP', MP_from_bact_calc(source_code), RVMPb_calc(source_code)),file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('MP from RUP,%.0f,g/day,%.5f,%%MP', MP_from_RUP_calc(source_code), RVMPu_calc(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
	write(sprintf('Total MP supply,%.0f,g/day', MPavail_get(source_code)), file=sprintf('%s/Table%d_MicrobialGrowth.csv', out_dir, table_count), append=T) 
			
	table_count = table_count + 1 
	microbial_composition_db = microbial_composition_database(source_code)  
	write.csv(microbial_composition_db, file = sprintf('%s/Table%d_Microbial_composition_database.csv', out_dir, table_count), quote=F, row.names=F)

	table_count = table_count + 1 
	microbial_fermentation = microbial_ferment_calc(source_code)
	ferment_summary = sprintf(',,,,,%.0f,,,%.0f,%.0f,,,%.0f\n\nTOTAL YEILD,%.0f,g/d', 
			ca_bact_yield_calc(source_code), cb1_bact_yield_calc(source_code), nsc_bact_yield_calc(source_code),FCbact_calc(source_code), TotalBact_calc(source_code))

	write.csv(microbial_fermentation, file=sprintf('%s/Table%d_microbial_fermentation.csv', out_dir, table_count), quote=F, row.names=F)		
	write(ferment_summary, file=sprintf('%s/Table%d_microbial_fermentation.csv', out_dir, table_count), append=T)

	table_count = table_count + 1 
	ruminal_nitrogen = Ruminal_nitrogen_deficiency_adjustment_calc(source_code)	
	ruminal_nitrogen_summary = c(sprintf(",%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\n\n", sum(as.numeric(ruminal_nitrogen[,'EFCBact'])), 
				sum(as.numeric(ruminal_nitrogen[,'ENFCBact'])), 
					sum(as.numeric(ruminal_nitrogen[, 'ETotalBact'])), sum(as.numeric(ruminal_nitrogen[,'EBactRatio'])), 
					sum(as.numeric(ruminal_nitrogen[,'NAllowableBact'])), sum(as.numeric(ruminal_nitrogen[,'BactRed'])),
					sum(as.numeric(ruminal_nitrogen[,'EFCBactRatio'])), sum(as.numeric(ruminal_nitrogen[,'FCBactRed'])), 
					sum(as.numeric(ruminal_nitrogen[,'NFCBact'])), sum(as.numeric(ruminal_nitrogen[,'FCRed'])),
					sum(as.numeric(ruminal_nitrogen[,'RDCB2'])), sum(as.numeric(ruminal_nitrogen[,'RECB2'])), 
					sum(as.numeric(ruminal_nitrogen[,'ProtB3Red'])), sum(as.numeric(ruminal_nitrogen[,'RDPB3']))), 
					sprintf('NAllowableBact,%.0f', NAllowableBact_calc(source_code)), 
					sprintf('E Allowable Bact,%.0f', EAllowableBact_calc(source_code)), 
					sprintf('FCRedRaio,%.1f', FCRedRatio_calc(source_code)))

	write.csv(ruminal_nitrogen, file=sprintf('%s/Table%d_Ruminal_Nitrogen_Defficiency_Adjustment.csv', out_dir, table_count), quote=F, row.names=F)		
	write(ruminal_nitrogen_summary, file=sprintf('%s/Table%d_Ruminal_Nitrogen_Defficiency_Adjustment.csv', out_dir, table_count), append=T)

	table_count = table_count + 1 	
	ruminal_feed_degradataion = adj_ruminal_feed_degradation_calc(source_code) 	
	write.csv(ruminal_feed_degradataion, file=sprintf('%s/Table%d_Adjusted_Ruminal_Feed_Degradation_For_Escaping_Peptides.csv', out_dir, table_count))	

	table_count = table_count + 1 

	ruminal_feed_escaping = ruminal_feed_escaping_calc(source_code)
	ruminal_feed_escaping_summary = sprintf(',Total,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\nTotal RUP,%.0f,g/d',
				sum(as.numeric(ruminal_feed_escaping[,'RECA'])), sum(as.numeric(ruminal_feed_escaping[,'RECB1'])),
				sum(as.numeric(ruminal_feed_escaping[,'adjRECB2'])), sum(as.numeric(ruminal_feed_escaping[,'RECC'])), 
				sum(as.numeric(ruminal_feed_escaping[,'REPA'])), sum(as.numeric(ruminal_feed_escaping[,'adjREPB1'])),
				sum(as.numeric(ruminal_feed_escaping[,'adjREPB2'])), sum(as.numeric(ruminal_feed_escaping[,'adjREPB3'])),
				sum(as.numeric(ruminal_feed_escaping[,'REPC'])), TotalRDP_calc(source_code)) 

	write.csv(ruminal_feed_escaping, file=sprintf('%s/Table%d_Adjusted_Ruminal_Feed_Degradation_For_Escaping_Peptides.csv', out_dir, table_count))		
	write(ruminal_feed_escaping_summary, file=sprintf('%s/Table%d_Adjusted_Ruminal_Feed_Degradation_For_Escaping_Peptides.csv', out_dir, table_count), append =T)


	table_count = table_count + 1 
	microbial_composition = microbial_composition_calc(source_code)	 
	microbial_composition_summary = sprintf(',Total,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f',
			REBTP_total_calc(source_code), REBCW_total_calc(source_code),REBNA_total_calc(source_code),
			REBCA_total_calc(source_code), REBCB1_total_calc(source_code), REBCHO_total_calc(source_code),
			REBFAT_total_calc(source_code),REBASH_total_calc(source_code), microbial_compos_total_calc(source_code))
	write.csv(microbial_composition, file=sprintf('%s/Table%d_Microbial_Composition.csv', out_dir, table_count))		
	write(microbial_composition_summary, file=sprintf('%s/Table%d_Microbial_Composition.csv', out_dir, table_count), append =T)

	table_count = table_count + 1 
	rumen_degradable_feed = rumen_degradable_feed_calc(source_code)
	
	rumen_degradable_feed_summary = sprintf(',Total,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\nTotal RDP,%.0f,g/d',
			sum(as.numeric(rumen_degradable_feed[,'RDCA'])) , sum(as.numeric(rumen_degradable_feed[,'RDCB1'])), 
			sum(as.numeric(rumen_degradable_feed[,'RDCB2'])), sum(as.numeric(rumen_degradable_feed[,'RDPA'])),
			sum(as.numeric(rumen_degradable_feed[,'RDPB1'])), sum(as.numeric(rumen_degradable_feed[,'RDPB2'])),
			sum(as.numeric(rumen_degradable_feed[,'RDPB3'])), TotalRDP_calc(source_code))

	write.csv(microbial_composition, file=sprintf('%s/Table%d_Rumen_Degradable_Feed.csv', out_dir, table_count))
	write(rumen_degradable_feed_summary, file=sprintf('%s/Table%d_Rumen_Degradable_Feed.csv', out_dir, table_count), append =T)
								
}


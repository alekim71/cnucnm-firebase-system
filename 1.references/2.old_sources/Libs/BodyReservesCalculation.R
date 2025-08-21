#===================================#
# Body reserves calculation Execute #
# Date : 2014-10-21                 #
# Written by Hyesun Park            #
#===================================#


body_reserves_calculation = function(source_code, out_dir) {

	source(source_code)
	source(body_reserves_module)

	AF = AF_calc(source_code)
	AP = AP_calc(source_code)

	EBWr = EBWr_calc(source_code)
	TF = TF_calc (source_code)
	TBP = TBP_calc(source_code)
	TE = TE_calc(source_code)

	MEbal = MEbal_get_to_bodyreserves(source_code)

	BCS_AD = BCS_AD_calc(source_code)
	EBWBCS5 = EBWBCS5_calc(source_code)
	BCSneg = BCSneg_calc (source_code) 
	BCSnegNEL = BCSnegNEL_calc(source_code)
	BCSpos = BCSpos_calc(source_code)
	BCSposNEL = BCSposNEL_calc (source_code)
	BCS_BW = BCS_BW_calc(source_code)

	NEDLW = NEDLW_calc(source_code)
	DLW = DLW_calc(source_code)

	out_file = sprintf("%s/Body_reserves.csv", out_dir)

	data_summary = c(
		'[Summary of equations to predict body reserves]', 
		sprintf("BCS_beef,,%s", BCS_beef), 
		sprintf('AF,,%.3f,g/g', AF), 
		sprintf('AP,,%.3f,g/g', AP), 
		sprintf('EBWr,,%.0f,kg', EBWr), 
		sprintf('TF,,%.0f,kg', TF), 
		sprintf('TBP,,%.0f,kg', TBP,units='kg'), 
		sprintf('TE,,%.0f,Mcal', TE, units='Mcal'), 
		sprintf('BCS_AD,,%.0f', BCS_AD), 
		sprintf('EBWBCS5,,%.0f,kg\n', EBWBCS5), 
		sprintf('BCSneg,,%.0f,Mcal', BCSneg), 
		sprintf('BCSnegNEL,,%.0f,Mcal\n', BCSnegNEL), 
		sprintf('BCSpos,,%.0f,Mcal', BCSpos), 
		sprintf('BCSposNEL,,%.0f,Mcal\n',BCSposNEL), 
		sprintf('BCS_BW,,%.0f,kg\n\n', BCS_BW), 
		sprintf('NEDLW,,%.3f,Mcal/kg', NEDLW), 
		sprintf('DLW,,%.6f,kg/d', DLW)
		)

	write(data_summary, out_file)


}


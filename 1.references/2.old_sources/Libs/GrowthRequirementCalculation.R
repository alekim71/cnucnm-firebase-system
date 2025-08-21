#=======================================================#
# Growth and pregnancy requirements calculation execute #
# Date : 2014-10-21                                     #
# Written by Hyesun Park                                #
#=======================================================#


growth_require_calculation = function(source_code, out_dir) {

	source(source_code)
	source(growth_requirement_module)

	# Calculation start 

	breed = breed_code 

	# SRW Setting  : 400(22%), 435(25%), 462(27%), 478(28%)
	SRW = SRW_calc (source_code)  	
	EBW = EBW_calc(source_code)
	EqSBW = EqSBW_calc(source_code)
	EqEBW = EqEBW_calc(source_code)

	TargetSWG = TargetSWG_calc(source_code)
	TargetEBG = TargetEBG_calc(source_code)
	NEgr = NEgr_calc(source_code)

	REG = REG_get_to_growth (source_code) 
	MEgr = MEgr_calc (source_code)
	NPg = NPg_calc (source_code)

	EqSBWg = EqSBWg_calc (source_code)
	MPg = MPg_calc (source_code)

	MPmm = MPmm_calc (source_code)
	MEmm = MEmm_calc (source_code)

	TPW = TPW_calc (source_code)

	TCA = TCA_calc (source_code)	
	TPA = TPA_calc(source_code)

	Tage = Tage_calc(source_code)

	BPADG = BPADG_calc(source_code)

	TCW_1 = TCW_1_calc(source_code)
	TCW_2 = TCW_2_calc(source_code)
	TCW_3 = TCW_3_calc(source_code)
	TCW_4 = TCW_4_calc(source_code)

	DIP_t = DIP_t_calc(source_code)
	APADG = APADG_calc(source_code)
	DtoP = DtoP_calc(source_code)

	ACADG = ACADG_calc(source_code)

	breed_target_ADG = breed_target_ADG_calc(source_code)

	ADGpreg_k = ADGpreg_k_calc(source_code)
	ADGpreg = ADGpreg_calc(source_code)

	CpW = CpW_calc(source_code)
	MEpreg = MEpreg_calc(source_code)
	MPpreg = MPpreg_calc(source_code)

	out_file = sprintf("%s/Growth_and_Pregnancy_requirement.csv", out_dir)

	data_summary = c("[Summary of equations to predict growth requirements]\n",
		sprintf("breed,,%s\n", breed_code), 
		"Energy and protein requirements", 		
		sprintf('SRW,,%.0f,kg', SRW), 
		sprintf('SBW,,%.0f,kg', SBW), 
		sprintf('EBW,,%.0f,kg', EBW), 
		sprintf('AFBW,,%.0f,kg', AFBW), 
		sprintf('EqSBW,,%.0f,kg', EqSBW), 
		sprintf('EqEBW,,%.0f,kg\n',EqEBW), 
		'Prediction of average daily gain (ADG) when net energy available for gain', 
		sprintf("SWG,,%.2f,kg/d", TargetSWG), 
		sprintf("EBG,,%.2f,kg/d", TargetEBG), 
		sprintf('NEgr,,%.2f,Mcal/d', NEgr), 
		sprintf("MEgr,,%.2f,Mcal/d", MEgr), 
		sprintf('NPg,,%.2f,g/d\n', NPg), 
		'For NPg/MPg conversion only',
		sprintf('EqSBWg,,%.0f,kg', EqSBWg), 
		sprintf("MPg,,%.0f,g/d\n", MPg),
		'Mammogenesis requirement',
		sprintf('MPmm,,%.2f,g/d', MPmm),
		sprintf('MEmm,,%.2f,Mcal/d\n', MEmm),
		'Predicting target weights (SBW) and rates of gain for herd replacement heifers', 
		sprintf("TPW,,%.0f,kg", TPW),
		sprintf("TCA,,%.0f,d", TCA),
		sprintf("TPA,,%.0f,d", TPA),
		sprintf("Tage,,%.0f,d", Tage),
		sprintf("BPADG,,%.2f,kg/d", BPADG),
		sprintf("TCW1,,%.0f,kg", TCW_1), 
		sprintf('TCW2,,%.0f,kg', TCW_2),
		sprintf('TCW3,,%.0f,kg', TCW_3), 
		sprintf("TCW4,,%.0f,kg", TCW_4), 
		sprintf('DIP(t),,%.0f,d', DIP_t), 
		sprintf('APADG,,%.2f,kg/d', APADG), 
		sprintf('DtoP,,%.0f,kg/d',  DtoP), 
		sprintf("ACADG,,%.2f,kg/d", ACADG), 
		sprintf('breed_target_ADG,,%.2f,kg/d\n\n',breed_target_ADG), 
		'[PREGNANCY Requirements]',
		'For pregnant animals, ADG due to gravid uterus growth is added to target and ME', 
		sprintf('CBW,,%.2f,kg', CBW), 
		sprintf('ADGpreg_k,,%.0f', ADGpreg_k),
		sprintf('ADGpreg,,%.2f,g/d', ADGpreg), 
		sprintf('CpW,,%.2f,kg', CpW, units='kg'), 
		sprintf('MEpreg,,%.2f,Mcal/d', MEpreg), 
		sprintf("MPpreg,,%.2f,g/d", MPpreg)
		)
	write(data_summary, out_file) 

}


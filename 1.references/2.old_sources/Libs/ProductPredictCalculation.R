
#===========================================#
# Predicting production calculation Execute #
# Date : 2014-10-24                         #
# Written by Hyesun Park                    #
#===========================================#



production_prediction_calculation = function(source_code, out_dir) {

	source(production_prediction_module)

	MEmr = MEmr_get_to_production(source_code)
	MEgr = MEgr_get_to_production(source_code)
	MEpreg = MEpreg_get_to_production(source_code)
	MEmm = MEmm_get_to_production(source_code)
	MElact = MElact_get_to_production(source_code)

	MEreq = MEreq_calc (source_code)
	MEsup = MEsup_calc (source_code)

	MEbal = MEbal_calc (source_code)

	MPm = MPm_get_to_production (source_code)
	MPg = MPg_get_to_production (source_code) 
	MPpreg = MPpreg_get_to_production (source_code)
	MPmm = MPmm_get_to_production (source_code)
	MPlact = MPlact_get_to_production (source_code)

	MPreq = MPreq_calc (source_code)
	MPsup = MPsup_calc (source_code)
	MPbal = MPbal_calc (source_code)

	MEI = MEI_get_to_production (source_code)
	MEC = MEC_get_to_production (source_code)

	NEma = NEma_get_to_production (source_code)
	NEga = NEga_get_to_production (source_code)
	NEla = NEla_get_to_production (source_code)

	REM = REM_calc (source_code)	
	REG = REG_calc (source_code)
	REL = REL_calc (source_code)

	MEproduction_avail = MEproduction_avail_calc (source_code)

	MEpreg_mm = MEpreg_mm_calc (source_code) 

	MEgandl_avail = MEgandl_avail_calc (source_code)

	MEg_avail = MEg_avail_calc(source_code)
	MElact_avail = MElact_avail_calc (source_code)
	
	NEg_avail = NEg_avail_calc (source_code) 

	MEgain = MEgain_calc (source_code)

	MEgain_prev = MEgain_prev_calc(source_code)
	MEmilk = MEmilk_calc(source_code)

	MPproduction_avail = MPproduction_avail_calc (source_code)

	MPpreg_mm  = MPpreg_mm_calc(source_code)

	MPgandl_avail = MPgandl_avail_calc 	(source_code)

	MPg_avail = MPg_avail_calc (source_code)

	MPlact_avail = MPlact_avail_calc (source_code)

	NPg_avail = NPg_avail_calc(source_code)

	MPgain = MPgain_calc (source_code)
	MPmilk = MPmilk_calc (source_code) 


	out_file = sprintf('%s/Prediction_production.csv', out_dir)

	data_summary = c( 
			'[Calculation of metabolizable energy and protein values]\n',
			'Calculation of metabolizable energy values',
			sprintf('MEmr,,%.2f,Mcal/d', MEmr),
			sprintf('MEgr,,%.2f,Mcal/d', MEgr), 
			sprintf('MEpreg,,%.2f,Mcal/d', MEpreg),
			sprintf('MEmm,,%.2f,Mcal/d', MEmm), 
			sprintf('MElact,,%.2f,Mcal/d\n', MElact), 
			sprintf('MEreq,,%.2f,Mcal/d', MEreq),
			sprintf('MEsup,,%.2f,Mcal/d', MEsup),
			sprintf('MEbal,,%.2f,Mcal/d\n',MEbal),
			'Calculation of metabolizable protein values',
			sprintf('MPm,,%.1f,g/d', MPm),
			sprintf('MPg,,%.1f,g/d', MPg), 
			sprintf('MPpreg,,%.1f,g/d', MPpreg),
			sprintf('MPmm,,%.1f,g/d',MPmm),
			sprintf('MPlact,,%.1f,g/d\n', MPlact),
			sprintf('MPpreq,,%.1f,g/d', MPreq),
			sprintf('MPsup,,%.1f,g/d', MPsup),
			sprintf('MPbal,,%.1f,g/d\n\n', MPbal),
			'Predicting metabolizable energy and protein values\n',
			'Feed energy values',
			sprintf('MEI,,%.2f,Mcal/d', MEI),
			sprintf('MEC,,%.2f,Mcal/kg', MEC),
			sprintf('NEma,,%.2f,Mcal/kg', NEma),
			sprintf('NEga,,%.2f,Mcal/kg', NEga),
			sprintf('NEla,,%.2f,Mcal/kg\n', NEla), 
			sprintf('REM,,%.2f', REM),
			sprintf('REG,,%.2f', REG), 
			sprintf('REL,,%.2f\n', REL),
			'Predicting metabolizable energy values',
			sprintf('MEI,,%.2f,Mcal/d', MEI),
			sprintf('MEmr,,%.2f,Mcal/d', MEmr), 
			sprintf('MEproduction_avail,,%.2f,Mcal/d\n', MEproduction_avail),
			sprintf('MEpreg_mm,,%.2f,Mcal/d',MEpreg_mm),
			sprintf('MEgandl_avail,,%.2f,Mcal/d\n', MEgandl_avail),
			sprintf('MElact,,%.2f,Mcal/d', MElact),
			sprintf('MElact_avail,,%.2f,Mcal\n',MElact_avail),
			sprintf('MEg_avail,,%.2f,Mcal/d',MEg_avail),
			sprintf('NEg_avail,,%.2f,Mcal/d\n', NEg_avail),
			'Predicting metabolizable energy gain',
			sprintf('MEgain,,%.2f,kg/d', MEgain),
			sprintf(',Value of previous equation,%.2f,kg/d', MEgain_prev),
			sprintf('MEmilk,,%.2f,kg/d\n', MEmilk),
			'Predicting metabolizable protein values',
			sprintf('MPsup,,%.0f,g/d',MPsup),
			sprintf('MPm,,%.0f,g/d', MPm),
			sprintf('MPproduction_avail,,%.0f,g/d\n', MPproduction_avail), 
			sprintf('MPpreg_mm,,%.0f,g/d', MPpreg_mm), 
			sprintf('MPgandl_avail,,%.0f,g/d\n', MPgandl_avail), 
			sprintf('MPlact,,%.0f,g/d', MPlact), 
			sprintf('MPlact_avail,,%.0f,g/d\n', MPlact_avail), 
			sprintf('MPg_avail,,%.0f,g/d', MPg_avail), 
			sprintf('NPg_avail,,%.0f,g/d\n', NPg_avail),
			'Predicting metabolizable protein gain',
			sprintf('MPgain,,%.2f,kg/d', MPgain), 
			sprintf('MPmilk,,%.2f,kg/d', MPmilk)
		)

	write(data_summary, out_file)

}

#=====================================#
# Prediction DMI  calculation execute #
# Date : 2014-10-23                   #
# Written by Hyesun Park              #
#=====================================#



intake_calculation = function(source_code, out_dir) {

	source(source_code)
	source(dmi_prediction_module)

	MudDMI = MudDMI_calc (source_code)
	CpW = CpW_get_to_intake(source_code)
	SBWpreg = SBWpreg_calc(source_code)

	Preg_adj = Preg_adj_calc(source_code)

	#CETI = CETI_get_to_intake(source_code)

	DMINC = DMINC_calc (source_code)

	DMIAF = DMIAF_calc(source_code)

	DMIdry = DMIdry_calc(source_code)

	Milkbeef = Milkbeef_get_to_intake(source_code)
	Milkadj = Milkadj_get_to_intake(source_code)

	FCM = FCM_calc(source_code)
	dietndf = dietndf_get_to_intake(source_code)

	NEma = NEma_get_to_intake(source_code)
	NEma_div = NEma_div_calc(source_code)	

	dual_milk = dual_milk_calc(source_code)

	PKMK = PKMK_calc()

	Lag = Lag_calc(source_code)
	P_lag = P_lag_calc (source_code)

	DMilact = DMIlact_calc(source_code)

	Beefcow_preg =  Beefcow_preg_calc(source_code)
	DMIbeefcow = DMIbeefcow_calc(source_code)

	BI = BI_calc(source_code)
	BFAT = BFAT_calc (source_code)
	ADTV = ADTV_calc (source_code)

	DMIadj = DMIadj_calc(source_code)
	DMIcalf = DMIcalf_calc (source_code)
	DMIyear = DMIyear_calc (source_code)
	DMIpred = DMIpred_calc (source_code)

	out_file = sprintf('%s/Prediction_DMI.csv', out_dir)

	data_summary = c(
		'[Predicting dry matter intake]\n', 
		sprintf('Animal type,,%s', animal_type), 
		sprintf('AGE,,%s,month', age), 
		sprintf('DMIpred,,%.2f,kg/d\n', DMIpred), 
		'Temperature and mud factors', 
		sprintf('NEma_div,,%.2f',NEma_div), 
		sprintf('BI,,%.2f', BI), 
		sprintf('BFAT,,%.2f', BFAT), 
		sprintf('ADTV,,%.2f', ADTV), 
		sprintf('MudDMI,,%.2f', MudDMI), 
		sprintf('DMINC,,%.2f', DMINC), 
		sprintf('DMIAF,,%.2f', DMIAF), 
		sprintf('DMIadj,,%.2f\n', DMIadj), 
		'Growing Calves',
		sprintf('DMIcalf,,%.2f,kg/d\n', DMIcalf),
		'Growing Yearlings',
		sprintf('Preg_adj(C1),,%.1f',Preg_adj), 
		sprintf('SBWpreg,,%.0f,kg', SBWpreg), 
		sprintf('DMIyear,,%.2f,kg/d', DMIyear), 
		sprintf('DMIdry,,%.2f,kg/d\n', DMIdry),
		'Non-pregnant beef cows', 
		sprintf('Beefcow_preg,,%.4f',Beefcow_preg), 
		sprintf('DMIbeefcow,,%.2f,kg/d\n', DMIbeefcow), 
		"Lactating dairy cattle", 
		sprintf('PKMK,,%s',PKMK),
		sprintf('P_lag(P),,%.2f', P_lag),
		sprintf('Lag,,%.2f', Lag), 
		sprintf("FCM,,%.2f,kg/d", FCM), 
		sprintf('dual_milk,,%.1f', dual_milk), 
		sprintf('DMIlact,,%.2f,kg/d', DMilact)
		)
	
	write(data_summary, out_file)


}
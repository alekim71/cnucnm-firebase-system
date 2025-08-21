#==============================================#
# Maintenancy requirements calculation execute #
# Date : 2014-10-20                            #
# Written by Hyesun Park                       #
#==============================================#

me_require_calculation = function(source_code, out_dir) {

	source(source_code)
	source(maintain_requirement_module)

	HRS = HRS_calc (source_code)
	FHP = FHP_calc(source_code)
	COMP = COMP_calc(source_code)
	PETI = PETI_calc(source_code)
	Temp_adj = Temp_adj_calc(source_code)
	ACT = ACT_calc(source_code)


	NEma = NEma_get_to_maintain(source_code) 
	ME = ME_get_to_maintain(source_code) 
	DMI = DMI_get_from_rumen(source_code) 
	NEga = NEga_get_to_maintain(source_code)
	NEla = NEla_get_to_maintain(source_code)

	NEmrb = NEmrb_calc(source_code)
	ionophore = ionophore_calc (source_code)
	ionophore_factor = ionophore_factor_calc (source_code)

	Im = Im_calc(source_code) 
	SA = SA_calc (source_code)

	NEproduction = NEproduction_calc(source_code)

	TI = TI_calc (source_code)
	
	MudME = MudME_calc(source_code)
	HideME = HideME_calc(source_code)

	EI =  EI_calc(source_code)
	HE = HE_calc(source_code)
	IN = IN_calc(source_code)
	LCT = LCT_calc (source_code)
	CETI = CETI_calc (source_code)

	MErcs = MErcs_calc(source_code)
	NEmrcs = NEmrcs_calc (source_code)
	NEmrhs = NEmrhs_calc (source_code) 
	NEmr = NEmr_calc (source_code)


	REM = REM_get_to_maintain (source_code)   
	RNB = RNB_get_to_maintain (source_code)    
	MPbal = MPbal_get_to_maintain(source_code) 

	RECYCLEDN = RECYCLEDN_get_to_maintain(source_code)
	excess_N_from_MP = excess_N_from_MP_calc(source_code) 

	UreaCost = UreaCost_calc(source_code) 
	MEmrb = MEmrb_calc (source_code)
	MEmr = MEmr_calc (source_code)

	REa = REa_calc (source_code)
	FPN = FPN_calc (source_code)
	SPA = SPA_calc(source_code)
	UPA = UPA_calc (source_code)
	MPm = MPm_calc (source_code)

	out_file = sprintf("%s/Maintenance_requirement.csv",out_dir)

	data_summary = c("[Summary of equation to predict maintanance requirment]\n", 
		sprintf('Breed_Code,,%s', breed_code), 
		sprintf('SBW,,%.0f,kg', SBW), 
		sprintf('NEmr,,%.2f,Mcal/d', NEmr), 
		sprintf('MEmr,,%.2f,Mcal/d\n', MEmr), 
		"Basal metabolism requirement", 
		sprintf('FHP(a1),,%.3f,Mcal/kg^0.75/d\n', FHP),
		'Adjustment for previous plane of nutrition (growing cattle only)' ,
		sprintf('COMP,,%.2f\n', COMP), 
		'Adjustment for previous temperature', 
		sprintf('PETI,,%.0f,Celsius', PETI),
		sprintf('Temp_adj(a2),,%.5f', Temp_adj), 
		'Adjustment for activity',
		sprintf('ACT,,%.2f,Mcal/d\n', ACT), 
		'Prediction heat increment', 
		sprintf('ionophore,,%.0f',  ionophore), 
		sprintf('ionophore_factor,,%.2f',  ionophore_factor),
		sprintf('NEmrb,,%.2f,Mcal/d',  NEmrb), 
		sprintf('Im,,%.2f,kg/d',  Im),
		sprintf('REa(RE),,%.2f,Mcal/d',  REa), 
		sprintf('NEproduction(RE+YE+LE),,%.2f,Mcal/d\n',  NEproduction), 
		'Adjustment for cold stress', 
		sprintf('SA,,%.2f,m^2',  SA),
		sprintf('HE,,%.2f,Mcal/m^2/d',  HE), 
		sprintf('HideME,,%.1f',  HideME), 
		sprintf('MudME,,%.1f',  MudME), 
		sprintf('EI,,%.2f,Celsius/Mcal/m^2/d',  EI),
		sprintf('TI,,%.2f,Celsius/Mcal/m^2/d',  TI),
		sprintf('IN,,%.2f,Celsius/Mcal/m^2/d',  IN), 
		sprintf('LCT,,%.2f,Celsius',  LCT), 
		sprintf('MErcs,,%.1f,Mcal/d',  MErcs), 
		sprintf('NEmrcs,,%.2f,Mcal/d\n',  NEmrcs),
		'Adjustment for heat stress',
		sprintf('HRS,,%.0f,hour',  HRS), 
		sprintf('CETI,,%.2f',  CETI), 
		sprintf('NEmrhs,,%.2f\n',  NEmrhs),
		'Adjustment for urea cost', 
		sprintf('RNB(BACTNBALANCE),,%.2f,g/d', RNB), 
		sprintf('RECYCLEDN,,%.2f,g/d',  RECYCLEDN), 
		sprintf('excess N from MP,,%.2f,Mcal/d',  excess_N_from_MP), 
		sprintf('UreaCost,,%.2f,Mcal/d',  UreaCost), 
		sprintf('MEmrb,,%.2f,Mcal/d\n\n',  MEmrb), 
		'[Maintenance protein requirement]', 
		sprintf('FPN,,%.1f,g/d',  FPN), 
		sprintf('SPA,,%.1f,g/d',  SPA), 
		sprintf('UPA,,%.1f,g/d',  UPA), 
		sprintf('MPm,,%.1f,g/d',  MPm) 
		)

	write(data_summary, out_file) 


}
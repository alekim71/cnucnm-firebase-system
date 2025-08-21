
#============================================#
# Lactation requirement  calculation Execute #
# Date : 2014-10-22                          #
# Written by Hyesun Park                     #
#============================================#

lactation_requirement_calculation = function(source_code, out_dir) {

	source(source_code)
	source(lactation_requirement_module)

	PKYD = PKYD_get(source_code)  
 
	PKYDadj = PKYDadj_calc(source_code)

	#  Hanwoo : 8.5  (Lactation for beef)
	PKW = PKW_calc(source_code)

	IRC = IRC_calc(source_code)

	WOL = WOL_calc(source_code)

	Milkbeef = Milkbeef_calc(source_code)

	Milkadj = Milkadj_calc (source_code)

	MFadj = MFadj_calc (source_code)

	PPadj = PPadj_calc (source_code)

	LE = LE_calc (source_code)

	LP = LP_calc(source_code)

	MElact = MElact_calc (source_code)

	MPlact = MPlact_calc (source_code)

	Coef_A = Coef_A_calc (source_code)

	Coef_B = wood_table_get(source_code, 'B')

	Coef_C = wood_table_get(source_code, 'C')

	Coef_D = wood_table_get(source_code, 'D')

	Milkpred = Milkpred_calc (source_code) 

	PMF = PMF_calc (source_code)

	PMP = PMP_calc (source_code)

	PQ = PQ_calc (source_code)

	PP_G = PP_calc(source_code)


	out_file = sprintf("%s/Lactation_requirement.csv", out_dir)

	data_summary = c(
		'[Lactation for beef requirements]', 
		sprintf('PKYD,,%.0f,kg/d', PKYD), 
		sprintf('PKYDadj,,%.0f,kg/d', PKYDadj), 
		sprintf('PKW(T),,%.1f,week(s)', PKW), 
		sprintf('IRC(A),,%.3f', IRC), 
		sprintf('WOL(A),,%.1f,week(s)', WOL), 
		sprintf('Milkbeef,,%.2f,kg/d', Milkbeef), 
		sprintf('Milkadj,,%.2f,kg/d', Milkadj), 
		sprintf('MFadj,,%.2f,%%', MFadj), 
		sprintf('PPadj,,%.2f,%%', PPadj), 
		sprintf('LE,,%.2f,Mcal/d', LE), 
		sprintf('LP,,%.2f,g/d\n\n', LP), 
		"[Lactation for dairy requirements]", 
		sprintf("MElact,,%.2f,Mcal/d", MElact),
		sprintf("MPlact,,%.2f,g/d\n", MPlact), 
		'Predicted dairy milk production, protein and fat', 
		sprintf("Coef_A,,%.0f", Coef_A), 
		sprintf('Coef_B,,%.2f', Coef_B), 
		sprintf('Coef_C,,%.2f', Coef_C), 
		sprintf('Coef_D,,%.2f', Coef_D),
		sprintf('Milkpred,,%.2f,kg/d', Milkpred),
		"George (1984)", 
		sprintf('PMF,,%.2f,%%', PMF), 
		sprintf('PMP,,%.2f,%%', PMP),
		sprintf('PQ,,%.2f,%%', PQ), 
		sprintf('PP,,%.2f,%%', PP_G)
		)


	write(data_summary, out_file)

}














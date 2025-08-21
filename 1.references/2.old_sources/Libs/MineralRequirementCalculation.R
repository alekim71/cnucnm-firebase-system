
#==========================================#
# Mineral requirement  calculation Execute #
# Date : 2014-10-22                        #
# Written by Hyesun Park                   #
#==========================================#



mineral_requirement_calculation = function(source_code, out_dir) {

	source(source_code)
	source(mineral_requirement_module)

	Fecal_Ca = Fecal_Ca_calc(source_code)
	Urinary_Ca = Urinary_Ca_calc (source_code)
	Req_Ca = Req_Ca_calc (source_code)

	ReqM_Ca = ReqM_Ca_calc (source_code)
	ReqL_Ca = ReqL_Ca_calc (source_code)
	ReqG_Ca = ReqG_Ca_calc (source_code)

	Reqtotal_Ca = Reqtotal_Ca_calc (source_code)

	Feed_Ca = Feed_Ca_calc(source_code)

	DMI = DMI_get_to_mineral(source_code) 

	Fecal_P = Fecal_P_calc (source_code) 
	Urinary_P = Urinary_P_calc (source_code)
	Req_P = Req_P_calc (source_code)

	ReqM_P = ReqM_P_calc (source_code)
	ReqL_P = ReqL_P_calc (source_code)
	ReqG_P = ReqG_P_calc (source_code) 

	Reqtotal_P = Reqtotal_P_calc (source_code)

	Feed_P = Feed_P_calc (source_code)


	out_file = sprintf('%s/Mineral_requirement.csv', out_dir)

	data_summary = c('[Mineral requirements summary]', 
		'Ca requirement', 
		sprintf("Req_Ca,,%.2f,g/d", Req_Ca), 
		sprintf(",Fecal_Ca,%.2f,g/d", Fecal_Ca), 
		sprintf(',Urinary_Ca,%.2f,g/d', Urinary_Ca), 
		sprintf('ReqM_Ca,,%.2f,g/d', ReqM_Ca), 
		sprintf('ReqL_Ca,,%.2f,g/d', ReqL_Ca), 
		sprintf('ReqG_Ca,,%.2f,g/d', ReqG_Ca), 
		sprintf("Reqtotal_Ca,,%.2f,g/d", Reqtotal_Ca), 
		sprintf('Feed_Ca,,%.2f\n', Feed_Ca), 
		'P requirement',
		sprintf('Req_P,,%.2f,g/d', Req_P), 
		sprintf(",Fecal_P,%.2f,g/d", Fecal_P), 
		sprintf(',Urinary_P,%.2f,g/d', Urinary_P), 
		sprintf('ReqM_P,,%.2f,g/d', ReqM_P),
		sprintf('ReqL_P,,%.2f,g/d', ReqL_P), 
		sprintf('ReqG_P,,%.2f,g/d', ReqG_P), 
		sprintf('Reqtotal_P,,%.2f,g/d', Reqtotal_P),
		sprintf('Feed_P,,%.2f,g/d', Feed_P)
		)

	write(data_summary, out_file)


} 


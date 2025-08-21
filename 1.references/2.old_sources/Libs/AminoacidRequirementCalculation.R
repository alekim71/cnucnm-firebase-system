#=============================================#
# Amino acid requirements calculation execute #
# Date : 2014-10-23                           #
# Written by Hyesun Park                      #
#=============================================#

aminoacid_require_calculation = function(source_code, out_dir) {


	source(source_code)
	source(aminoacid_requirement_module)

	aminoacid_components  = aminoacid_components_get()

	aminoacid_efficiency_table = aminoacid_efficiency_database(source_code)

	Preg_eff = Preg_eff_calc (source_code)

	MPAA = MPAA_calc (source_code)
	
	MPAA_total = sum(MPAA)


	RPAA = RPAA_calc (source_code)
	RPAA_total = sum(RPAA)


	LPAA = LPAA_calc(source_code) 
	LPAA_total = sum(LPAA)

	YPAA = YPAA_calc(source_code)
	YPAA_total = sum(YPAA)

	total_AA = total_AA_calc (source_code)	
	total_AA_total = sum(total_AA)

	out_file = sprintf('%s/Amino_acid_requirement.csv', out_dir)

	data_summary = c(
		'[Amino Acid Reqruirements]', 
		sprintf('MPAA,,%.0f,g/d', MPAA_total),
		sprintf('RPAA,,%.0f,g/d', RPAA_total),
		sprintf('LPAA,,%.0f,g/d', LPAA_total), 
		sprintf('YPAA,,%.0f,g/d\n', YPAA_total),
		sprintf('total_AA,,%.0f,g/d\n\n', total_AA_total),
		sprintf("Preg_eff,,%.2f\n\n", Preg_eff),
		'Amino acid requirement table',
		'MET,LYS,ARG,THR,LEU,ILE,VAL,HIS,PHE,TRP',
		paste(sprintf("%.0f", MPAA), collapse=','),
		paste(sprintf("%.0f", RPAA), collapse=','),
		paste(sprintf('%.0f', LPAA), collapse=','),
		paste(sprintf('%.0f', YPAA), collapse=','),
		paste(sprintf('%.0f', total_AA), collapse=','),
		'\n\n',
		'Amino acid components',
		'% CP,MET,LYS,ARG,THR,LEU,ILE,VAL,HIS,PHE,TRP',
		sprintf('Tissue,%s',paste(sprintf('%.3f',aminoacid_components[[1]]),collapse=',')),
		sprintf('Milk,%s\n\n',paste(sprintf('%.3f',aminoacid_components[[2]]),collapse=',')),
		'Aminoacid efficiency',
		',MET,LYS,ARG,THR,LEU,ILE,VAL,HIS,PHE,TRP',
		sprintf('EAAM,%s',paste(sprintf('%.0f%%',aminoacid_efficiency_table[[1]]),collapse=',')),
		sprintf('EAAG,%s',paste(sprintf('%.0f%%',aminoacid_efficiency_table[[2]]),collapse=',')),
		sprintf('EAAP,%s',paste(sprintf('%.0f%%',aminoacid_efficiency_table[[3]]),collapse=',')),
		sprintf('EAAL,%s',paste(sprintf('%.0f%%',aminoacid_efficiency_table[[4]]),collapse=','))
		)

	write(data_summary, out_file)

}
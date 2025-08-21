#========================#
# CNU_CNM Execute        # 
# Date : 2015-07-27      #
# Written by Hyesun Park #
#========================#

#======================#
# Program pre setting  #
#======================#

#setwd('C:/Users/hspark/Desktop')

config_file = "cncps_config.txt"

source(config_file)

if (run_program == "Analysis") {
	run_file = sprintf("%s/CNCPS_Execute.r",library_path)
	source(run_file)
} else if (run_program == "Simulation") {
	run_file = sprintf("%s/MCSimulation_Execute.R", library_path)
	source(run_file)
} else {
	stop(sprintf("'%s' is not defined. You can only choose one command between 'Analysis' and 'Simulation'", run_program))
}



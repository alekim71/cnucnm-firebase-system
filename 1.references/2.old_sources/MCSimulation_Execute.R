###################################
# Monte carlo simulation running  #
# Date : 2015-08-03               #
# Writed by Hyesun Park           #
###################################

print ("CNU CNM mcmc simulation is start.")

config_file = "cncps_config.txt"

source(config_file)

#===================================#
## Step 0. Installed pacakges check #
#===================================#

print ("Installed packages check")

ins_pkg_list = installed.packages()[,1]

pkg_list = c("FAdist", "PearsonDS", "mvtnorm", "matrixStats", "gdata")

for (pkg_n in 1:length(pkg_list)) {

    pkg_name = pkg_list[pkg_n] 

    if (!is.element(pkg_name, ins_pkg_list)) {
        print (sprintf("%s install start", pkg_name))
        install.packages(pkg_name)
        print (sprintf("%s install end", pkg_name))
    }

}

print ("Installed packages check is done.")


#############################################################
## Step 1. Get animal recode and feed library information  ##
#############################################################

make_input_source = sprintf("%s/Libs/makeInputFiles.R", library_path)

source(make_input_source)

animal_data = read.csv(animal_file, header=T, row.names=1)
feed_data  = read.csv(feed_file, header=T, row.names=1)


var.list = ls() 



#if (ncol(animal_data) > 1  & is.element("input_data", var.list)) {
if (is.element("input_data", var.list)) {

    make_input_summary(animal_file, input_data) 
}


running.start = Sys.time() 


##################################################
## Step 2. Feed ingredients randon sampling.    ##
##################################################

n = num_iter
traits_list = sort(strsplit(result_data, ",")[[1]])

traits_header = c('Num')

for (t in 1:length(traits_list)) {
    if (traits_list[t] == "ADG") {
        traits_header = c(traits_header, "MEgain,MPgain")
    } else if (traits_list[t] == "MY")
    traits_header = c(traits_header, "MEmilk,MPmilk")
}

traits_header = paste(traits_header, collapse=',')

for (i in (1:ncol(animal_data))) {

    print (sprintf("Analysis set : Dataset %s", i))

    today = sprintf("%s_%s", format(Sys.time(), format='%Y%m%d%H%M%S'), i)

    temp_dir = sprintf("%s\\tmp_cncps", today) 
    out_dir = sprintf("%s\\results", today)
    newsrc_path = sprintf("%s\\new_sources", today)    
    
    shell (sprintf("mkdir %s %s %s ", today, out_dir, newsrc_path))

    source_file =  make_input_files (today, library_path, feed_data, animal_data, i)
 
    #=========================================#
    # make animal general information database#  
    #=========================================#

    source(source_file)
    source(random_sampling_module)
    source(production_prediction_module)

    make_input_database (input_database, gsub("\\\\", "/", out_dir), source_file)
    rm("feed_library", "calc_temp")

    #=========================================#
    #  feed ingredients data random sampling  #
    #=========================================#

    feed_id.list = make_sampling_dataSet(source_file, gsub("\\\\", "/", newsrc_path), out_dir)
    feed_info_data = make_output_feed_ingred_data(gsub("\\\\", "/", newsrc_path), n)

    simulation_out_data= NULL

    print (sprintf("Iteration start. (n = %s)", n))

    for (j in 1:n) {   

        if (j %% 50==0 ) {
            print (sprintf("n_iter = %s", j))
        }


        source_code = sprintf("%s/preSetting_%s.txt", gsub("\\\\", "/", newsrc_path), j) 
        new_feed_file = sprintf("%s/feed_library_%s.csv", gsub("\\\\", "/", newsrc_path), j)
        
        shell (sprintf("copy %s %s", gsub('/', '\\\\', source_file), gsub('/', '\\\\', source_code)))
        shell (sprintf("mkdir %s\\new_sources\\tmp_%s %s", today, j, temp_dir))

        cat(sprintf("\nfeed_library = '%s'\n", new_feed_file), file= source_code, append=T)
        cat(sprintf("calc_temp = '%s/tmp_%s/'\n", gsub("\\\\", "/", newsrc_path), j), file= source_code, append=T)

        feed_ingred_matrix = feed_info_data[j,]

        row_data = c()

        for (k in 1:length(traits_list)) {
             if (traits_list[k] == "ADG"){                
                MEgain = MEgain_calc(source_code)
                MPgain = MPgain_calc(source_code)
                row_data = c(row_data, MEgain, MPgain)
            } else if (traits_list[k] == "MY") {
                MEmilk = MEmilk_calc(source_code)
                MPmilk = MPmilk_calc(source_code)
                row_data = c(row_data, MEmilk, MPmilk)
            } 
        }

        row_data = c(j, row_data, feed_ingred_matrix)
        simulation_out_data = rbind(simulation_out_data, row_data)

        shell(sprintf("rmdir /S /Q %s %s\\new_sources\\tmp_%s", temp_dir, today, j) )
    }

    #=========================#
    # Simulation results out  #
    #=========================#

    out_file = sprintf("%s/cnu_cnm_mcmcsimulation_result.csv", gsub("\\\\", '/', out_dir))

    #file_header = sprintf("Num,MEgain,MPgain,MEmilk,MPmilk,%s", paste(rep(c("NDF", "Lignin", "CP", "NDICP", "Starch", "Fat", "Ash"), length(feed_id.list)), collapse=','))
    file_header = sprintf("%s,%s", traits_header, paste(rep(c("NDF", "Lignin", "CP", "NDICP", "Starch", "Fat", "Ash"), length(feed_id.list)), collapse=','))
    feed_name_info = get_feed_names (feed_library, feed_id.list)
 
    write(sprintf("%s\n%s", feed_name_info, file_header), file=out_file)
    write.table(simulation_out_data, file=out_file, row.names=F, col.names=F, sep=",", append=T)

   }


#================#
# Step 3. Finall #     
#================#

running.end = Sys.time() 

total.run.time = difftime(running.end, running.start, units='min')[[1]]

print (sprintf ("Running time : %s min", round(total.run.time, 3)))
print ("CNU_CNM MCMC simulation is done.")
print (sprintf("Result file : %s/*/results/cnu_cnm_mcmcsimulation_result.csv", getwd()))
   




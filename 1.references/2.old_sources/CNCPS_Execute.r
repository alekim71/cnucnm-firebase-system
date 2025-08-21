#========================#
# CNCPS Running          #
# Date : 2014-10-20      #
# Written by Hyesun Park #
#========================#


#======================#
# Program pre setting  #
#======================#


config_file = "cncps_config.txt"
source(config_file)

make_input_source = sprintf("%s/Libs/makeInputFiles.R", library_path)
source(make_input_source)


print ("#===========================#")
print (sprintf("#    CNCPS analysis start.  #", getwd()))
print ("#===========================#")


####################
# Make Input files #
####################


animal_data = read.csv(animal_file, header = T, row.names = 1 )
feed_data = read.csv (feed_file, header=T, row.names = 1 )

if (!ncol (animal_data) == ncol(feed_data)) {

	print ("Number of animal and feed is not same. Please check of it.")
	quit() 

} 



##########################
# Make final output file #
##########################

total_summary_header = c("Num") 

sensitivity = ""

var.list = ls() 


if (ncol(animal_data) > 1  & is.element("input_data", var.list)) {

    make_input_summary(animal_file, input_data) 
}



if (ncol(animal_data) > 1 & is.element('result_data', var.list)) {

    traits_list = sort(strsplit(result_data, ",")[[1]])

    for (i in range(1:length(traits_list))) {

        if (traits_list[i] == "ADG") {
            total_summary_header = c(total_summary_header, "MEgain","MPgain")
        } else if (traits_list[i] == "MY") {
            total_summary_header = c(total_summary_header, "MEmilk","MPmilk")
        } 
    }

    sensitivity = "T"
}

total_summary_header = paste(total_summary_header, collapse=',')

total_output = NULL

running.start = Sys.time() 

for (i in (1:ncol(animal_data))) {


    today = format(Sys.time(), format='%Y%m%d%H%M%S')
    today = sprintf("%s_%s", today, i )

    source_code =  make_input_files (today, library_path, feed_data, animal_data, i)
    
    #=======#
    # Input #
    #=======#

    #source_code = "Input/preSetting_1.txt"
    source (source_code) 
    source(input_database)

    out_dir = sprintf("%s\\results", today)
    temp_dir = sprintf('%s\\tmp_cncps', today) 

    shell(sprintf("mkdir %s %s", out_dir, temp_dir))

    print ("#====================================#")
    print (sprintf ("# %s set CNCPS calculation start.    #", i))

    write("", sprintf("%s/Exp_No._%s.txt", today, i))

    #=================#
    # Input Data List #   
    #=================#

    breed_name = breed_table[[breed_code]][1]
    animal_type_name = animal_type_list[animal_type+1]
    sex_name = sex_code_list[sex]
    breed_type_name = breed_type_list[breed_type]
    additional_treat_name = additional_treat_code_list[additive]

    Feeding_method_name = feed_method_list[Feeding_method]
    calf_implanted_name = implant_tag_list[calf_implanted]

    HCcode_name = hair_condition_list[HCcode]

    cowshed_code_name = cowshed_list[cowshed_code]
    standing_hour = standing_hour_list[cowshed_code]
    position_change = position_change_list[cowshed_code]
    flat_distance = flat_distance_list [cowshed_code]
    slop_distance = slop_distance_list[cowshed_code]


    #====================#
    # Input Data summary #
    #====================#

    input_summary = sprintf("%s/InputData.csv", out_dir) 

    input.data = c(sprintf("Breed,%s", breed_name), sprintf("Animal Type,%s", animal_type_name), sprintf("Sex,%s", sex_name),  
                   sprintf("Breed type,%s", breed_type_name),  sprintf("Additional treat,%s", additional_treat_name), 
                   sprintf("Feeding method,%s", Feeding_method_name) , sprintf("Calf implanted,%s", calf_implanted_name), 
                   sprintf("Hair condition,%s", HCcode_name),  sprintf("Cow house,%s", cowshed_code_name), 
                   sprintf(",Standing hour,%s", standing_hour),    sprintf(",Position change,%s", position_change), 
                   sprintf(",Flat distance,%s", flat_distance),  sprintf(",Slop distance,%s", slop_distance))

    write(input.data, input_summary)


    #==========================#
    # Feed library calculation #
    #==========================#
    print ("    Feed contents calcualtion")
    source(feed_calculation)
    feed_mixed_ratio_calcualtion(source_code, feed_module, out_dir)


    #=============#
    # Rumen model #
    #=============#

    print ("    Rumen model calculation")
    source(rumen_model_execute)
    rumen_model(source_code, rumen_model_module, today)

    #==================#
    # Intestinal model #
    #==================#
    print ("    Intesintal model calculation")
    source(intestinal_model_execute)
    intestinal_model(source_code, intestinal_model_module, today)

    #=============================#
    # Maintain energy requirement #
    #=============================#
    print ("    Maintenancy requirement")
    source(maintain_requirement_execute)
    me_require_calculation (source_code, out_dir)

    #==============================#
    # Growth Pregnancy requirement #
    #==============================#
    print ("    Growth and pregnancy requirement")
    source(growth_requirement_execute)
    growth_require_calculation (source_code, out_dir)

    #===============#
    # Body reserves #
    #===============#
    print ("    Body reserves requirement")
    source(body_reserves_execute)
    body_reserves_calculation(source_code, out_dir)

    #========================#
    # Lacatation requirement #
    #========================#
    print ("    Lactation requirement")
    source(lactation_requirement_execute)
    lactation_requirement_calculation(source_code, out_dir)

    #=========================#
    # Amino acid requirement  #
    #=========================# 
    print ("    Amino acid requirement")
    source(aminoacid_requirement_execute)
    aminoacid_require_calculation(source_code, out_dir)
    
    #=====================#
    # Mineral requirement #
    #=====================#
    print ("    Mineral requirement")
    source(mineral_requirement_execute)
    mineral_requirement_calculation(source_code, out_dir)

    #=================#
    # DMI Prediction  #
    #=================#
    print ("    DMI prediction")
    source(dmi_prediction_execute)
    intake_calculation(source_code, out_dir)
    
    #========================#
    # Production prediction  #
    #========================#
    print ("    Production prediction")
    source(production_prediction_execute)
    production_prediction_calculation(source_code, out_dir)


    #========================#
    # Final Summary Reports  #  
    #========================#
    print ("    Final summary reports")
    source(write_summary)
    CNCPS_reports(source_code, out_dir)


    #===============#
    # Total reports #
    #===============#

    output_row = c(i)

    if (sensitivity == "T") {
        for (t in 1:length(traits_list)) {
            if (traits_list[t] == "ADG") {
                MEgain = MEgain_calc(source_code)
                MPgain = MPgain_calc(source_code)
                output_row = c(output_row, MEgain, MPgain)
            } else if (traits_list[t] == 'MY') {
                MEmilk = MEmilk_calc (source_code)
                MPmilk = MPmilk_calc (source_code)
                output_row = c(output_row, MEmilk, MPmilk)
            }
        }

        total_output = rbind(total_output, output_row)
    }

    ##########################
    # Remove temporary files #
    ##########################
    shell(sprintf('rmdir /S /Q %s', temp_dir))

    print (sprintf("# %s set CNCPS calculation is done. #", i))

} 

running.end = Sys.time() 

total.run.time = running.end - running.start 


total_summary = sprintf("cnu_cnm_output_summary_%s.csv", format(Sys.time(), format='%Y%m%d%H%M%S'))
if (sensitivity == 'T') {
    write(total_summary_header, file = total_summary)
    write.table(total_output, col.names=F, row.names=F, sep=',', append=T, file=total_summary)
}


print ("#===============================================================#")
print (sprintf("#  Results path : %s  #", getwd()))
print ("#===============================================================#")

print ("#===========================#")
print ('# CNCPS calcualtion is done #')
print ("#===========================#")

print (total.run.time)
#print (sprintf('Running time : %.2f min', total.run.time))
#print (sprintf("Running time : %t", running.end - running.start))


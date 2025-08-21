
#========================#
# Make input files       #
# Date : 2015-02-11      #
# Written by Hyesun Park #
#========================#


check_files = function(animal_file, feed_file) {


    animal_data = read.csv(animal_file, header = T, row.names = 1 )
    feed_data = read.csv (feed_file, header=T, row.names = 1 )

    if (! ncol (animal_data) == ncol(feed_data)) {

    	print ("Number of animal and feed is not same. Please check of it.")
    	quit() 

    } else {
        return (animal_data, feed_data)

    }
    
}


make_input_summary = function (animal_file, input_data) {

    animal_data = read.csv(animal_file, header=T, row.names=1)    
    input_data_list= sort(strsplit(input_data, ',')[[1]])

    out_file_name= sprintf("cnu_cnm_input_summary_%s.csv",format(Sys.time(), format='%Y%m%d%H%M%S'))
    print (out_file_name)
    out_file_header = c("Num")

    input_data_summary = 1:ncol(animal_data)

    
    for (i in 1:length(input_data_list)) {
        if (is.element(input_data_list[i], rownames(animal_data))) {
            out_file_header = c(out_file_header, input_data_list[i])
            input_data_summary = rbind(input_data_summary, animal_data[input_data_list[i],])
        } 
    }
   

    write(paste(out_file_header, collapse=','), file = out_file_name)
    write.table(t(input_data_summary), sep=',', row.names=F, col.names=F, file = out_file_name, append=T)
}



make_input_files = function (today, library_path, feed_data, animal_data, num_index ) {

    input_dir = sprintf("%s\\Input", today)
    tmp_dir = sprintf("%s\\Input\\tmp", today)

    shell(sprintf("mkdir %s %s", input_dir, tmp_dir))

    input_dir = sprintf("%s/Input", today )

	feed_file_input = make_FeedMixedRatio(input_dir, feed_data, num_index )
	pres_file_input = make_preSetting(input_dir, library_path, animal_data, num_index, feed_file_input, today)

	return (pres_file_input)
}


check_rownames = function(animal_recode_names) {

    raw_data_list = c ('Target_DMI', 'breed_code', 'animal_type', 'age', 'sex', 'FBW', 
    	                'breed_type', 'DIP', 'DIM', 'lact_no', 'CIm', 'CBW', 'TCAm', 'MW',
    	                'BCS', 'target_ADG', 'RHA', 'MY', 'MkCP',  'milk_price', 'RelMilkProd') 

    missed_data = NULL

    for (i in (1:length(raw_data_list))) {
    	if (!is.element(raw_data_list[i], animal_recode_names)){
    		missed_data = c(missed_data, raw_data_list[i])
    	}
    }

    if (!is.null(missed_data)) {
    	print ("Some data was missing. Please check it.")
    	print (paste(c("Missed Data : ", paste(missed_data, collapse=',')), collapse = ''))
    	quit()
    }

}


make_FeedMixedRatio = function(input_dir, feed_data, num_index) { 

    file_name = sprintf("%s/FeedMixedRatio.csv", input_dir)

    feed_id_list = rownames(feed_data)
    sub_feed_data = feed_data[,num_index]

    out_feed_data = NULL 

    for (i in (1:length(sub_feed_data)))  {

        if (length(feed_id_list) == length(sub_feed_data)) {
    	    if (!is.na(sub_feed_data[i]) && !sub_feed_data[i] == 0) {
                in_data = c(feed_id_list[i], sub_feed_data[i])
    		    out_feed_data = rbind(out_feed_data, in_data)
            }
        }
    }

    colnames (out_feed_data) = c("FeedID","DM(%)")
    rownames (out_feed_data) = out_feed_data[,1]

    write.csv(out_feed_data, row.names=F, file=file_name)

    return (file_name)
}



make_preSetting  = function(input_dir, library_path, animal_data, num_index, input_feed_file, today) { 

	file_name = sprintf("%s/preSetting.txt", input_dir, num_index)
  
    write ("# cncps pipeline preSetting #\n\n", file_name)
	write (sprintf("feed_mixed_file = '%s'",  input_feed_file ), file_name, append=T)

	data_tag = rownames(animal_data)
	sub_animal_data = animal_data[,num_index]

	check_rownames(data_tag)

	if (! length(data_tag) == length(sub_animal_data)) {
		print ("Animal recode has missing values. Please check it.")
		quit() 
	}


    calc_temp = sprintf("%s/tmp", input_dir, num_index)
    write(sprintf('calc_temp = "%s/"', calc_temp), file_name, append=T) 


	for (i in (1:length(sub_animal_data))) {

		data_key = data_tag[i]
		data_value = sub_animal_data[i]

        if (data_key == "target_ADG" & data_value < 0) {
            data_value = 0
        }
        
        write(sprintf("%s = %s", data_key, data_value), file_name,  append=T)

		if (data_key == "FBW") {
			write("SBW = FBW * 0.96", file_name, append=T)
		}

		if (data_key == "MW") {
			write("if (breed_code == 1) {MW_default = 394} else if (breed_code == 2) {MW_default = 680} else if (breed_code == 3) {MW_default = 800} else {MW_default = 0 }", file_name, append = T)		
			write("AFBW = MW * 0.96", file_name, append=T)
		}

		if (data_key == "BCS") {
			write ("if (breed_type == 3) {BCS_beef = BCS*2 -1} else {BCS_beef = BCS}", file_name, append=T) 
		}

        if (data_key == 'MkCP') {
            write("PP = MkCP * 0.93", file_name, append=T)
        }

	}


    extra_tags = c("grazing_unite_size", "daily_pasture_allowances", 'initial_pasture_mass', 'selection_pressure_for_growth_per_milk', 
                   'Feeding_frequency', 'Feeding_method','calf_implanted', 'DMI_Scaler',
                   'additive', 'WS', 'Tp', 'RHP', 'Tc' , 'RHC', 'SE', 'NC', 'HAIR', 
                   'MUD', 'HIDE', 'HCcode', 'Heat_Stress', 'HRS_code', 'cowshed_code') 
                   
    extra_values = c('NaN', 'NaN', 'NaN', 'NaN','NaN','NaN', 'NaN', 'NaN', 
                     '1', '5', '15', '40', '15', '40', '0', '1', '0.3', 
                     '0', '1', '1', '1', '0', '2')


    for (i in (1:length(extra_tags))) {
        if (!is.element(extra_tags[i], data_tag)) {
            write(sprintf('%s = %s', extra_tags[i], extra_values[i]), file_name, append=T)
        }
    }
                 

    write("\r\n\r\n# cncps library and out file names\r\n", file_name, append=T)

    # Database files 
    write(sprintf("input_database = '%s/Database/InputDatabase.txt'", library_path), file_name, append=T )
    write(sprintf("feed_library = '%s/Database/KoreanFeedLibrary_convert.csv'", library_path), file_name, append=T)

    # Getting feed information 
    write(sprintf("feed_calculation = '%s/Libs/FeedMixedRatioCalculation.R'", library_path), file_name, append=T )
    write(sprintf("feed_module = '%s/Libs/FeedMixedRatioCalculationModule.R'", library_path), file_name, append=T ) 


    #Rumen & intestinal source 
    write(sprintf("rumen_model_execute = '%s/Libs/RumenModelCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("rumen_model_module = '%s/Libs/RumenModelCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("intestinal_model_execute = '%s/Libs/IntestinalModelCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("intestinal_model_module = '%s/Libs/IntestinalModelCalculationModule.R'", library_path), file_name, append=T ) 


    # Requirement calculation module 
    write(sprintf("maintain_requirement_execute = '%s/Libs/MaintainEnergyCalculation.R'", library_path), file_name, append=T )
    write(sprintf("maintain_requirement_module = '%s/Libs/MaintainEnergyCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("growth_requirement_execute = '%s/Libs/GrowthRequirementCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("growth_requirement_module = '%s/Libs/GrowthRequirementCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("body_reserves_execute = '%s/Libs/BodyReservesCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("body_reserves_module = '%s/Libs/BodyReservesCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("lactation_requirement_execute = '%s/Libs/LactationRequirementCalculation.R'", library_path), file_name, append=T )
    write(sprintf("lactation_requirement_module = '%s/Libs/LactationRequirementCalculationModule.R'", library_path), file_name, append=T )

    write(sprintf("aminoacid_requirement_execute = '%s/Libs/AminoacidRequirementCalculation.R'", library_path), file_name, append=T )
    write(sprintf("aminoacid_requirement_module = '%s/Libs/AminoacidRequirementCalculationModule.R'", library_path), file_name, append=T )

    write(sprintf("mineral_requirement_execute = '%s/Libs/MineralRequirementCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("mineral_requirement_module = '%s/Libs/MineralRequirementCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("dmi_prediction_execute = '%s/Libs/IntakePredictionCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("dmi_prediction_module = '%s/Libs/IntakePredictionCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("production_prediction_execute = '%s/Libs/ProductPredictCalculation.R'", library_path), file_name, append=T ) 
    write(sprintf("production_prediction_module = '%s/Libs/ProductPredictCalculationModule.R'", library_path), file_name, append=T ) 

    write(sprintf("random_sampling_module = '%s/Libs/dataSampling.R'", library_path), file_name, append =T)

    write(sprintf("write_summary = '%s/Libs/CNCPSsummary.R'", library_path), file_name, append=T ) 

    write("# temporary files ", file_name, append=T) 
    write(sprintf("tmp_feed_database = '%s/tmp_cncps/feed_database.csv'", today), file_name, append=T )
    write(sprintf("tmp_dm_percent = '%s/tmp_cncps/feed_dm_perc.csv'",today), file_name, append=T )
    write(sprintf("tmp_intake_p_dm = '%s/tmp_cncps/feed_intake_p_dm_perc.csv'",today), file_name, append=T )
    write(sprintf("tmp_intake_p_day = '%s/tmp_cncps/feed_intake_p_dm_day.csv'",today), file_name, append=T )
    write(sprintf("tmp_dm_intake = '%s/tmp_cncps/dm_intake.csv'",today), file_name, append=T )
    write(sprintf("tmp_rumen_passage_rate = '%s/tmp_cncps/rumen_passage_rate.csv'",today), file_name, append=T )
    write(sprintf("tmp_adj_rumen_passage_rate_by_ph =  '%s/tmp_cncps/adj_rumen_passage_rate_by_ph.csv'",today), file_name, append=T )
    write(sprintf("tmp_rumen_passage_rate_by_ph = '%s/tmp_cncps/rumen_passage_rate_by_ph.csv'",today), file_name, append=T )
    write(sprintf("tmp_rumen_degradation = '%s/tmp_cncps/rumen_degradation.csv'",today), file_name, append=T )
    write(sprintf("tmp_microbial_fermentation = '%s/tmp_cncps/microbial_fermentation.csv'",today), file_name, append=T )
    write(sprintf("tmp_ruminal_nitrogen = '%s/tmp_cncps/ruminal_nitrogen.csv'",today), file_name, append=T )
    write(sprintf("tmp_adj_ruminal_feed_degradation = '%s/tmp_cncps/adj_ruminal_feed_degradation.csv'",today), file_name, append=T )
    write(sprintf("tmp_ruminal_feed_escaping = '%s/tmp_cncps/ruminal_feed_escaping.csv'",today), file_name, append=T )
    write(sprintf("tmp_microbial_composition = '%s/tmp_cncps/microbial_composition.csv'",today), file_name, append=T )
    write(sprintf("tmp_rumen_degradable_feed = '%s/tmp_cncps/rumen_degradable_feed.csv'",today), file_name, append=T )
    write(sprintf("tmp_intestinal_digestibilites = '%s/tmp_cncps/intestinal_degestibilities.csv'",today), file_name, append=T )
    write(sprintf("tmp_total_intestinal_supply = '%s/tmp_cncps/total_intestinal_supply.csv'",today), file_name, append=T )
    write(sprintf("tmp_prediction_intestinal_digestion = '%s/tmp_cncps/prediction_intestinal_digest.csv'",today), file_name, append=T )
    write(sprintf("tmp_fecal_output = '%s/tmp_cncps/fecal_output.csv'",today), file_name, append=T )
    write(sprintf("tmp_total_digest_nutrients = '%s/tmp_cncps/total_digest_nutrients.csv'",today), file_name, append=T )
    write(sprintf("tmp_aminoacid_composition = '%s/tmp_cncps/aminoacid_composition.csv'",today), file_name, append=T )
    write(sprintf("tmp_bacterial_amino_acid = '%s/tmp_cncps/bacterial_amino_acid_supply_to_the_duodenum.csv'",today), file_name, append=T )
    write(sprintf("tmp_bacterial_amino_acid_digestion = '%s/tmp_cncps/bacterial_amino_acid_digestion.csv'",today), file_name, append=T )
    write(sprintf("tmp_feed_amino_acid_supply = '%s/tmp_cncps/feed_amino_acid_supply.csv'",today), file_name, append=T )
    write(sprintf("tmp_feed_amino_acid_digestion = '%s/tmp_cncps/feed_amino_acid_digestion.csv'",today), file_name, append=T )
    write(sprintf("tmp_duodenal_supply = '%s/tmp_cncps/total_duodenal_amino_acid_supply.csv'",today), file_name, append=T )
    write(sprintf("tmp_total_metabolizable_supply = '%s/tmp_cncps/total_metabolizable_supply.csv'",today), file_name, append=T )     

	return (file_name) 

}






make_input_database = function(input_database, out_dir, source_file) {

    #===================================#
    # Getting animal general information#
    #===================================#

    source(input_database)

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
    
    #==========================================================#
    # Adding animal general information to preSetting.txt file #
    #==========================================================#

    write(sprintf("breed_name = '%s'", breed_name), source_file, append=T) 
    write(sprintf("animal_type_name = '%s'", animal_type_name), source_file, append=T) 
    write(sprintf("sex_name = '%s'", sex_name), source_file, append=T) 
    write(sprintf("breed_type_name = '%s'", breed_type_name), source_file, append=T) 
    write(sprintf("additional_treat_name = '%s'", additional_treat_name), source_file, append=T) 
    write(sprintf("Feeding_method_name = '%s'", Feeding_method_name), source_file, append=T) 
    write(sprintf("calf_implanted_name = '%s'", calf_implanted_name), source_file, append=T) 
    write(sprintf("HCcode_name = '%s'", HCcode_name), source_file, append=T) 
    write(sprintf("cowshed_code_name = '%s'", cowshed_code_name), source_file, append=T) 
    write(sprintf("standing_hour = %s", standing_hour), source_file, append=T) 
    write(sprintf("position_change = %s", position_change), source_file, append=T) 
    write(sprintf("flat_distance = %s", flat_distance), source_file, append=T) 
    write(sprintf("slop_distance = %s", slop_distance), source_file, append=T) 

    #====================================#
    # Animal general information summary #
    #====================================#

    input_summary = sprintf("%s/InputData.csv", out_dir) 

    input.data = c(sprintf("Breed,%s", breed_name), sprintf("Animal Type,%s", animal_type_name), sprintf("Sex,%s", sex_name),  
                   sprintf("Breed type,%s", breed_type_name),  sprintf("Additional treat,%s", additional_treat_name), 
                   sprintf("Feeding method,%s", Feeding_method_name) , sprintf("Calf implanted,%s", calf_implanted_name), 
                   sprintf("Hair condition,%s", HCcode_name),  sprintf("Cow house,%s", cowshed_code_name), 
                   sprintf(",Standing hour,%s", standing_hour),    sprintf(",Position change,%s", position_change), 
                   sprintf(",Flat distance,%s", flat_distance),  sprintf(",Slop distance,%s", slop_distance))

    write(input.data, input_summary)

}
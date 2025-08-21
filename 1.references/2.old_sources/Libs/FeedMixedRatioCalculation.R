
#======================================#
# Feed mixed ratio calculation execute #
# Date : 2014-10-27                    #
# Written by Hyesun Park               #
#======================================#


feed_mixed_ratio_calcualtion = function(source_code, feed_module, out_dir) {

	source(source_code)
	source(feed_module)

	# feed_mixed_file, feed_library, Target_DMI  Target_AF, Predict_DMI

	dmi_perc_result = dm_perc_calc(source_code)

	target_AFI = target_AFI_calc (source_code)

	DMIpred = DMIpred_calc (source_code)

	data_summary = c( sprintf('\n,target_AFI,%.3f,kg', target_AFI), 
		sprintf(',target_DMI,%.3f,kg', Target_DMI), 
		sprintf(',predict DMI,%.3f,kg', DMIpred))

	out_file = sprintf('%s/feed_information.csv', out_dir)

	write(data_summary, file=out_file)

	write('\n\nFeed mixed ratio table\n', file=out_file, append=T)

	file_header = sprintf('Num,Feed_ID,Feed_Name,DM,DM(%%)')
    write(file_header, file=out_file, append=T)

	feed_id_list = rownames(dmi_perc_result)

	for (i in (1:length(feed_id_list))) {
		f_id = feed_id_list[i]
		row_data = dmi_perc_result[f_id,]

	    if (i >= 1 & i < nrow(dmi_perc_result)) {
			out_data = sprintf('%d,%s,%s,%.3f,%.1f,%%', i, f_id, as.character(row_data[1]), as.numeric(row_data[2]), as.numeric(row_data[3]))
		} else {
			out_data = sprintf(',%s,%s,%.3f,%.1f,%%', f_id, as.character(row_data[1]), as.numeric(row_data[2]), as.numeric(row_data[3]))
		}

		write(out_data, file=out_file, append=T)
	}

}
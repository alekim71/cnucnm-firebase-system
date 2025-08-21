#=====================================#
# Feed mixed ratio calculation module #
# Date : 2014-10-27                   #
# Written by Hyesun Park              #
#=====================================#


dm__perc___calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_dm_percent)) {

		feed_database = read.csv(file=feed_library, header=T, row.names=1)

		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)
		feed_id_list = rownames(feed_data)

		dmi.total = 0
		dmi.perc.total = 0 

		dm_perc =  NULL 

		for (i in (1:nrow(feed_data))) {
			feed.dm = feed_data[i,]
			feed.id = feed_id_list[i]
			feed.name = as.character(feed_database[feed.id,'Feed_name'])

			feed.dm.perc = (feed.dm/Target_DMI) * 100
		
			dmi.total = dmi.total + as.numeric(feed.dm)
			dmi.perc.total = dmi.perc.total + as.numeric(feed.dm.perc)

			dm_perc = rbind(dm_perc, c(feed.id, feed.name, feed.dm,feed.dm.perc))	
		}

		dm_perc = rbind(dm_perc, c('', 'Total', dmi.total, dmi.perc.total))
		colnames(dm_perc) = c('FeedID', 'FeedName','DM(kg/d)', 'DMperc')	
		rownames(dm_perc) = c(feed_id_list, 'total')
		dm_perc = dm_perc[,2:ncol(dm_perc)]

		write.csv(dm_perc, file=tmp_dm_percent, quote=F, row.names=T)

	} else {
		dm_perc = read.csv(file=tmp_dm_percent, header=T, row.names=1)
	}
	
	return (dm_perc)
}


dm_perc_calc = function(source_code) {

	source(source_code)

	if (!file.exists(tmp_dm_percent)) {

		feed_database = read.csv(file=feed_library, header=T, row.names=1)

		feed_data = read.csv(file=feed_mixed_file, header=T, row.names=1)
		feed_id_list = rownames(feed_data)

		dmi.total = 0
		dmi.perc.total = 0 

		dm_perc =  NULL 

		for (i in (1:nrow(feed_data))) {
			feed.dm.perc = feed_data[i,]
			feed.id = feed_id_list[i]
			feed.name = as.character(feed_database[feed.id,'Feed_name'])

			feed.dm = feed.dm.perc/100 * Target_DMI

		
			dmi.total = dmi.total + as.numeric(feed.dm)
			dmi.perc.total = dmi.perc.total + as.numeric(feed.dm.perc)

			dm_perc = rbind(dm_perc, c(feed.id, feed.name, feed.dm,feed.dm.perc))	
		}

		dm_perc = rbind(dm_perc, c('', 'Total', dmi.total, dmi.perc.total))
		colnames(dm_perc) = c('FeedID', 'FeedName','DM(kg/d)', 'DMperc')	
		rownames(dm_perc) = c(feed_id_list, 'total')
		dm_perc = dm_perc[,2:ncol(dm_perc)]

        #if (round(dmi.perc.total,4) != as.numeric(100) )  {
        if (round(dmi.perc.total,4) < 98 &&  round(dmi.perc.total, 4) > 101 )  {        	
        	#print ("TOTAL DM PERCENT IS NOT 100. PLEASE CHECK OF THIS")
        	print ("TOTAL DM PERCENT IS NOT in range 98 to 101. PLEASE CHECK OF THIS")
        	quit()
        }


		write.csv(dm_perc, file=tmp_dm_percent, quote=F, row.names=T)

	} else {
		dm_perc = read.csv(file=tmp_dm_percent, header=T, row.names=1)
	}


	return (dm_perc)
}



target_AFI_calc = function(source_code) {

	#target_AFI= 8.546

	source(source_code)	
	source(rumen_model_module)

	dietdry = dietdry_calc (source_code)
	target_AFI = Target_DMI/(dietdry/100)

	return  (target_AFI)
}


DMIpred_calc = function(source_code) {

	#DMIpred = 7.599 
	source(source_code)
	source(dmi_prediction_module)

	DMIpred = DMIpred_calc(source_code)

	return (DMIpred)
}


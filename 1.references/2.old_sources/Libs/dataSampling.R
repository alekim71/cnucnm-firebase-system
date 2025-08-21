
##########################################
# Monte carlo simulation running modules #
# Date : 2015-08-03                      #
# Writed by Hyesun Park                  #
##########################################


make_sampling_dataSet  = function (source_code, newsrc_path, out_dir) {

	library(matrixStats)

	source(source_code)

    feed_data.subSet = read.csv(feed_mixed_file, header=T,  row.names=1)
    feed_id.list = rownames(feed_data.subSet)

    for (i in 1:length(feed_id.list)) {
        feed.ingred_file = sprintf("%s/%s_ingred.csv", newsrc_path, feed_id.list[i])
        feed_cor_file = sprintf("%s/%s_cor.csv", cor_dir, feed_id.list[i])

    	if (file.exists(sprintf(feed_cor_file))) {
            feed.ingred_sampling_data = data_sampling(feed_cor_file, n)
    	} else {
            print (sprintf("Can't found file %s_cor.csv file.Feed ID %s is not applied random sampling.", feed_id.list[i], feed_id.list[i]))
            feed.ingred_sampling_data = NULL
        }

        if (!is.null(feed.ingred_sampling_data)){        	
            write.csv(feed.ingred_sampling_data, file=feed.ingred_file, col.names=T, row.names=T)	

            summary_file = sprintf("%s/%s_summary.csv", out_dir, feed_id.list[i])

            summary_data = NULL

            summary_data = rbind(summary_data, colMins(feed.ingred_sampling_data))
            summary_data = rbind(summary_data, colMaxs(feed.ingred_sampling_data))
            summary_data = rbind(summary_data, colMeans(feed.ingred_sampling_data))
            summary_data = rbind(summary_data, colMedians(feed.ingred_sampling_data))
            summary_data = rbind(summary_data, colSds(feed.ingred_sampling_data))

            rownames(summary_data) = c("Min", "Max", "Mean", "Median", "Stdev")

            cor_data = cor(feed.ingred_sampling_data)

            write(sprintf("!FeedID:%s feed ingredients data summary", feed_id.list[i]), file=summary_file)
            write(sprintf("\n!General summary", feed_id.list[i]), file=summary_file, append=T)
            write.table(round(summary_data, 5), file=summary_file, row.names=T, col.names=NA, sep=",", append=T)
            write(sprintf("\n!sampling data matrix", feed_id.list[i]), file=summary_file, append=T)
            write.table(round(cor_data, 5), file = summary_file, row.names=T, col.names=NA, sep=",", append=T)
        }
        
        make_feed_library(feed_id.list[i], feed.ingred_sampling_data, feed_library, n, newsrc_path)
    }

    return (feed_id.list)
}



data_sampling = function (feed_cor_file, n, cutoff.prop = .05) {

	library (mvtnorm)

    sample_cor_data = read.csv(feed_cor_file, header=T, row.names = 1) 
    cor_matrix = as.matrix(sample_cor_data[,1:(ncol(sample_cor_data)-2)])
    mean_data = rep(0, ncol(cor_matrix))
    dist_type = sample_cor_data$DistType
    param_data = gsub("^\'", "", sample_cor_data$Param)

	if (!isSymmetric(cor_matrix)) {
		if (!ncol(cor_matrix) == nrow(cor_matrix)) {
			print ("Number of column and number of rows is not same. Please check it.")
			break 
		}

		trans.matrix = t(cor_matrix) 
		trans.matrix[upper.tri(trans.matrix)] = cor_matrix[upper.tri(cor_matrix)]

		is.na(trans.matrix) = 0

		if (!isSymmetric(trans.matrix)) {
			print ("Correlation matrix is not symmetric. please check it.")
			break 
		}

		n_iter = n * 5 

		rawData.sampling = rmvnorm(mean=mean_data, sigma = trans.matrix, n = n_iter)
		colnames(rawData.sampling) = colnames(trans.matrix)		

		rawData.uniform = pnorm(rawData.sampling, mean = mean_data)

		out_data = NULL 

		for (i in 1:ncol(rawData.uniform)) {
			rawData = rawData.uniform[,i]
			dist_param = as.numeric(strsplit(as.character(param_data[i]), ';')[[1]])
			
			#####################################
			# Distribution description          #
			#-----------------------------------#
			# alpha : shape, beta : scale,      #
			# gamma : location                  #
			# normal (location(mean), scale(sd))#
			# beta-general (alpha1, alpha2)     #
			# exponential (beta)                #
			# logistic (alpha, beta)            #
			# loglogistic (gamma, alpha, beta)  #
			# lognormal (mean, sd)              # 
			# pearsonV (alpha, beta, gamma=0)     #
			# weibull (alpha, beta)             #
			#####################################

			if (dist_type [i] == "Normal") {
				rawData.convert = qnorm(rawData, mean = dist_param[1], sd=dist_param[2]) 
			} else if (dist_type [i] == "Weibull") {
				rawData.convert = qweibull(rawData,shape=dist_param[1], scale=dist_param[2])
			} else if (dist_type[i] == "PearsonV") {
				library("PearsonDS")
				rawData.convert = qpearsonV(rawData, shape = dist_param[1], scale = 1/dist_param[2], location=0) 				
			} else if (dist_type [i] == "Loglogistic") {
				library("FAdist")				
				rawData.convert = qllog3(rawData, thres = dist_param[1], scale=dist_param[2], shape=dist_param[3])
			} else if (dist_type[i] == "lognormal") {				
				rawData.convert = qlnorm(rawData, meanlog = log(dist_param[1]), sdlog = log(dist_param[2]))
			} else if (dist_type [i] == "Betageneral") {
				rawData.convert = qbeta(rawData, shape1=dist_param[1], shape2= dist_param[2])
			} else if (dist_type [i] == "Logistic") {
				rawData.convert = qlogis(rawData, location = dist_param[1], scale = dist_param[2])
			} else if (dist_type[i] == "Exponential") {
				rawData.convert = qexp(rawData, rate = dist_param[1])
			} else {
				print (sprintf("%s is not defined distribution.", dist_type[i]))
				print ("Available distribution types : Normal, PearsonV, Loglogistic, Logistic, lognormal, Beta general, Exponential")
				break 
			}
			out_data = cbind(out_data, rawData.convert)
		}
		colnames(out_data) = colnames(rawData.uniform) 
	}

	out_data.filtered = remove_threshold_data(out_data, dist_type, n, param_data, mean_data, cutoff.prop)

	return (out_data.filtered)
}


remove_threshold_data = function(data_matrix, dist_type, n, parameters, mean_data, cutoff.prop) {

	filtered.matrix = NULL 

	for (i in 1:nrow(data_matrix)) {
		row_data= NULL 
		data_count = 0 
		matrix.row_data = data_matrix[i,]

		for (j in 1:ncol(data_matrix)) {
			dist_data = dist_type[j]
			dist_param = as.numeric(strsplit(as.character(parameters[j]), ";")[[1]])			
			ll.ratio = cutoff.prop
			ul.ratio = 1 - cutoff.prop

			if (dist_data == "Normal") {
				value.ll = qnorm(ll.ratio, mean = dist_param[1], sd = dist_param[2]) 
				value.ul = qnorm(ul.ratio, mean = dist_param[1], sd = dist_param[2])
			} else if (dist_data == "Weibull") {
				value.ll = qweibull(ll.ratio, shape=dist_param[1], scale = dist_param[2])
				value.ul = qweibull(ul.ratio, shape=dist_param[1], scale = dist_param[2])
			} else if (dist_data == "PearsonV") {
				library("PearsonDS")				
				value.ll = qpearsonV(ll.ratio, shape = dist_param[1], scale = 1/dist_param[2], location = 0)
				value.ul = qpearsonV(ul.ratio, shape = dist_param[1], scale = 1/dist_param[2], location = 0)
			} else if (dist_data == "Loglogistic") {
				library("FAdist")
				value.ll = qllog3(ll.ratio, thres = dist_param[1], scale = dist_param[2], shape = dist_param[3])
				value.ul = qllog3(ul.ratio, thres = dist_param[1], scale = dist_param[2], shape = dist_param[3])
			} else if (dist_data == "lognormal") {
				value.ll = qlnorm(ll.ratio, meanlog = log(dist_param[1]), sdlog = log(dist_param[2]))
				value.ul = qlnorm(ul.ratio, mean=dist_param[1], sd = dist_param[2])
			} else if (dist_data == "Betageneral") {
				value.ll = qbeta(ll.ratio, shape1=dist_param[1], shape2= dist_param[2])
				value.ul = qbeta(ul.ratio, shape1=dist_param[1], shape2= dist_param[2])
			} else if (dist_data == "Logistic") {
				value.ll = qlogis(ll.ratio, location = dist_param[1], scale = dist_param[2])
				value.ul = qlogis(ul.ratio, location = dist_param[1], scale = dist_param[2])

			} else if (dist_data == "Exponential") {
				value.ll = qexp(ll.ratio, rate = dist_param[1])
				value.ul = qexp(ul.ratio, rate = dist_param[1])
			} else {
				print (sprintf("%s is not defined distribution.", dist_type[i]))
				print ("Available distribution types : Normal, PearsonV, Loglogistic, Logistic, lognormal, Beta general, Exponential")
				break 
			}


			if (matrix.row_data[j] >= 0 & value.ll <= matrix.row_data[j] & matrix.row_data[j] <= value.ul) {
				if (is.element(dist_data, c("Logistic", "Loglogistic"))) {
					matrix.row_data[j] = log(matrix.row_data[j], 2)
				}
				data_count = data_count + 1 
				row_data = c(row_data, matrix.row_data[j])
			} 
		}

		if (ncol(data_matrix) == data_count) {
			filtered.matrix = rbind(filtered.matrix, row_data)
		}
	}

	if (nrow(filtered.matrix) < n) {
		final_matrix = filtered.matrix[sample(nrow(filtered.matrix), size = n, replace=T),]
	} else {
		final_matrix = filtered.matrix[sample(nrow(filtered.matrix), size = n),]		
	}

	final_matrix = final_matrix / 10 # proportion convert to percentage 

	colnames(final_matrix) = colnames(data_matrix)

	return (final_matrix)
}


make_feed_library = function (feed_id, out_data.filtered, feed_library, n, file_path) {

	feed_db = read.csv(feed_library, header=T, row.names=1) 

	feed_data = feed_db[feed_id,]

	if (!is.null(out_data.filtered)) {
		if (nrow(out_data.filtered) < n) {
			print (sprintf("sampled data is less than %s", n))
			break 
		}
	}

	feed_ingred_list = colnames(out_data.filtered)

	for (i in 1:n) {

		sampling_data = out_data.filtered[i,]

		feed_library_set_name = sprintf("%s/feed_library_%s.csv", file_path, i)

		if (!is.null(out_data.filtered)) {

			for (j in 1:ncol(out_data.filtered)) {
				if (feed_ingred_list[j] == "Concentrate") {
					feed_data[,4] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Forage") {
					feed_data[,5] = sampling_data[j]
				} else if (feed_ingred_list[j] == "DM") {
					feed_data[,6] = sampling_data[j]
				} else if (feed_ingred_list[j] == "NDF") {
					feed_data[,7] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Lignin") {
					feed_data[,8] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CP") {
					feed_data[,9] = sampling_data[j]
				} else if (feed_ingred_list[j] == "SOLP") {
					feed_data[,10] = sampling_data[j]
				} else if (feed_ingred_list[j] == "NPN") {
					feed_data[,11] = sampling_data[j]
				} else if (feed_ingred_list[j] == "NDICP") {
					feed_data[,12] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ADICP") {
					feed_data[,13] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Starch") {
					feed_data[,14] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Fat") {
					feed_data[,15] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Ash") {
					feed_data[,16] = sampling_data[j]
			 	} else if (feed_ingred_list[j] == "peNDF") {
					feed_data[,17] = sampling_data[j]					
				} else if (feed_ingred_list[j] == "CHOA") {
					feed_data[,18] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CHOB1") {
					feed_data[,19] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CHOB2") {
					feed_data[,20] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CHOC") {
					feed_data[,21] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ProteinA") {
					feed_data[,22] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ProteinB1") {
					feed_data[,23] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ProteinB2") {
					feed_data[,24] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ProteinB3") {
					feed_data[,25] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ProteinC") {
					feed_data[,26] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDCHOA") {
					feed_data[,27] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDCHOB1") {
					feed_data[,28] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDCHOB2") {
					feed_data[,29] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDCHOC") {
					feed_data[,30] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDProteinA") {
					feed_data[,31] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDProteinB1") {
					feed_data[,32] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDProteinB2") {
					feed_data[,33] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDProteinB3") {
					feed_data[,34] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDProteinC") {
					feed_data[,35] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDFat") {
					feed_data[,36] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IDAsh") {
					feed_data[,37] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Methionine") {
					feed_data[,38] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Lysine") {
					feed_data[,39] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Arginine") {
					feed_data[,40] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Threonine") {
					feed_data[,41] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Leucine") {
					feed_data[,42] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Isoleucine") {
					feed_data[,43] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Valine") {
					feed_data[,44] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Histidine") {
					feed_data[,45] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Phenylalanine") {
					feed_data[,46] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Tryptophan") {
					feed_data[,47] = sampling_data[j]
				} else if (feed_ingred_list[j] == "TDN") {
					feed_data[,48] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ME") {
					feed_data[,49] = sampling_data[j]
				} else if (feed_ingred_list[j] == "NEm") {
					feed_data[,50] = sampling_data[j]
				} else if (feed_ingred_list[j] == "NEg") {
					feed_data[,51] = sampling_data[j]
				} else if (feed_ingred_list[j] == "RUP3X") {
					feed_data[,52] = sampling_data[j]
				} else if (feed_ingred_list[j] == "RUP1X") {
					feed_data[,53] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Ca") {
					feed_data[,54] = sampling_data[j]
				} else if (feed_ingred_list[j] == "P") {
					feed_data[,55] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Mg") {
					feed_data[,56] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Cl") {
					feed_data[,57] = sampling_data[j]
				} else if (feed_ingred_list[j] == "K") {
					feed_data[,58] = sampling_data[j]
				} else if (feed_ingred_list[j] == "0") {
					feed_data[,59] = sampling_data[j]
				} else if (feed_ingred_list[j] == "S") {
					feed_data[,60] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Co") {
					feed_data[,61] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Cu") {
					feed_data[,62] = sampling_data[j]
				} else if (feed_ingred_list[j] == "I") {
					feed_data[,63] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Fe") {
					feed_data[,64] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Mn") {
					feed_data[,65] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Se") {
					feed_data[,66] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Zn") {
					feed_data[,67] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitA") {
					feed_data[,68] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitD") {
					feed_data[,69] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitE") {
					feed_data[,70] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CaBio") {
					feed_data[,71] = sampling_data[j]
				} else if (feed_ingred_list[j] == "PBio") {
					feed_data[,72] = sampling_data[j]
				} else if (feed_ingred_list[j] == "MgBio") {
					feed_data[,73] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ClBio") {
					feed_data[,74] = sampling_data[j]
				} else if (feed_ingred_list[j] == "KBio") {
					feed_data[,75] = sampling_data[j]
				} else if (feed_ingred_list[j] == "0Bio") {
					feed_data[,76] = sampling_data[j]
				} else if (feed_ingred_list[j] == "SBio") {
					feed_data[,77] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CoBio") {
					feed_data[,78] = sampling_data[j]
				} else if (feed_ingred_list[j] == "CuBio") {
					feed_data[,79] = sampling_data[j]
				} else if (feed_ingred_list[j] == "IBio") {
					feed_data[,80] = sampling_data[j]
				} else if (feed_ingred_list[j] == "FeBio") {
					feed_data[,81] = sampling_data[j]
				} else if (feed_ingred_list[j] == "MnBio") {
					feed_data[,82] = sampling_data[j]
				} else if (feed_ingred_list[j] == "SeBio") {
					feed_data[,83] = sampling_data[j]
				} else if (feed_ingred_list[j] == "ZnBio") {
					feed_data[,84] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitABio") {
					feed_data[,85] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitDBio") {
					feed_data[,86] = sampling_data[j]
				} else if (feed_ingred_list[j] == "VitEBio") {
					feed_data[,87] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Starch2") {
					feed_data[,88] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Sugar2") {
					feed_data[,89] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Lactic") {
					feed_data[,90] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Acetic") {
					feed_data[,91] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Proprionic") {
					feed_data[,92] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Butyric") {
					feed_data[,93] = sampling_data[j]
				} else if (feed_ingred_list[j] == "Isobutyric") {
					feed_data[,94] = sampling_data[j]
				} else if (feed_ingred_list[j] == "pH") {
					feed_data[,95] = sampling_data[j]
				} else if (feed_ingred_list[j] == "AmmoniaCPE") {
					feed_data[,96] = sampling_data[j]
				} else {
					print (sprintf("%s is not defined feed ingredient. Please ask admin.", feed_ingred_list[j]))
					break 
				} 
			}
		}

		file_header = c("Feed_ID","Feed_name","Catergory","Price(Won/kg)","Concentrate(%)","Forage(%)","DM(%AF)",
				"NDF (%DM)","Lignin (%NDF)","CP (%DM)","Sol-P (%CP)","NPN (%Sol-P)","NDICP (%CP)","ADICP (%CP)","Starch (%NSC)",
				"Crude fat (%DM)","Crude ash (%DM)","peNDF (%NDF)","CHO-A (%/hr)","CHO-B1 (%/hr)","CHO-B2 (%/hr)","CHO-C (%/hr)",
				"Protein-A (%/hr)","Protein-B1 (%/hr)","Protein-B2 (%/hr)","Protein-B3 (%/hr)","Protein-C (%/hr)","ID-CHO-A (%)",
				"ID-CHO-B1 (%)","ID-CHO-B2 (%)","ID-CHO-C (%)","ID-Protein-A (%)","ID-Protein-B1 (%)","ID-Protein-B2 (%)",
				"ID-Protein-B3 (%)","ID-Protein-C (%)","ID-Fat (%)","ID-Ash (%)","Methionine (%UIP)","Lysine (%UIP)",
				"Arginine (%UIP)","Threonine (%UIP)","Leucine (%UIP)","Isoleucine (%UIP)","Valine (%UIP)","Histidine (%UIP)",
				"Phenylalanine (%UIP)","Tryptophan (%UIP)","TDN (%DM)","ME (Mcal/kg)","NEm (Mcal/kg)","NEg (Mcal/kg)","RUP-3X (%CP)",
				"RUP-1X (%CP)","Ca (%)","P (%)","Mg (%)","Cl (%)","K (%)","0 (%)","S (%)","Co (mg/kg)","Cu (mg/kg)","I (mg/kg)","Fe (mg/kg)",
				"Mn (mg/kg)","Se (mg/kg)","Zn (mg/kg)","Vit A (1000 IU/kg)","Vit D (1000 IU/kg)","Vit E (IU/kg)","Ca-Bio","P-Bio","Mg-Bio","Cl-Bio",
				"K-Bio","0-Bio","S-Bio","Co-Bio","Cu-Bio","I-Bio","Fe-Bio","Mn-Bio","Se-Bio","Zn-Bio","VitA-Bio","VitD-Bio","VitE-Bio","Starch","Sugar",
				"Lactic","Acetic","Proprionic","Butyric","Isobutyric","pH","AmmoniaCPE")

		feed_data = cbind(feed_id, feed_data)
		colnames(feed_data) = file_header

		if (!file.exists(feed_library_set_name)) {			
			write.table(feed_data, file = feed_library_set_name, sep=',', row.names=F, col.names=T)
		}   else {
			write.table(feed_data, append=T, file = feed_library_set_name, row.names=F, sep=',', col.names=F)	
		}
		feed_data = feed_db[feed_id,]
	}

}


get_feed_names = function(feed_library, feed_id.list) {

	feed_db = read.csv(feed_library, header=T, row.names=1)
	feed_name_db = feed_db[,1:2]

    feed_name_list_info = c ('', '', '', '', '' ) 

    for (l in 1:length(feed_id.list)) {
        id4out = feed_id.list[l]
        name4out = feed_name_db[id4out,1]
        name_info = sprintf("%s(feed_id:%s)", name4out, id4out)
        feed_name_list_info = c(feed_name_list_info, name_info, '', '', '', '', '', '')
    }

    feed_names_list_info = paste(feed_name_list_info, collapse=',')
	
    return (feed_names_list_info)
}


make_output_feed_ingred_data = function(file_path, n) {

	library(gdata)

	feed_out_data = NULL

	for (i in 1:n) {

		feed_file = sprintf("%s/feed_library_%s.csv", file_path, i)
		feed_data = read.csv(feed_file, row.names=1, header=F) 
		feed_data.subset = feed_data[2:nrow(feed_data),c(1,7,8,9,12,14,15,16)]

		feed_data.subset = feed_data.subset[,2:ncol(feed_data.subset)]

		feed_data.subset.trans = unmatrix(feed_data.subset, byrow=T)
		feed_out_data = rbind(feed_out_data, feed_data.subset.trans) 

	}

	feed_out_data = as.matrix(feed_out_data)


	return (feed_out_data)

}


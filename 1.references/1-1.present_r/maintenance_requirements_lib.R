library(tidyverse)
source("./modlib/constants_equations_v3.R")

###################################################
# Calculation nutrients maintenance requirements  #
###################################################

maintenance_requirements_fn<-function(diet_composition_rev,feed_data_rev,input_data_rev){
  
  input_data<-input_data_rev
  feed_data<-feed_data_rev
  diet_composition<-diet_composition_rev
  
  maint_energy_req<-maint_energy_req_fn(diet_composition,input_data)
  maint_protein_req<-maint_protein_req_fn(diet_composition,input_data)
  maint_amino_req<-maint_amino_req_fn(diet_composition,input_data)
  maint_fatty_req<-maint_fatty_req_fn(diet_composition,input_data)
  maint_vitamin_req<-maint_vitamin_req_fn(diet_composition,input_data)
  maint_mineral_req<-maint_mineral_req_fn(diet_composition,input_data)
  
  maint_nutr_req<-list("energy"=maint_energy_req,
                       "protein"=maint_protein_req,
                       # "amino" = maint_amino_req,
                       # "fatty" = maint_fatty_req,
                       # "vitamin" = maint_vitamin_req,
                       "mineral"= maint_mineral_req)
    
}



################################################
# Calculation maintenance protein requirements  #
################################################


maint_protein_req_fn<-function(diet_composition,input_data){
  # calcuation of metabolizable protein energy requirement for maintenance (MEm)
  # first calculation NEm requirment
  # basal NEM (fasting heat production + compensatory growth (BCS) + previous temperature)
  nem_basal<-nem_basal_fn(input_data)
  nem_coldstress<-nem_coldstress_fn(input_data,nem_basal,diet_composition)
  nem_heatstress<-nem_heatstress_fn(input_data)
  
  nem_req<-(nem_basal+nem_coldstress)*nem_heatstress
  maint_energy_req_wo_ureacost<-nem_req/(diet_composition$diet_nem.mcal.kg/diet_composition$diet_me.mcal.kg)
  return(maint_energy_req_wo_ureacost)
}




  

################################################
# Calculation maintenance energy requirements  #
################################################


maint_energy_req_fn_NASEM2024<-function(diet_composition,input_data){
  
  ##############################################################################################
  #                      Estimated ME and NE Use                                               #
  ##############################################################################################
  
  
  #convert variables to NASEM
  
  
  
  
  
  
  #### Net Energy of Maintenance Requirements (NEm, mcal/d) ####
  #Unstressed (NS) Maintenance costs NEm, mcal/d
  #Heifers
  An_NEmUse_NS <- 0.10 * An_BW^0.75  #Back calculated from MEm of 0.15 and Km_NE_ME = 0.66
  #Calves
  An_NEmUse_NS <- ifelse(An_StatePhys == "Calf", 0.0769*An_BW_empty^0.75, An_NEmUse_NS)  #milk or mixed diet
  An_NEmUse_NS <- ifelse(An_StatePhys == "Calf" & Dt_DMIn_ClfLiq == 0, 0.097*An_BW_empty^0.75, An_NEmUse_NS)  #weaned calf
  #Cows
  An_NEmUse_NS <- ifelse(An_Parity_rl>0, 0.10*An_BW^0.75,  An_NEmUse_NS)
  
  
  #Environmental stress cost (NEm_Env), mcal/d ##
  An_NEmUse_Env <- 0
  An_NEmUse_Env <- ifelse(Env_TempCurr<LCT & An_BW<100, 0.00201*(LCT-Env_TempCurr)*
                            An_MBW,An_NEmUse_Env)							#calves - cold stress
  An_NEmUse_Env <- ifelse(Env_TempCurr>UCT & An_BW<100, 0.00201*(Env_TempCurr-UCT)*
                            An_MBW,An_NEmUse_Env)							#calves - heat stress
  
  #Locomotion costs (NEm_Act), mcal/d ##
  An_Grazing <- ifelse(Dt_PastIn/Dt_DMIn < 0.005, 0, 1)
  An_NEm_Act_Graze <- ifelse(Dt_PastIn/Dt_DMIn < 0.005, 0, 
                             0.0075*An_MBW*(600-12*Dt_PastSupplIn)/600)
  An_NEm_Act_Parlor <-  (0.00035*Env_DistParlor/1000) * Env_TripsParlor * An_BW
  An_NEm_Act_Topo <- 0.0067*Env_Topo/1000 * An_BW
  An_NEmUse_Act <- An_NEm_Act_Graze + An_NEm_Act_Parlor + An_NEm_Act_Topo
  
  
  #Total Maintenance cost (NEm), mcal/d ##
  An_NEmUse <- An_NEmUse_NS + An_NEmUse_Env + An_NEmUse_Act
  
  
  ############ efficiencies of Energy Use (Kxxx), Mcal NE/Mcal ME ######################
  An_MEIn_ClfDry <- An_MEIn - Dt_MEIn_ClfLiq
  An_ME_ClfDry <- An_MEIn_ClfDry / (An_DMIn - Dt_DMIn_ClfLiq)
  An_NE_ClfDry <- 1.1104*An_ME_ClfDry - 0.0946*An_ME_ClfDry^2 + 0.0065*An_ME_ClfDry^3 - 0.7783
  
  ## Maintenance ##
  Km_ME_NE_Clf <- ifelse(An_StatePhys == "Calf" & An_ME_ClfDry > 0 & An_NE_ClfDry >0 & Dt_DMIn_ClfLiq == 0, 
                         An_NE_ClfDry/An_ME_ClfDry,   #Dry feed only
                         0.69)                       #mixed dry and liquid feed
  Km_ME_NE_Clf <- ifelse(An_StatePhys == "Calf" & Dt_DMIn_ClfStrt == 0 & Dt_DMIn_ClfLiq > 0, 0.723, Km_ME_NE_Clf) #Liquid feed only
  Km_ME_NE_Heif <- 0.63
  Km_ME_NE_Cow <- 0.66 #Dry and lactating
  Km_ME_NE <- ifelse(An_StatePhys == "Calf", Km_ME_NE_Clf, Km_ME_NE_Heif)  #calves, Heifer is default
  Km_ME_NE <- ifelse(An_StatePhys=="Lactating Cow" | An_StatePhys=="Dry Cow", Km_ME_NE_Cow, Km_ME_NE)  #Dry and Lactating Cows
  
  #Activity
  #Km_ME_NEact <- 0.66
  
  ## Lactation ##
  Kl_ME_NE <- 0.66
  
  ## Frame (f) Gain (excludes Reserves Gain or Loss) ##
  #Calf frame gain
  Kf_ME_RE_ClfLiq <- 0.56
  Kf_ME_RE_ClfDry <- (1.1376*An_DE*0.93 -0.1198*(An_DE*0.93)^2+0.0076*(An_DE*0.93)^3-1.2979)/(An_DE*0.93)
  Kf_ME_RE_Clf <- Kf_ME_RE_ClfLiq*Dt_DMIn_ClfLiq/Dt_DMIn + Kf_ME_RE_ClfDry*(Dt_DMIn-Dt_DMIn_ClfLiq)/Dt_DMIn
  
  Kf_ME_RE <- ifelse(An_StatePhys == "Calf", Kf_ME_RE_Clf, 0.4)    #Default frame gain is 0.4 for heifers and cows
  
  #Reserves Gain and Loss
  Kr_ME_RE <- 0.60                    #Efficiency of ME to RE for reserves gain, Heifers and dry cows
  Kr_ME_RE <- ifelse(Trg_MilkProd > 0 & Trg_RsrvGain > 0, 0.75, Kr_ME_RE) #Efficiency of ME to Rsrv RE for lactating cows gaining Rsrv
  Kr_ME_RE <- ifelse(Trg_RsrvGain <= 0, 0.89, Kr_ME_RE)                #Efficiency of ME generated for cows losing Rsrv
  
  ##Gestation ##
  Ky_ME_NE <- ifelse(Gest_REgain >= 0, 0.14, 0.89) #Gain from Ferrell et al, 1976, and loss assumed = Rsrv loss
  
  
  
  ############## ME Maintenance Requirements (MEm, mcal/d) ################
  An_MEmUse <- An_NEmUse / Km_ME_NE
  An_MEmUse_NS <- An_NEmUse_NS / Km_ME_NE
  An_MEmUse_Act <- An_NEmUse_Act / Km_ME_NE
  An_MEmUse_Env <- An_NEmUse_Env / Km_ME_NE
  An_NEm_ME <- An_NEmUse / An_MEIn #proportion of MEIn used for maintenance
  An_NEm_DE <- An_NEmUse / An_DEIn #proportion of DEIn used for maintenance
  An_NEmNS_DE <- An_NEmUse_NS / An_DEIn
  An_NEmAct_DE <- An_NEmUse_Act / An_DEIn
  An_NEmEnv_DE <- An_NEmUse_Env / An_DEIn
  
  ################ Energy Available for Production, Mcal/d ######################
  An_NEprod_Avail <- An_NEIn - An_NEmUse  
  An_MEprod_Avail <- An_MEIn - An_MEmUse
  
  ############################# Gestation ###########################################
  Gest_MEuse <- Gest_REgain / Ky_ME_NE
  Gest_NELuse <- Gest_MEuse * Kl_ME_NE  #mcal/d ME required. ??This should not be used, delete.
  Gest_NE_ME <- Gest_MEuse / An_MEIn #proportion of MEIn used for Gestation
  Gest_NE_DE <- Gest_REgain / An_DEIn #proportion of DEIn retained in gravid uterus tissue
  
  ######################## Frame and Reserves Gain ########################
  An_REgain <- 9.4*Body_Fatgain+5.55*Body_CPgain	     #Retained Energy, mcal/d. Does not apply to calves
  Rsrv_NEgain <- 9.4*Rsrv_Fatgain + 5.55*Rsrv_CPgain     #These are really REgain.  Abbreviations on NEgain need to be sorted out. MDH
  Frm_NEgain <- 9.4*Frm_Fatgain + 5.55*Frm_CPgain
  Rsrv_NE_DE <- Rsrv_NEgain / An_DEIn #proportion of DEIn used for Reserves gain
  Frm_NE_DE <- Frm_NEgain / An_DEIn #proportion of DEIn used for Frame gain
  Body_NEgain_BWgain <- An_REgain / Body_Gain #mcal NE/kg BW gain
  Rsrv_MEgain <- Rsrv_NEgain / Kr_ME_RE
  Frm_MEgain <- Frm_NEgain / Kf_ME_RE
  An_MEgain <- Rsrv_MEgain + Frm_MEgain
  An_ME_NEg <- An_REgain / An_MEgain  #A weighted average efficiency based on user entered or prediction frame and reserves gains. Cows only at this time.
  
  Rsrv_NELgain <- Rsrv_MEgain * Kl_ME_NE  #express body energy required in NEL terms
  Frm_NELgain <- Frm_MEgain * Kl_ME_NE
  An_NELgain <- An_MEgain * Kl_ME_NE
  
  An_NEgain_DE <- An_REgain / An_DEIn
  An_NEgain_ME <- An_REgain / An_MEIn
  
  ######################## Lactation Energy ########################
  Trg_MilkLacp <- ifelse(is.na(Trg_MilkLacp),4.78,Trg_MilkLacp)	#use the median if missing
  Trg_MilkLac <- Trg_MilkLacp/100 * Trg_MilkProd
  Trg_NEmilk_Milk <- 9.29*Trg_MilkFatp/100 + 5.85*Trg_MilkTPp/100 + 3.95*Trg_MilkLacp/100
  Trg_NEmilk_Milk <- ifelse(is.na(Trg_NEmilk_Milk), 0.36+9.69*Trg_MilkFatp/100, Trg_NEmilk_Milk) #If milk protein and lactose are not provided, use the Tyrrell and Reid (1965) eqn.
  Trg_Mlk_NEout <- Trg_MilkProd * Trg_NEmilk_Milk
  Trg_Mlk_MEout <- Trg_Mlk_NEout / Kl_ME_NE
  Trg_NEmilk_DEIn <- Trg_Mlk_NEout / An_DEIn
  Trg_MilkProd_EPcor <- 0.327*Trg_MilkProd + (12.97*Trg_MilkFatp/100*Trg_MilkProd) + 
    (7.65*Trg_MilkTPp/100*Trg_MilkProd)  #energy and protein corrected milk
  
  ## Energy Allowable Milk - biased estimates as assumption of all added energy to 1 target is wrong ##
  #An_NEavail_Milk <- An_NEIn - An_NEgain - An_NEmUse - Gest_NELuse ??Don't calculate directly.  Calculate from ME available.
  An_MEavail_Milk <- An_MEIn - An_MEgain - An_MEmUse - Gest_MEuse
  Mlk_Prod_NEalow <- An_MEavail_Milk * Kl_ME_NE / Trg_NEmilk_Milk 	#Energy allowable Milk Production, kg/d
  Mlk_Prod <- ifelse(An_StatePhys == "Lactating Cow" & mProd_eqn==2, Mlk_Prod_NEalow, Mlk_Prod)  #use NE Allowable Milk prediction
  Mlk_Prod <- ifelse(mProd_eqn==4, min(Mlk_Prod_NEalow,Mlk_Prod_MPalow), Mlk_Prod)  #Use min of NE and MP Allowable
  Mlk_Prod_NEalow_EPcor <- 0.327*Mlk_Prod_NEalow + (12.97*Trg_MilkFatp/100*Mlk_Prod_NEalow) + 
    (7.65*Trg_MilkTPp/100*Mlk_Prod_NEalow)  #energy and protein corrected milk
  Mlk_EPcorNEalow_DMIn <- Mlk_Prod_NEalow_EPcor / An_DMIn
  
  #Milk Composition
  #g/g
  MlkNP_Milk <- Mlk_NP_g/1000/Mlk_Prod;	#Milk true protein, g/g
  MlkNP_Milk <- ifelse(An_StatePhys == "Lactating Cow", MlkNP_Milk, 0)
  MlkFat_Milk <- Mlk_Fat / Mlk_Prod  #Milk Fat, g/g
  MlkFat_Milk <- ifelse(An_StatePhys == "Lactating Cow", MlkFat_Milk, 0)
  
  #Percentages
  MlkNP_Milk_p <- MlkNP_Milk*100
  MlkFat_Milk_p <- MlkFat_Milk*100
  
  
  MlkNE_Milk <- 9.29*MlkFat_Milk + 5.85*MlkNP_Milk + 3.95*Trg_MilkLacp/100
  Mlk_NEout <- MlkNE_Milk * Mlk_Prod
  Mlk_MEout <- Mlk_NEout / Kl_ME_NE
  Mlk_NE_DE <- Mlk_NEout / An_DEIn #proportion of DEIn used for milk
  
  ## Total Energy Use, Mcal/d ##
  An_MEuse <- An_MEmUse + An_MEgain + Gest_MEuse + Mlk_MEout
  Trg_MEuse <- An_MEmUse + An_MEgain + Gest_MEuse + Trg_Mlk_MEout
  An_NEuse <- An_NEmUse + An_REgain + Gest_REgain + Mlk_NEout
  Trg_NEuse <- An_NEmUse + An_REgain + Gest_REgain + Trg_Mlk_NEout
  An_NELuse <- An_MEuse * Kl_ME_NE
  Trg_NELuse <- Trg_MEuse * Kl_ME_NE
  
  An_NEprod_GE <- (An_NEuse-An_NEmUse) / An_GEIn  #Total efficiency of GE use
  Trg_NEprod_GE <- (Trg_NEuse-An_NEmUse) / An_GEIn  #Total efficiency of GE use
  An_NEmlk_GE <- Mlk_NEout / An_GEIn  #Efficiency of GE use for milk NE
  Trg_NEmlk_GE <- Trg_Mlk_NEout / An_GEIn  #Efficiency of GE use for milk NE
  
  An_MEbal <- An_MEIn - An_MEuse
  An_NELbal <- An_MEbal * Kl_ME_NE
  An_NEbal <- An_NEIn - An_NEuse
  
  Trg_MEbal <- An_MEIn - Trg_MEuse
  Trg_NELbal <- Trg_MEbal * Kl_ME_NE
  Trg_NEbal <- An_NEIn - Trg_NEuse
  
  An_MPuse_MEuse <- An_MPuse_g / An_MEuse     #g/mcal
  Trg_MPuse_MEuse <- An_MPuse_g_Trg / An_MEuse
  
  ## Energy Allowable Gain at the user specified mix of Frame and Reserves ##
  An_MEavail_Grw <- An_MEIn - An_MEmUse - Gest_MEuse - Mlk_MEout
  #Use a weighted average of Kf and Kr to predict allowable gain at that mix of Frm and Rsrv gain.
  Kg_ME_NE <- Kf_ME_RE*Frm_NEgain/(Frm_NEgain+Rsrv_NEgain) + Kr_ME_RE*Rsrv_NEgain/(Frm_NEgain+Rsrv_NEgain)
  Body_Gain_NEalow <- An_MEavail_Grw * Kg_ME_NE / Body_NEgain_BWgain
  
  
  #Make NEallow have the same comp as the mix of Trg Rsrv and Frm
  An_BodConcgain_NEalow <- Body_Gain_NEalow + Conc_BWgain
  Body_Fatgain_NEalow <- 0.85*(Body_Gain_NEalow/0.85-1.19)/8.21
  Body_NPgain_NEalow <- 0.85 * (1-Body_Fatgain_NEalow/0.85) * 0.215
  
  An_Days_BCSdelta1 <- BW_BCS / Body_Gain_NEalow   #days to gain or lose 1 BCS (9.4% of BW), 5 pt scale.
  
  
  
  
  
}
  





maint_energy_req_fn<-function(diet_composition,input_data){
  # calcuation of metabolisable energy requirement for maintenance (MEm)
  # first calculation NEm requirment
  # basal NEM (fasting heat production + compensatory growth (BCS) + previous temperature)
  nem_basal<-nem_basal_fn(input_data)
  nem_coldstress<-nem_coldstress_fn(input_data,nem_basal,diet_composition)
  nem_heatstress<-nem_heatstress_fn(input_data)
  
  nem_req<-(nem_basal+nem_coldstress)*nem_heatstress
  maint_energy_req_wo_ureacost<-nem_req/(diet_composition$diet_nem.mcal.kg/diet_composition$diet_me.mcal.kg)
  return(maint_energy_req_wo_ureacost)
}

nem_heatstress_fn<-function(input_data){
  eff_temp_index_cur<-eff_temp_index(input_data$temp_cur,input_data$humid_cur,input_data$wind.kmh,input_data$radiation.hr)
  if(input_data$panting == 3){
    nem_heatstress<-1.18
  }else if(input_data$panting == 2){
    nem_heatstress<-1.07
  }else if (eff_temp_index_cur > 20) {
    nem_heatstress <- 1.09857-(0.01343*eff_temp_index_cur)+(0.000457*eff_temp_index_cur^2)
  } else {nem_heatstress <- 1} 
}


nem_basal_fn<-function(input_data){
  fhp<-fhp_breed_table[[input_data$breed_name]][[input_data$stage_name]]
  
  compensatory_adj<-compensatory_adj_fn(input_data$bcs_beef)
  
  # effective temperature index of past month
  if(input_data$temp_past>20){
    eff_temp_index_past<-eff_temp_index(input_data$temp_past,input_data$humid_past,input_data$ind.km,input_data$radiation.hr)
  }else{eff_temp_index_past<-input_data$temp_past}
    
  prev_temp_adj<-prev_temp_adj_fn(eff_temp_index_past)
  activity<-activity_code[input_data$area_head_code,]
  nem_act<-nem_act_fn(activity, input_data$full_bw)
  
  nem_basal<-((input_data$shrunk_bw^0.75*((fhp*compensatory_adj)+prev_temp_adj))+nem_act)
  return(nem_basal)
}

nem_coldstress_fn<-function(input_data,nem_basal,diet_composition){
  # dietary ME concentration
  me<-diet_composition$diet_me.mcal.kg
  
  # body surface area
  surface_area<-surface_area_fn(input_data$shrunk_bw)
  
  ######################################
  # calculating heat production
  
  # DMI required for maintenance
  dmi_maintenance<-nem_basal/diet_composition$diet_nem.mcal.kg
  
  # Net energy intake for production
  # dietary concentration of net energy for production 
  if(input_data$stage_name == "lactating"){
    diet_ne_production<-diet_composition$diet_nel.mcal.kg
  }else if(input_data$stage_name == "drying"){
    diet_ne_production<-diet_composition$diet_nem.mcal.kg
  }else{diet_ne_production<-diet_composition$diet_neg.mcal.kg}
  
  ne_intake_production<-(diet_composition$target_dmi - dmi_maintenance)*diet_ne_production
  
  # heat production
  heat_production<-(me*diet_composition$target_dmi - diet_ne_production)/surface_area
  ######################################
  
  ######################################
  # calculating external insulation
  # mud adjustment
  if(input_data$hair_condition <= 2){
    mud_adj<-1-(input_data$hair_condition - 1)*0.2
  }else{mud_adj<-1-(input_data$hair_condition - 2)*0.3}
  
  # hide adjustment
  hide_adj<- 0.8 + (input_data$hide-1) * 0.2 
  
  # external insulation
  insulation_external<-(7.36-0.296*input_data$wind.kmh+2.55*input_data$hair_length)*mud_adj*hide_adj
  ######################################
  
  ######################################
  # calculating internal insulation
  if(input_data$age.month<1){
    insulation_tissue<-2.5  
  }else if(input_data$age.month >= 1 & input_data$age.month < 6){
    insulation_tissue<-6.5  
  }else if(input_data$age.month >= 6 & input_data$age.month < 12){
    insulation_tissue<-5.1875+(0.3125*input_data$bcs_beef)  
  }else{insulation_tissue<-5.25+(0.75*input_data$bcs_beef)}
  ######################################
  
  # calculating total insulation
  insulation_total<-insulation_tissue+insulation_external
  
  # calculating lower critical temperature
  lct<-39-(insulation_total*heat_production*0.85)
  
  # calculating ME requirement for cold stress
  if(lct>input_data$temp_cur){
    me_coldstress<-surface_area*(lct-input_data$temp_cur)/insulation_total
  }else{me_coldstress<-0}
  
  # calculating NE requirement for cold stress
  nem_coldstress<-nem_basal/me*me_coldstress
  return(nem_coldstress)
}  

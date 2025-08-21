library(tidyverse)
source("./modlib/constants_equations_v3.R")

#########################################
# Calculation Energy supply of the Diet  #
#########################################

dmi_prediction<-function(diet_composition_rev,input_data_rev){
  
  # animal related variables
  breed_name<-input_data_rev$breed_name
  stage_name<-input_data_rev$stage_name
  age.month<-input_data_rev$age.month
  gender<-input_data_rev$gender
  full_bw<-input_data_rev$full_bw
  preg.day<-input_data_rev$preg.day
  milk.day<-input_data_rev$milk.day
  calf_bw<-input_data_rev$calf_bw
  mature_bw<-input_data_rev$mature_bw
  bcs_beef<-input_data_rev$bcs_beef
  target_adg<-input_data_rev$target_adg
  milk_yield<-input_data_rev$milk_yield
  milk_fat<-input_data_rev$milk_fat
  milk_cp<-input_data_rev$milk_cp
  shrunk_bw<-input_data_rev$shrunk_bw
  empty_bw<-input_data_rev$empty_bw
  mature_shrunk_bw<-input_data_rev$mature_shrunk_bw
  eq_shrunk_bw<-input_data_rev$eq_shrunk_bw
  eq_empty_bw<-input_data_rev$eq_empty_bw
  lact_no<-input_data_rev$lact_no
  bcs_dairy<-input_data_rev$bcs_dairy
  
  
  # feed related variables
  diet_ndf.p<-diet_composition_rev$diet_ndf.p
  diet_nem.mcal.kg<-diet_composition_rev$diet_nem.mcal.kg
  
  
  # environment related variables
  wind.kmh<-input_data_rev$wind.kmh
  temp_past<-input_data_rev$temp_past
  humid_past<-input_data_rev$humid_past
  temp_cur<-input_data_rev$temp_cur
  humid_cur<-input_data_rev$humid_cur
  no_cooling_night<-input_data_rev$no_cooling_night
  mud_depth<-input_data_rev$mud_depth
  radiation.hr<-input_data_rev$radiation.hr
  
  # effective temperature index for the current month
  eff_temp_index_cur<-eff_temp_index(temp_cur,humid_cur,wind.kmh,radiation.hr)
  
  # dry matter intake prediction
  
  if(breed_name=="hanwoo"){
    # Hanwoo has different equations based on Japanese Feeding Standard
    predict_dmi<-DMI_Hanwoo(gender,full_bw,target_adg)
  }else{
    # Holstein DMI predictions based on CNCPS
    
    # dry matter intake adjustment factors
    dmi_temp_adj<-dmi_temp_adj(temp_cur,eff_temp_index_cur,no_cooling_night)
    dmi_mud_adj<-dmi_mud_adj(mud_depth)
    dmi_beef_adj<-dmi_beef_adj(breed_name,stage_name,gender,eq_shrunk_bw)
    
    if(stage_name=="lactating"){
      predict_dmi<-DMI_Holstein_lact_KFS(stage_name,full_bw,milk_yield,milk_fat,milk.day,diet_ndf.p)
    }else{
      predict_dmi<-DMI_Holstein_non_lact_CNCPS(stage_name,age.month,full_bw,target_adg,diet_nem.mcal.kg,calf_bw,preg.day)
    }
    predict_dmi<-predict_dmi*dmi_temp_adj*dmi_mud_adj*dmi_beef_adj
  } 
  return(round(predict_dmi,2))
  
}
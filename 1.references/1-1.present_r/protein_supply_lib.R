# last updated on 20240805


library(tidyverse)
source("./modlib/constants_equations_v3.R")

#########################################
# Calculation protein supply of the Diet  #
#########################################

diet_protein<-function(diet_composition_rev,feed_data_rev,input_data_rev,solution_level){
  if(solution_level == "zero"){
    
    # use tabular RUP1x
  
    # calculate DMI factor - based on NRC (2001, p327)
    # Total TDN1x intake
    TotalTDN<-sum(feed_data_rev$tdn.kg)
    
    if(input_data_rev$stage_name %in% c("lactating","drying","calf")){
      DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))
    }else{DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))}
    
    dmi_factor<-DMI_to_DMIMaint - 1
    
    
    # Feed protein calculation based on based on CNCPS Level 1 (Fox et al., 2001)
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rupx.p.cp = RUPxx_CNCPS_L1(feed_class,conc.p,forage.p,rup1x.p.cp,dmi_factor)) %>% 
      mutate(rdpx.p.cp = 100 - rupx.p.cp) 
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rdpx.kg.kg=cp.p.dm/100*(rdpx.p.cp/100)) %>% 
      mutate(rupx.kg.kg=cp.p.dm/100*(rupx.p.cp/100)) %>% 
      mutate(mp.bact.g.kg=MP_Bacteria_NRC_dairy_2001(dtdn.p)) %>% 
      mutate(mp.rup.g.kg=MP_RUP_NRC_dairy_2001(rupx.p.cp,cp.p.dm)) %>% 
      mutate(mp.g.kg=mp.bact.g.kg + mp.rup.g.kg)

    diet_protein<-feed_data_rev %>% 
      mutate(rupx.kg=rupx.kg.kg*dm.kg) %>% 
      mutate(mp.bact.g=mp.bact.g.kg*dm.kg) %>% 
      mutate(mp.rup.g=mp.rup.g.kg*dm.kg) %>% 
      mutate(mp.g=mp.g.kg*dm.kg) %>% 
      summarise_at(vars(rupx.kg:mp.g),sum)
    
    diet_protein$rupx.kg<-diet_protein$rupx.kg/sum(feed_data_rev$cp.kg)*100
  
    names(diet_protein)<-c("diet_rupx.p.cp","diet_mp_bact.g","diet_mp_rup.g","diet_mp.g")
    
    diet_protein$diet_rupx.p.cp<-round(diet_protein$diet_rupx.p.cp,2)
    diet_protein$diet_mp_bact.g<-round(diet_protein$diet_mp_bact.g,0)
    diet_protein$diet_mp_rup.g<-round(diet_protein$diet_mp_rup.g,0)
    diet_protein$diet_mp.g<-round(diet_protein$diet_mp.g,0)
    
    diet_composition_rev<-cbind(diet_composition_rev,diet_protein)
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
  }
  else if(solution_level == "one"){
    TotalTDN<-sum(feed_data_rev$tdn.kg)
    
    if(input_data_rev$stage_name %in% c("lactating","drying","calf")){
      DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))
    }else{DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))}
    
    dmi_factor<-DMI_to_DMIMaint - 1
    
    
  # Feed protein calculation based on protein fractions, kd, and kp
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rup1x.p.cp = RUP1x_CNCPS_L1(feed_class,conc.p,forage.p,cp.p.dm,solp.p.dm,ndicp.p.dm,adicp.p.dm,p_a.p.hr,p_b1.p.hr,p_b2.p.hr,p_b3.p.hr,p_c.p.hr,snpn.p.cp)) %>% 
      mutate(rupx.p.cp = RUPxx_CNCPS_L1(feed_class,conc.p,forage.p,rup1x.p.cp,dmi_factor)) %>% 
      mutate(rdpx.p.cp = 100 - rupx.p.cp) 
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rdpx.kg.kg=cp.p.dm/100*(rdpx.p.cp/100)) %>% 
      mutate(rupx.kg.kg=cp.p.dm/100*(rupx.p.cp/100)) %>% 
      mutate(mp.bact.g.kg=MP_Bacteria_NRC_dairy_2001(dtdn.p)) %>% 
      mutate(mp.rup.g.kg=MP_RUP_NRC_dairy_2001(rupx.p.cp,cp.p.dm)) %>% 
      mutate(mp.g.kg=mp.bact.g.kg + mp.rup.g.kg)
    
    diet_protein<-feed_data_rev %>% 
      mutate(rupx.kg=rupx.kg.kg*dm.kg) %>% 
      mutate(mp.bact.g=mp.bact.g.kg*dm.kg) %>% 
      mutate(mp.rup.g=mp.rup.g.kg*dm.kg) %>% 
      mutate(mp.g=mp.g.kg*dm.kg) %>% 
      summarise_at(vars(rupx.kg:mp.g),sum)
    
    diet_protein$rupx.kg<-diet_protein$rupx.kg/sum(feed_data_rev$cp.kg)*100
    
    names(diet_protein)<-c("diet_rupx.p.cp","diet_mp_bact.g","diet_mp_rup.g","diet_mp.g")
    
    diet_protein$diet_rupx.p.cp<-round(diet_protein$diet_rupx.p.cp,2)
    diet_protein$diet_mp_bact.g<-round(diet_protein$diet_mp_bact.g,0)
    diet_protein$diet_mp_rup.g<-round(diet_protein$diet_mp_rup.g,0)
    diet_protein$diet_mp.g<-round(diet_protein$diet_mp.g,0)
    
    diet_composition_rev<-cbind(diet_composition_rev,diet_protein)
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
    
    
  }
  else if(solution_level == "NASEM2021"){
    
    # Feed protein calculation based on protein fractions, static kd, and kp and fraction A ruminal digestibility 
    # based on NASEM(2021)
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rdpx.p.cp = RDP35_NASEM2021_L1(snpn.p.cp,conc.p,forage.p,cp.p.dm,insitu_p_a.p.cp,insitu_p_b.p.cp,insitu_p_c.p.cp,insitu_p_b.p.hr)) %>% 
      mutate(rupx.p.cp = RUP35_NASEM2021_L1(snpn.p.cp,conc.p,forage.p,cp.p.dm,insitu_p_a.p.cp,insitu_p_b.p.cp,insitu_p_c.p.cp,insitu_p_b.p.hr))
      
    
    feed_data_rev<-feed_data_rev %>%
      mutate(rdpx.kg.kg=cp.p.dm/100*(rdpx.p.cp/100)) %>% 
      mutate(rupx.kg.kg=cp.p.dm/100*(rupx.p.cp/100)) %>% 
      mutate(mp.bact.g.kg=MP_Bacteria_NRC_dairy_2001(dtdn.p)) %>% 
      mutate(mp.rup.g.kg=MP_RUP_NRC_NASEM_2021(rupx.p.cp,cp.p.dm,drup.p.rup)) %>% 
      mutate(mp.g.kg=mp.bact.g.kg + mp.rup.g.kg)
    
    diet_protein<-feed_data_rev %>% 
      mutate(rupx.kg=rupx.kg.kg*dm.kg) %>% 
      mutate(mp.bact.g=mp.bact.g.kg*dm.kg) %>% 
      mutate(mp.rup.g=mp.rup.g.kg*dm.kg) %>% 
      mutate(mp.g=mp.g.kg*dm.kg) %>% 
      summarise_at(vars(rupx.kg:mp.g),sum)
    
    diet_protein$rupx.kg<-diet_protein$rupx.kg/sum(feed_data_rev$cp.kg)*100
    
    names(diet_protein)<-c("diet_rupx.p.cp","diet_mp_bact.g","diet_mp_rup.g","diet_mp.g")
    
    diet_protein$diet_rupx.p.cp<-round(diet_protein$diet_rupx.p.cp,2)
    diet_protein$diet_mp_bact.g<-round(diet_protein$diet_mp_bact.g,0)
    diet_protein$diet_mp_rup.g<-round(diet_protein$diet_mp_rup.g,0)
    diet_protein$diet_mp.g<-round(diet_protein$diet_mp.g,0)
    
    diet_composition_rev<-cbind(diet_composition_rev,diet_protein)
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
  }
  else if(solution_level == "three"){
    
  }else{stop()}
}







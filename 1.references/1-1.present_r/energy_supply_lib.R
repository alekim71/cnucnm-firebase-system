# last updated on 20240805

library(tidyverse)
source("./modlib/constants_equations_v3.R")

#########################################
# Calculation Energy supply of the Diet  #
#########################################

diet_energy<-function(diet_composition,feed_data_rev,input_data_rev,solution_level){
  if(solution_level == "zero"){
    
    # use tabular TDN1x
    # feed_energy<-feed_data_rev %>%
    #   select(dm.kg,feed_class,conc.p,forage.p,dm.p.af,ndf.p.dm,ee.p.dm,tdn.p.dm,tdn.kg)
    
    # calculate DMI factor - based on NRC (2001, p327)
    # Total TDN1x intake
    TotalTDN<-sum(feed_data_rev$tdn.kg)
    
    if(input_data_rev$stage_name %in% c("lactating","drying","calf")){
      DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))
    }else{DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))}
    
    dmi_factor<-DMI_to_DMIMaint - 1
    
    
    # Feed energy calculation based on based on NRC Dairy (2001)
    
    feed_data_rev<-feed_data_rev %>%
      mutate(dtdn.p=dTDN_NRC_dairy_2001(tdn.p.dm,dmi_factor)) %>% 
      # DE = 0.04409 *dTDN
      mutate(ge.mcal.kg=GE_basic(ndf.p.dm,cp.p.dm,ee.p.dm,nfc.p.dm)) %>% 
      mutate(de.mcal.kg=TDN_to_DE_CNCPS_L1(dtdn.p)) %>% 
      mutate(me.mcal.kg=DE_to_ME_NRC_dairy_2001(de.mcal.kg,feed_class,input_data_rev$stage_name,ee.p.dm)) %>% 
      mutate(nem.mcal.kg=ME_to_NEm_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(neg.mcal.kg=ME_to_NEg_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(nel.mcal.kg=ME_to_NEl_NRC_dairy_2001(me.mcal.kg,feed_class,ee.p.dm))
    
    feed_data_rev<-feed_data_rev %>% 
      mutate(dtdn.kg=dm.kg*(dtdn.p/100)) %>% 
      mutate(ge.mcal=dm.kg*ge.mcal.kg,de.mcal=dm.kg*de.mcal.kg,me.mcal=dm.kg*me.mcal.kg,
             nem.mcal=dm.kg*nem.mcal.kg,neg.mcal=dm.kg*neg.mcal.kg,nel.mcal=dm.kg*nel.mcal.kg)
    
    # feed_energy.mcal<-feed_energy %>% 
    #   select(dtdn.kg:nel.mcal)
    # 
    diet_energy<-feed_data_rev %>% 
      summarise_at(vars(dtdn.kg:nel.mcal),sum)
    
    diet_energy<-diet_energy/sum(feed_data_rev$dm.kg)
    diet_energy$dtdn.kg<-diet_energy$dtdn.kg*100
    names(diet_energy)<-c("diet_dtdn.p","diet_ge.mcal.kg","diet_de.mcal.kg","diet_me.mcal.kg","diet_nem.mcal.kg","diet_neg.mcal.kg","diet_nel.mcal.kg")
    
    diet_composition_rev<-cbind(diet_composition,round(diet_energy,2))
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
      
  }
  else if(solution_level == "NASEM2021_zero"){
    # 20240805
    # NASEM2021의 feedlibrary를 만들때 DE base를 기초로 TDN을 산출함. 
    # DE base는 DMI = 3.5% BW, starch 26%, dietary NDF 30%를 기본으로 함. 
    # 따라서 tdn은 discounted TDN, dtdn과 동일

    feed_data_rev<-feed_data_rev %>%
      mutate(dtdn.p=tdn.p.dm) %>% 
      # GE는 feedlibrary 전환시에 이미 계산을 했으므로 그대로 이용
      # mutate(ge.mcal.kg=ge.mcal.kg) %>% 
      # DE = 0.04409 *dTDN
      mutate(de.mcal.kg=dtdn.p*0.04409) %>% 
      mutate(me.mcal.kg=DE_to_ME_NRC_dairy_2001(de.mcal.kg,feed_class,input_data_rev$stage_name,ee.p.dm)) %>% 
      mutate(nem.mcal.kg=ME_to_NEm_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(neg.mcal.kg=ME_to_NEg_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(nel.mcal.kg=ME_to_NEl_NRC_dairy_2001(me.mcal.kg,feed_class,ee.p.dm))
    
    feed_data_rev<-feed_data_rev %>% 
      mutate(dtdn.kg=dm.kg*(dtdn.p/100)) %>% 
      mutate(ge.mcal=dm.kg*ge.mcal.kg,de.mcal=dm.kg*de.mcal.kg,me.mcal=dm.kg*me.mcal.kg,
             nem.mcal=dm.kg*nem.mcal.kg,neg.mcal=dm.kg*neg.mcal.kg,nel.mcal=dm.kg*nel.mcal.kg)
    
    # feed_energy.mcal<-feed_energy %>% 
    #   select(dtdn.kg:nel.mcal)
    # 
    diet_energy<-feed_data_rev %>% 
      summarise_at(vars(dtdn.kg:nel.mcal),sum)
    
    diet_energy<-diet_energy/sum(feed_data_rev$dm.kg)
    diet_energy$dtdn.kg<-diet_energy$dtdn.kg*100
    names(diet_energy)<-c("diet_dtdn.p","diet_ge.mcal.kg","diet_de.mcal.kg","diet_me.mcal.kg","diet_nem.mcal.kg","diet_neg.mcal.kg","diet_nel.mcal.kg")
    
    diet_composition_rev<-cbind(diet_composition,round(diet_energy,2))
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
  }
  else if(solution_level == "one"){
    
    # feed_energy<-feed_data_rev %>%
    #   select(dm.kg,feed_class,conc.p,forage.p,ndf.p.dm,lignin.p.ndf,cp.p.dm,ndicp.p.cp,adicp.p.cp,ee.p.dm,ash.p.dm)
    # 
    
    # Feed energy calculation based on CNCPS Level 1 with some modifications according to RNS (2021)
    
    feed_data_rev<-feed_data_rev %>%
      mutate(tdn.p.dm=TDN1x_CNCPS_L1(feed_class,conc.p,forage.p,ndf.p.dm,lignin.p.dm,cp.p.dm,ndicp.p.dm,adicp.p.dm,ash.p.dm,ee.p.dm,fa.p.dm,dfa.p.fa=73)) %>% 
      mutate(tdn.kg=tdn.p.dm/100*dm.kg)
    
    
    # calculate DMI factor - based on NRC (2001, p327)
    # Total TDN1x intake
    TotalTDN<-sum(feed_data_rev$tdn.kg)
    
    if(input_data_rev$stage_name %in% c("lactating","drying","calf")){
      DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))
    }else{DMI_to_DMIMaint<-TotalTDN/(0.035*(input_data_rev$full_bw^0.75))}
    
    dmi_factor<-DMI_to_DMIMaint - 1
    
    # discounted TDN based on NRC dairy 2001
    feed_data_rev<-feed_data_rev %>%
      mutate(dtdn.p=dTDN_NRC_dairy_2001(tdn.p.dm,dmi_factor)) %>% 
      # DE = 0.04409 *dTDN
      mutate(ge.mcal.kg=GE_basic(ndf.p.dm,cp.p.dm,ee.p.dm,nfc.p.dm)) %>% 
      mutate(de.mcal.kg=TDN_to_DE_CNCPS_L1(dtdn.p)) %>% 
      mutate(me.mcal.kg=DE_to_ME_NRC_dairy_2001(de.mcal.kg,feed_class,input_data_rev$stage_name,ee.p.dm)) %>% 
      mutate(nem.mcal.kg=ME_to_NEm_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(neg.mcal.kg=ME_to_NEg_NRC_dairy_2001(me.mcal.kg,feed_class)) %>% 
      mutate(nel.mcal.kg=ME_to_NEl_NRC_dairy_2001(me.mcal.kg,feed_class,ee.p.dm))
    
    feed_data_rev<-feed_data_rev %>% 
      mutate(dtdn.kg=dm.kg*(dtdn.p/100)) %>% 
      mutate(ge.mcal=dm.kg*ge.mcal.kg,de.mcal=dm.kg*de.mcal.kg,me.mcal=dm.kg*me.mcal.kg,
             nem.mcal=dm.kg*nem.mcal.kg,neg.mcal=dm.kg*neg.mcal.kg,nel.mcal=dm.kg*nel.mcal.kg)
    
    # feed_energy.mcal<-feed_energy %>% 
    #   select(dtdn.kg:nel.mcal)
    # 
    diet_energy<-feed_data_rev %>% 
      summarise_at(vars(dtdn.kg:nel.mcal),sum)
    
    diet_energy<-diet_energy/sum(feed_data_rev$dm.kg)
    diet_energy$dtdn.kg<-diet_energy$dtdn.kg*100
    names(diet_energy)<-c("diet_dtdn.p","diet_ge.mcal.kg","diet_de.mcal.kg","diet_me.mcal.kg","diet_nem.mcal.kg","diet_neg.mcal.kg","diet_nel.mcal.kg")
    
    diet_composition_rev<-cbind(diet_composition,round(diet_energy,2))
    
    return(list(diet_composition_rev=diet_composition_rev, feed_data_rev=feed_data_rev))
  }
  else if(solution_level == "two"){
    
  }
  else if(solution_level == "three"){
    
  }else{stop()}
  
  
  
}







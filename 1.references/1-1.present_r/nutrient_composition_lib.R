library(tidyverse)

################################################
# Calcuation Nutrient Composition of the Diet  #
################################################

# arguments 
# feed_data: diet formulation based on the format of CNUCNM v3 - first col, kg DM; 
# animal_info: c("breed_name",")
# new version 
# updated by Seo on 20240730

diet_nutrients<-function(feed_data){
  fd<-feed_data %>%
    mutate(
      f_ndf.p.dm=ndf.p.dm*forage.p/100
    ) 

  fd<-fd %>%
    # major nutrients
    mutate(
      af.kg=AF,dm.kg=af.kg*dm.p.af/100,
      forage.kg=dm.kg*forage.p/100, 
      om.kg=dm.kg*(om.p.dm/100),
      nfc.kg=dm.kg*(nfc.p.dm/100),
      ndf.kg=dm.kg*(ndf.p.dm/100),
      f_ndf.kg=dm.kg*f_ndf.p.dm/100,
      adf.kg=dm.kg*(adf.p.dm/100),
      cf.kg=dm.kg*(cf.p.dm/100),
      lignin.kg=dm.kg*(lignin.p.dm/100),
      cp.kg=dm.kg*(cp.p.dm/100),
      solp.kg=dm.kg*(solp.p.dm/100),
      ndicp.kg=dm.kg*(ndicp.p.dm/100),
      adicp.kg=dm.kg*(adicp.p.dm/100),
      ee.kg=dm.kg*(ee.p.dm/100),
      ash.kg=dm.kg*(ash.p.dm/100),
      pndf.kg=dm.kg*(pndf.p.ndf/100*ndf.p.dm/100),
      tdn.kg=dm.kg*(tdn.p.dm/100)
    )
  fd<-fd %>%
    mutate(
      starch.kg=dm.kg*(starch.p.dm/100)
    )
  # amino acids
  # fd<-fd %>%
  #   mutate(
  #     met.kg=cp.kg*(met.p.uip/100),lys.kg=cp.kg*(lys.p.uip/100),arg.kg=cp.kg*(arg.p.uip/100),thr.kg=cp.kg*(thr.p.uip/100),leu.kg=cp.kg*(leu.p.uip/100),
  #     ile.kg=cp.kg*(ile.p.uip/100),val.kg=cp.kg*(val.p.uip/100),his.kg=cp.kg*(his.p.uip/100),phe.kg=cp.kg*(phe.p.uip/100),trp.kg=cp.kg*(trp.p.uip/100)
  #   )

  # mineral
  fd<-fd %>%
    mutate(
      ca.kg=dm.kg*(ca.p.dm/100),pho.kg=dm.kg*(p.p.dm/100),mg.kg=dm.kg*(mg.p.dm/100),cl.kg=dm.kg*(cl.p.dm/100),
      k.kg=dm.kg*(k.p.dm/100),na.kg=dm.kg*(na.p.dm/100),sulf.kg=dm.kg*(s.p.dm/100)
      # ,co.mg=dm.kg*co.ppm.dm,cu.mg=dm.kg*cu.ppm.dm,i.mg=dm.kg*i.ppm.dm,fe.mg=dm.kg*fe.ppm.dm,mn.mg=dm.kg*mn.ppm.dm,se.mg=dm.kg*se.ppm.dm,zn.mg=dm.kg*zn.ppm.dm
    )

  # vitamin
  # fd<-fd %>%
  #   mutate(vit_a.1000iu=dm.kg*vit_a.1000iu.kg,vit_d.1000iu=dm.kg*vit_d.1000iu.kg,vit_e.iu=dm.kg*vit_e.iu.kg)

  nutrients_sum<-fd %>%
    # summarise_at(vars(af.kg:vit_e.iu),sum) if micro nutrients are to be considered
    summarise_at(vars(af.kg:sulf.kg),sum)
  
  # dietary concencentration % DM
  diet_nutrients<-nutrients_sum/nutrients_sum$dm.kg*100
  
  # Replace intakes to the amount in kg
  diet_nutrients[1]<- nutrients_sum[2]
  diet_nutrients[2]<- nutrients_sum[2]/nutrients_sum[1]*100

  # Replace the column names of diet nutrient composition to be consistent with the model variables
  names(diet_nutrients)<-c("target_dmi","diet_dm.p.af","diet_forage.p","diet_om.p","diet_nfc.p","diet_ndf.p",
                           "diet_fndf.p","diet_adf.p","diet_cf.p","diet_lignin.p","diet_cp.p","diet_solp.p",
                           "diet_ndicp.p","diet_adicp.p","diet_ee.p","diet_ash.p","diet_pndf.p","diet_tdn1x.p","diet_starch.p",
                           "diet_ca.p","diet_phos.p","diet_mg.p","diet_cl.p","diet_k.p","diet_na.p","diet_sulf.p")
  
  names(diet_nutrients)

  # calculate DCAB1(simple; Ender et al., 1971) and DCAB2(complex; Goff et al., 1997)
  # according to NRC, coefficient of sulfur is 0.6 instead of 0.25
  # The equations should be checked again
  
  diet_nutrients<-diet_nutrients %>%
    mutate(diet_dcad1.meq.100g=(435*diet_na.p+256*diet_k.p)-(282*diet_cl.p+624*diet_sulf.p),
           diet_dcad2.meq.100g=(453*diet_na.p+256*diet_k.p+0.15*500*diet_ca.p+0.15*823*diet_mg.p)-(282*diet_cl.p+0.25*624*diet_sulf.p+0.5*968*diet_phos.p))

  # Round to two decimals
  diet_nutrients<-round(diet_nutrients,2)
  
  # Return diet nutrients composition and revised feed_data as a list
  return(list(diet_nutrients=diet_nutrients,feed_data=fd))

}


######################################################################################################################################
# previous version with CNUCNM v2
# 
# 
# diet_nutrients<-function(feed_data){
#   fd<-feed_data %>%
#     
#     ###########
#   # Om, nfc #
#   ###########
#   mutate(
#     om.p.dm=100-ash.p.dm,
#     nfc.p.dm=om.p.dm - (cp.p.dm+ee.p.dm)- ndf.p.dm, # equation to estimate nfc
#     f_ndf.p.dm=ndf.p.dm*forage.p/100
#   ) 
#   
#   # if calculated OM is less than o, OM = 0
#   fd$om.p.dm[fd$om.p.dm<=0]<-0
#   
#   # if calculated nfc is less than o, nfc = 0
#   fd$nfc.p.dm[fd$nfc.p.dm<=0]<-0
#   
#   fd<-fd %>%
#     # major nutrients
#     mutate(
#       af.kg=AF,dm.kg=af.kg*dm.p.af/100,
#       forage.kg=dm.kg*forage.p/100, om.kg=dm.kg*(om.p.dm/100),nfc.kg=dm.kg*(nfc.p.dm/100),
#       ndf.kg=dm.kg*(ndf.p.dm/100),f_ndf.kg=dm.kg*f_ndf.p.dm/100,adf.kg=dm.kg*(adf.p.dm/100),cf.kg=dm.kg*(cf.p.dm/100),lignin.kg=dm.kg*(lignin.p.ndf/100*ndf.p.dm/100),
#       cp.kg=dm.kg*(cp.p.dm/100),solp.kg=dm.kg*(solp.p.cp/100*cp.p.dm/100),npn.kg=dm.kg*(npn.p.solp/100*solp.p.cp/100*cp.p.dm/100),ndicp.kg=dm.kg*(ndicp.p.cp/100*cp.p.dm/100),adicp.kg=dm.kg*(adicp.p.cp/100*cp.p.dm/100),
#       ee.kg=dm.kg*(ee.p.dm/100),ash.kg=dm.kg*(ash.p.dm/100),pndf.kg=dm.kg*(pndf.p.ndf/100*ndf.p.dm/100),tdn.kg=dm.kg*(tdn.p.dm/100)
#     ) 
#   fd<-fd %>%
#     mutate(
#       ##########################
#       # May need to be changed #
#       ##########################
#       starch.kg=dm.kg*(starch.p.nfc/100*nfc.p.dm/100)
#     )
#   # amino acids
#   # fd<-fd %>%
#   #   mutate(
#   #     met.kg=cp.kg*(met.p.uip/100),lys.kg=cp.kg*(lys.p.uip/100),arg.kg=cp.kg*(arg.p.uip/100),thr.kg=cp.kg*(thr.p.uip/100),leu.kg=cp.kg*(leu.p.uip/100),
#   #     ile.kg=cp.kg*(ile.p.uip/100),val.kg=cp.kg*(val.p.uip/100),his.kg=cp.kg*(his.p.uip/100),phe.kg=cp.kg*(phe.p.uip/100),trp.kg=cp.kg*(trp.p.uip/100)
#   #   )
#   
#   # mineral
#   fd<-fd %>%
#     mutate(
#       ca.kg=dm.kg*(ca.p.dm/100),pho.kg=dm.kg*(p.p.dm/100),mg.kg=dm.kg*(mg.p.dm/100),cl.kg=dm.kg*(cl.p.dm/100),
#       k.kg=dm.kg*(k.p.dm/100),na.kg=dm.kg*(na.p.dm/100),sulf.kg=dm.kg*(s.p.dm/100)
#       # ,co.mg=dm.kg*co.ppm.dm,cu.mg=dm.kg*cu.ppm.dm,i.mg=dm.kg*i.ppm.dm,fe.mg=dm.kg*fe.ppm.dm,mn.mg=dm.kg*mn.ppm.dm,se.mg=dm.kg*se.ppm.dm,zn.mg=dm.kg*zn.ppm.dm
#     )
#   
#   # vitamin
#   # fd<-fd %>%
#   #   mutate(vit_a.1000iu=dm.kg*vit_a.1000iu.kg,vit_d.1000iu=dm.kg*vit_d.1000iu.kg,vit_e.iu=dm.kg*vit_e.iu.kg)
#   
#   nutrients_sum<-fd %>%
#     # summarise_at(vars(af.kg:vit_e.iu),sum) if micro nutrients are to be considered
#     summarise_at(vars(af.kg:sulf.kg),sum)
#   
#   # dietary concencentration % DM
#   diet_nutrients<-nutrients_sum/nutrients_sum$dm.kg*100
#   
#   # Replace intakes to the amount in kg
#   diet_nutrients[1]<- nutrients_sum[2]
#   diet_nutrients[2]<- nutrients_sum[2]/nutrients_sum[1]*100
#   
#   # Replace the column names of diet nutrient composition to be consistent with the model variables
#   names(diet_nutrients)<-c("target_dmi","diet_dm.p.af","diet_forage.p","diet_om.p","diet_nfc.p","diet_ndf.p",
#                            "diet_fndf.p","diet_adf.p","diet_cf.p","diet_lignin.p","diet_cp.p","diet_solp.p",
#                            "diet_npn.p","diet_ndicp.p","diet_adicp.p","diet_ee.p","diet_ash.p","diet_pndf.p","diet_tdn1x.p","diet_starch.p",
#                            "diet_ca.p","diet_phos.p","diet_mg.p","diet_cl.p","diet_k.p","diet_na.p","diet_sulf.p")
#   
#   
#   # calculate DCAB1(simple; Ender et al., 1971) and DCAB2(complex; Goff et al., 1997)
#   # according to NRC, coefficient of sulfur is 0.6 instead of 0.25
#   # The equations should be checked again
#   
#   diet_nutrients<-diet_nutrients %>%
#     mutate(diet_dcad1.meq.100g=(435*diet_na.p+256*diet_k.p)-(282*diet_cl.p+624*diet_sulf.p),
#            diet_dcad2.meq.100g=(453*diet_na.p+256*diet_k.p+0.15*500*diet_ca.p+0.15*823*diet_mg.p)-(282*diet_cl.p+0.25*624*diet_sulf.p+0.5*968*diet_phos.p))
#   
#   # Round to two decimals
#   diet_nutrients<-round(diet_nutrients,2)
#   
#   # Return diet nutrients composition and revised feed_data as a list
#   return(list(diet_nutrients=diet_nutrients,feed_data=fd))
#   
# }






#   
# # Calculation of dietary nutrient concentration


# target_dmi
# diet_dm.p.af
# diet_forage.p
# diet_om.p
# diet_nfc.p
# diet_ndf.p
# diet_fndf.p
# diet_adf.p
# diet_cf.p
# diet_lignin.p
# diet_cp.p
# diet_solp.p
# diet_npn.p
# diet_ndicp.p
# diet_adicp.p
# diet_ee.p
# diet_ash.p
# diet_pndf.p
# diet_tdn1x.p
# diet_starch.p
# diet_ca.p
# diet_phos.p
# diet_mg.p
# diet_cl.p
# diet_k.p
# diet_na.p
# diet_sulf.p
# diet_dcad1.meq.100g
# diet_dcad2.meq.100g




# diet_lignin.p.ndf
# diet_co.ppm
# diet_cu.ppm
# diet_iod.ppm
# diet_fe.ppm
# diet_mn.ppm
# diet_se.ppm
# diet_zn.ppm
# diet_vita.1000iu.p.kg
# diet_vitd.1000iu.p.kg
# diet_vite.iu.p.kg
# diet_sugar.p
# diet_lactic.p
# diet_acetic.p
# diet_propionic.p
# diet_butyric.p
# diet_isobutyric.p
# diet_cho_a.p
# diet_cho_b1.p
# diet_cho_b2.p
# diet_cho_c.p
# diet_prt_a.p
# diet_prt_b1.p
# diet_prt_b2.p
# diet_prt_b3.p
# diet_prt_c.p
# diet_phos.g




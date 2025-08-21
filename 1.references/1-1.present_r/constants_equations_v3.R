
# last updated on 20240805

###############################################################################
# coeffcicients

ref_shrunk_bw<-478

# BW to SBW
q_FBW_SBW<-0.96

# SBW to EBW
q_SBW_EBW<-0.891

# ADG to SWG(shrunk weight gain)
q_ADG_SWG <- 1

# SWG to EWG(empty weight gain)
q_SWG_EWG <- 0.956


# MCP to MP
q_MCP_MP<-0.64

# RUP to MP
q_RUP_MP<-0.80

# days per month
month.day<-30.4

# average length of pregancy of cattle 
pregnancy.day<-283

# milk crude protein to true protein NASEM(2024)
milk_cp_tp<-0.951

###############################################################################

###############################################################################
# Reference values

# age at first calving 2023년 검정우 평균
age_at_first_calving<-26.8

# calving interval 2024년 검정우 평균
ci.month<-447.7/30.4

# 305일 유량 2024년 검정우 평균
rha_KDIA<-10159

# milk yield 2024년 검정우 평균
ref_milk_yield.kg<-rha_KDIA/305
  
# milk fat 2024년 검정우 평균
ref_milk_fat.p<-4.02
  
# milk cp 2024년 검정우 평균
ref_milk_cp.p<-3.22
ref_milk_tp.p<-ref_milk_cp.p*milk_cp_tp




###############################################################################


###############################################################################
# tables

# average body weight of each physiological stage
ave_bw_stage<-c("calf"=75,
                "growing"=374,
                "fattening"=500,
                "lactating"=700,
                "drying"=700
)
# mature body weight
mbw_matrix<-c("hanwoo heifer"= 474,
              "hanwoo cow" = 474,
              "hanwoo steer" = 700,
              "holstein heifer" = 700,
              "holstein cow" = 700,
              "holstein steer" = 800
)

# calf birth weight by breed_name
cbw_matrix<-c("hanwoo"= 26,
              "holstein" = 43
)

# target frame by breed
target_frame<-list("hanwoo"=c(0.6,0.8,0.92,0.96,1),
                   "holstein"=c(0.55,0.82,0.92,1,1))

# fasting heat production coefficient
# for each breed c(calf, growing, fattening,lactating,drying)
# Based on Fox et al. (2004)
# Angus, Charolais, Hereford and most other beef breed 0.070
# lactating beef cows 20% increase
fhp_breed_table<-list("hanwoo" = c("calf" = 0.07, "growing" = 0.07, "fattening" = 0.07,"lactating" = 0.084,"drying"=0.07),
                "holstein" = c("calf" = 0.078, "growing" = 0.078, "fattening" = 0.078,"lactating" = 0.073,"drying"=0.078))
   
# activity code table
activity_code<-data.frame(
  standing_hour= c(12,12,15,15,15),
  position_change= c(6, 9, 9, 9, 9),
  flat_distance= c(0, 500, 1000, 1500, 1500),
  slope_distance= c(0, 1, 1, 1, 1)
)



#################################################################


###############################################################################
# List of equations as functions
###############################################################################

##################################################
##    Calculating additional animal inputs      ##
##################################################

add_animal_inputs<-function(input_data){
  input_data_rev<-input_data %>% 
    mutate(shrunk_bw = round(full_bw*q_FBW_SBW,0), empty_bw = round(shrunk_bw*q_SBW_EBW,0)) %>%
    mutate(mature_shrunk_bw=round(mature_bw*q_FBW_SBW,0)) %>% 
    mutate(eq_shrunk_bw=round(shrunk_bw*(ref_shrunk_bw/mature_shrunk_bw),1), eq_empty_bw=round(eq_shrunk_bw*q_SBW_EBW,0)) %>%
    mutate(lact_no=max((age.month-tca.month)%/%ci.month,0)) %>% 
    mutate(bcs_dairy=(bcs_beef+1)/2)
  
  return(input_data_rev)
}

###################
##    GE         ##
###################


GE_basic<-function(ndf.p.dm,cp.p.dm,ee.p.dm,nfc.p.dm){
  GE<-(9.4*ee.p.dm+5.65*cp.p.dm+4.2*(ndf.p.dm+nfc.p.dm))/100

return(round(GE,2))
}


###################
##    TDN1x      ##
###################


TDN1x_CNCPS_L1<-function(feed_class,conc.p,forage.p,ndf.p.dm,lignin.p.dm,cp.p.dm,ndicp.p.dm,adicp.p.dm,ash.p.dm,ee.p.dm,fa.p.dm,dfa.p.fa=73){
  # function that calculate TDN1x based on the CNCPS Level 1 solution (Fox et al., 2004)
  
  # updated on 20240731 by Seo according to the feed library v3
  # inputs needed are 
  # conc.p - concentrate as a percentage of DM # normally conc.p is 100 or 0
  # forage.p - forage as a percenage of DM # However, something like beet pulp should be revisited 
  # ndf.p.dm - ndf as a percentage of DM
  # lignin.p.dm - lignin as a percentage of DM
  # cp.p.dm - CP as a percentage of DM
  # ndicp.p.dm - NDICP as a percentage of DM
  # adicp.p.dm - ADICP as a percentage of DM
  # ee.p.dm - EE as a percentage of DM
  # ash.p.dm - Ash as a percentage of DM
  # 지방산의 소화율을 평균 73%로 낮추었기 때문에 사료라이브러리보다 값이 낮다
  
  
  # indigestible ADCIP as a percentage of DM
  iadicp.p.dm<- forage.p/100*(adicp.p.dm/100)*0.7+conc.p/100*(adicp.p.dm/100)*0.4
  
  # nitrogen corrected ndf based on CNCPS v5
  ndfn.p.dm<-ndf.p.dm - (ndicp.p.dm/100) + iadicp.p.dm # nitrogen corrected ndf
  
  # true digestible NFC
  dNFC<-0.98*(100-ndfn.p.dm-cp.p.dm-ash.p.dm-ee.p.dm+iadicp.p.dm)
  dNFC[dNFC<=0]<-0
  # cat("\ndNFC =",dNFC,"\n")
  
  # true digestible EE
  # the coefficient of 2.25 is used based on RNS(Tedeschi and Fox, 2021) and NRC(2001)
  # 20240603: Fatty acid content of forage is crude fat * 0.5678; otherwise, crude fat - 1 (NASEM 2021)
  # fatty_acid<-ee.p.dm-1
  # fatty_acid[fatty_acid<=0]<-ee.p.dm[fatty_acid<=0]
  # # fatty_acid[forage.pfeed_class=="1_forage"]<-ee.p.dm[feed_class=="1_forage"]*0.5678
  # fatty_acid[forage.p==100]<-ee.p.dm[forage.p==100]*0.5678
  
  fatty_acid<-fa.p.dm
  
  # Modified on 20240731 by SEo based on NASEM 2021
  # 지방의 소화율 대신 지방산의 소화율로 계산하고, 그 소화율을 100으로 보지 않고
  # 만약 수치가 있다면 (NASEM feed library) 그 수치를 이용하고 아니면 73% 가정
  dEE<-fatty_acid*dfa.p.fa/100
  # cat("\ndEE =",dEE,"\n")
  
  # true digestible CP
  dCP<-(forage.p/100*exp(-0.012*adicp.p.dm/cp.p.dm*100)+conc.p/100*(1-0.004*adicp.p.dm/cp.p.dm*100))*cp.p.dm
  dCP[dCP<=0]<-0
  dCP[is.nan(dCP)]<-0
  # cat("\ndCP =",dCP,"\n")
  
  
  # true digestible ndf
  dndfn<-0.75*(ndfn.p.dm-lignin.p.dm)*(1-(lignin.p.dm/ndfn.p.dm)^(2/3))
  dndfn[dndfn<=0]<-0
  dndfn[is.nan(dndfn)]<-0
  # cat("\ndndfn =",dndfn,"\n")
  
  # apparent TDN
  TDN1x<-dNFC+dCP+2.25*dEE+dndfn-7
  
  # if feed_class is lipid
  # Based on NRC(2001): 
  # calcium salts of fatty acids - 0.86,
  # hydrolyzed tallow fatty acids - 0.79
  # partially hydrogenated tallow - 0.43
  # tallow - 0.68
  # vegetable oil - 0.86
  # assume mean value is 0.8
  # dEE is already calculated by 2.25 times fatty acid 
  # TDN1x[feed_class=="3_lipid"]<-2.25*dEE[feed_class=="3_lipid"]*0.8
  # NRC 2001에서는 Lipid에 대해서만 지방산의 소화율 보정하였지만, 
  # NASEM 2021년에서는 DE 계산 시 모든 지방산의 소화율을 자료가 없으면 73%로 보정
  
  # if feed_class is additives  
  TDN1x[feed_class=="7_additives"]<-0
  TDN1x[TDN1x<=0]<-0
  
  # cat("\nTDN1x =",TDN1x,"\n")
  # TDN1x[is.nan(TDN1x)]<-0
  
  return(round(TDN1x,2))
}

################################
##    Discount TDN (dTDN)     ##
################################

dTDN_NRC_dairy_2001<-function(TDN,dmi_factor){
  DiscountVariable<-((0.18*TDN)-10.3)*dmi_factor
  Discount<-(TDN-DiscountVariable)/TDN
  Discount[TDN<60]<-1
  dTDN<-TDN*Discount
  return(dTDN)
}



###############
##    DE     ##
###############

TDN_to_DE_CNCPS_L1<-function(TDN){
  DE<-4.409*TDN/100
  return(round(DE,2))
}  


#####################
##    DE->ME       ##
#####################
DE_to_ME_NRC_beef<-function(DE){
  ME<-0.82*DE
  return(round(ME,2))
}

DE_to_ME_NRC_dairy_2001<-function(DE,feed_class,stage_name,ee.p.dm){
  if(stage_name %in% c("lactating","drying")){
    ME<-(1.01*DE)-0.45
    ME[ee.p.dm>=3]<-(1.01*DE[ee.p.dm>=3])-0.45+(0.0046*(ee.p.dm[ee.p.dm>=3]-3))
  }else if(stage_name == "calf"){
    ME<-0.82*DE # should be changed
  }else{ # growing and fattening
    ME<-0.82*DE
  }
  ME[DE<=0]<-0
  ME[feed_class == "3_lipid"]<-DE[feed_class == "3_lipid"]
  return(round(ME,2))
}


#####################
##    ME->NE       ##
#####################

ME_to_NEm_NRC_beef<-function(ME){
  NEm<-1.37*ME-0.138*ME^2+0.0105*ME^3-1.12
  NEm[NEm<=0]<-0
  return(round(NEm,3))
} 
ME_to_NEg_NRC_beef<-function(ME){
  NEg<-1.42*ME-0.174*ME^2+0.0122*ME^3-1.65
  NEg[NEg<=0]<-0
  return(round(NEg,3))
} 
ME_to_NEl_NRC_beef<-function(ME){
  NEl<-0.644*ME
  return(round(NEl,3))
} 

ME_to_NEl_NRC_dairy_2001<-function(ME,feed_class,ee.p.dm){
  NEl<-0.703*ME-0.19
  
  #####################################################################
  # the following statements generate the following error message
  #  number of items to replace is not a multiple of replacement length 
  #
  # NEl[ee.p.dm>=3]<-0.703*ME-0.19+((((0.097*ME)+0.19)/97)*(ee.p.dm-3))
  #
  #####################################################################
  
  NEl[ee.p.dm>=3]<-0.703*ME[ee.p.dm>=3]-0.19+((((0.097*ME[ee.p.dm>=3])+0.19)/97)*(ee.p.dm[ee.p.dm>=3]-3))
  
  NEl[ME<=0]<-0
  NEl[feed_class == "3_lipid"]<-0.8*ME[feed_class == "3_lipid"]
  return(round(NEl,3))
}

ME_to_NEm_NRC_dairy_2001<-function(ME,feed_class){
  NEm<-1.37*ME-0.138*ME^2+0.0105*ME^3-1.12
  NEm[ME<=0]<-0
  NEm[feed_class == "3_lipid"]<-0.8*ME[feed_class == "3_lipid"]
  return(round(NEm,3))
} 

ME_to_NEg_NRC_dairy_2001<-function(ME,feed_class){
  NEg<-1.42*ME-0.174*ME^2+0.0122*ME^3-1.65
  NEg[ME<=0]<-0
  NEg[feed_class == "3_lipid"]<-0.55*ME[feed_class == "3_lipid"]
  return(round(NEg,3))
}


####################
##    RUP1x       ##
####################

#old version
# RUP1x_CNCPS_L1<-function(feed_class,conc.p,forage.p,cp.p.dm,solp.p.cp,npn.p.solp,ndicp.p.cp,adicp.p.cp,p_a.p.hr,p_b1.p.hr,p_b2.p.hr,p_b3.p.hr,p_c.p.hr){
#   # function that calculate RUP1x
#   # First, determine proportion of protein fractions (A,B1,B2,B3,C)
#   p_a<-npn.p.solp*solp.p.cp/100 # protein fraction A (% CP)
#   p_c<-adicp.p.cp #protein fraction C (% CP)
#   p_b1<-solp.p.cp - p_a # protein fraction B1 (% CP)
#   p_b3<-ndicp.p.cp-p_c # protein fraction B3 (% CP) 
#   p_b2<-100 - ndicp.p.cp-solp.p.cp # protein fraction B2 (% CP) 
#   p_b2[p_b2<=0]<-0 # if protein fraction B2 is equal to or less than 0 then assign 0
#   
#   ##############################
#   # basal forage and concentrate Kp at the level of maintenance intake 
#   # Based on table 1 in Seo et al (2006)
#   # The mean DMI (% BW) was 2.6%, kp_forage was 3.9%/h and Kp_concentrate was 5.3%/h
#   # Although the level of intake is a little higher, the Kps are similar to those are assumed when calculating In situ ERD
#   kp_forage<-3.9
#   kp_conc<-5.3
#   ##############################
#   
#   RUP1x<-rep(0,length(p_a))
#   
#   for (i in 1:length(p_a)){
#     p_fraction<-c(p_a[i],p_b1[i],p_b2[i],p_b3[i],p_c[i])
#     # print(p_fraction)
#     p_kd<-c(p_a.p.hr[i],p_b1.p.hr[i],p_b2.p.hr[i],p_b3.p.hr[i],p_c.p.hr[i])
#     # print(p_kd)
#     RUP1x[i]<-sum(p_fraction*(1-(p_kd/(p_kd+(forage.p[i]*kp_forage+conc.p[i]*kp_conc)/100))))
#     if (cp.p.dm[i]==0){RUP1x[i]<-0}
#   }
#   return(RUP1x)
# }

# v3 with all nutrients are expressed in a DM basis
# snpn.p.dm as an input to assign RUP 0 for NPN supplement

RUP1x_CNCPS_L1<-function(feed_class,conc.p,forage.p,cp.p.dm,solp.p.dm,ndicp.p.dm,adicp.p.dm,p_a.p.hr,p_b1.p.hr,p_b2.p.hr,p_b3.p.hr,p_c.p.hr,snpn.p.cp){
  # function that calculate RUP1x
  # First, determine proportion of protein fractions (A,B1,B2,B3,C)
  solp.p.cp<-solp.p.dm/cp.p.dm*100
  ndicp.p.cp<-ndicp.p.dm/cp.p.dm*100
  adicp.p.cp<-adicp.p.dm/cp.p.dm*100
  
  p_a<-rep(0,length(solp.p.cp)) # protein fraction A (% CP)
  p_c<-adicp.p.cp #protein fraction C (% CP)
  p_b1<-solp.p.cp # protein fraction B1 (% CP)
  p_b3<-ndicp.p.cp-p_c # protein fraction B3 (% CP) 
  p_b2<-100 - ndicp.p.cp-solp.p.cp # protein fraction B2 (% CP) 
  p_b2[p_b2<=0]<-0 # if protein fraction B2 is equal to or less than 0 then assign 0
  
  ##############################
  # basal forage and concentrate Kp at the level of maintenance intake 
  # Based on table 1 in Seo et al (2006)
  # The mean DMI (% BW) was 2.6%, kp_forage was 3.9%/h and Kp_concentrate was 5.3%/h
  # Although the level of intake is a little higher, the Kps are similar to those are assumed when calculating In situ ERD
  kp_forage<-3.9
  kp_conc<-5.3
  ##############################
  
  RUP1x<-rep(0,length(p_a))
  # print(length(p_a))
  for (i in 1:length(p_a)){
    p_fraction<-c(p_a[i],p_b1[i],p_b2[i],p_b3[i],p_c[i])
    # print(p_fraction)
    p_kd<-c(p_a.p.hr[i],p_b1.p.hr[i],p_b2.p.hr[i],p_b3.p.hr[i],p_c.p.hr[i])
    # print(p_kd)
    RUP1x[i]<-sum(p_fraction*(1-(p_kd/(p_kd+(forage.p[i]*kp_forage+conc.p[i]*kp_conc)/100))))
    if (cp.p.dm[i]==0){RUP1x[i]<-0}
    if (is.na(snpn.p.cp[i]) || snpn.p.cp[i]>0){RUP1x[i]<-0}
    # print(RUP1x[i])
    # if (is.nan(RUP1x[i])){RUP1x[i]<-0}
    
  }
 
  return(RUP1x)
}

####################
##    RUPxx       ##
####################

RUPxx_CNCPS_L1<-function(feed_class,conc.p,forage.p,RUP1x,DMI_factor){
  # function that calculate RUPxx according to DMI_factor
  # based on CNCPS Level 1
  RUPxx_conc<-0.097 + 1.01*RUP1x + 4.47*DMI_factor + 0.058*RUP1x*DMI_factor
  RUPxx_forage<-0.167 + RUP1x + 4.3*DMI_factor - 0.032*RUP1x*DMI_factor
  RUPxx<-(RUPxx_conc*conc.p+RUPxx_forage*forage.p)/100
  RUPxx[RUP1x<=0]<-0
  RUPxx[RUP1x>=100]<-100
  return(RUPxx)
}

RUP35_NASEM2021_L1<-function(snpn.p.cp,conc.p,forage.p,cp.p.dm,insitu_p_a.p.cp,insitu_p_b.p.cp,insitu_p_c.p.cp,insitu_p_b.p.hr){
  # function that calculate RUP
  # 각각의 사료에 대해서는 rup1x.p.cp의 값과 동일해야 함. 
  # NASEM의 RUP는 표준 동물 (BW 650kg, DMI 23kg(3.5% BW))의 RUP이므로 이미 RUP3.5라 할 수 있다
  # NASEM (2021) p73
  rum_dp_a<-93.6 # protein A fraction의 반추위 소화율
  rup_a<-(100-rum_dp_a)/100*(100-snpn.p.cp)/100*insitu_p_a.p.cp # (100-반추위 분해율)*(supplement NPN이 아닌 A)
  ##############################
  # static passage rate
  # Based on table 1 in Seo et al (2006)
  # kp_forage<-3.9
  # kp_conc<-5.3
  
  # based on the NASEM 2021
  kp_forage<-4.87
  kp_conc<-5.28
  ##############################
  
  kp_feed<-(forage.p*kp_forage+conc.p*kp_conc)/100
  rup_b<- insitu_p_b.p.cp*kp_feed/(kp_feed+insitu_p_b.p.hr)
  
  rup_c<-insitu_p_c.p.cp
  
  rup35<-rup_a+rup_b+rup_c
  
  rup35[rup35<=0]<-0
  rup35[is.na(rup35)]<-0
  
  return(rup35)
}

RDP35_NASEM2021_L1<-function(snpn.p.cp,conc.p,forage.p,cp.p.dm,insitu_p_a.p.cp,insitu_p_b.p.cp,insitu_p_c.p.cp,insitu_p_b.p.hr){
  # function that calculate RUP
  # 각각의 사료에 대해서는 rup1x.p.cp의 값과 동일해야 함. 
  # NASEM의 RUP는 표준 동물 (BW 650kg, DMI 23kg(3.5% BW))의 RUP이므로 이미 RUP3.5라 할 수 있다
  # NASEM (2021) p73
  rum_dp_a<-93.6 # protein A fraction의 반추위 소화율
  rdp_a<-rum_dp_a/100*insitu_p_a.p.cp # (100-반추위 분해율)*(supplement NPN이 아닌 A)
  ##############################
  # static passage rate
  # Based on table 1 in Seo et al (2006)
  # kp_forage<-3.9
  # kp_conc<-5.3
  
  # based on the NASEM 2021
  kp_forage<-4.87
  kp_conc<-5.28
  ##############################
  
  kp_feed<-(forage.p*kp_forage+conc.p*kp_conc)/100
  rdp_b<- insitu_p_b.p.cp*insitu_p_b.p.hr/(kp_feed+insitu_p_b.p.hr)
  
  rdp35<-rdp_a+rdp_b
  
  rdp35[rdp35<=0]<-0
  rdp35[is.na(rdp35)]<-0
  
  return(rdp35)
}



###############################
##    MP from bacteria       ##
###############################

MP_Bacteria_NRC_dairy_2001<-function(dtdn.p){
  microbial_CP<-dtdn.p/100*1000*0.13
  MPfromBacteria<-microbial_CP*q_MCP_MP
  return(MPfromBacteria)
}




########################
##    MP from RUP     ##
########################

MP_RUP_NRC_dairy_2001<-function(rupx.p.cp,cp.p.dm){
  rupx.g<-(rupx.p.cp/100)*cp.p.dm/100*1000
  MPfromRUP<-rupx.g*q_RUP_MP
  return(MPfromRUP)
}

MP_RUP_NRC_NASEM_2021<-function(rupx.p.cp,cp.p.dm,drup.p.rup){
  rupx.g<-(rupx.p.cp/100)*cp.p.dm/100*1000
  drup.p.rup[is.na(drup.p.rup)]<-0
  MPfromRUP<-rupx.g*drup.p.rup/100
  return(MPfromRUP)
}


##############################
##    intake prediction     ##
##############################

# 4% fat corrected milk
fat4_cor_milk<-function(milk_yield,milk_fat){
  FCM<-milk_yield*(0.4+15*milk_fat/100)
  return(FCM)
}

# conceptus weight  
conceptus<-function(calf_bw,preg.day){
  if(preg.day>=190){
    CpW = (calf_bw/45)*(18+((preg.day-190)*0.665))
  }else if(preg.day>0){
    CpW = (calf_bw*0.01828)*(exp(0.02 * preg.day - 0.0000143*preg.day^2))
  }else{
    CpW = 0
  }
}

# lag in milk production during early lactation
milk_lag<-function(milk.day){
  wol<-ceiling(milk.day/7)
  peak_milk.month<-1
  peak_lag<-2.36 # if peak_milk.month >= 3, 3.67 
  
  if(wol>0 && wol<=16){
    lag<-1-exp(-(0.564-0.124*peak_milk.month)*(wol+peak_lag))
  } else {lag<-1}
  
  return(lag)
}


# effective temperature index
eff_temp_index<-function(temp,humid,wind,radiation){
  eti = 27.88-(0.456*temp)+(0.010754*temp^2)-(0.4905*humid)+0.00088*humid^2+(1.1507*1000/3600*wind)-(0.126447*(1000/3600*wind)^2)+(0.019876*temp*humid)-(0.046313*temp*1000/3600*wind)+(0.4167*radiation)  
  return(eti)
}


# DMI adjustment factor for temperature
dmi_temp_adj<-function(temp_cur,eff_temp_index_cur,no_cooling_night){
  dmi_nc_adj<-(119.62-0.9708*eff_temp_index_cur)/100
  if(temp_cur< (-20)){
    dmi_temp_adj<-1.16
  }else if(temp_cur< 20){
    dmi_temp_adj<-1.0433-0.0044*temp_cur+0.0001*temp_cur^2
  }else if(no_cooling_night){
    dmi_temp_adj<-dmi_nc_adj
  }else{
    dmi_temp_adj<-(1-dmi_nc_adj)*0.75+dmi_nc_adj
  }
}

# DMI adjustment factor for mud depth
dmi_mud_adj<-function(mud_depth){
  dmi_mud_adj<-1-0.01*mud_depth
  return(dmi_mud_adj)

}

# DMI adjustment factor for last month of gestation
dmi_gest_adj<-function(preg.day){
  dmi_gest_adj<-ifelse(preg.day>=260,0.8,1)
  return(dmi_gest_adj)
  
}

# DMI adjustment factor for beef cattle 
dmi_beef_adj<-function(breed_name,stage_name,gender,eq_shrunk_bw){
  
  if(breed_name=="hanwoo"){
    dmi_beef_adj<-1
  }else if(gender == "steer" || stage_name == "fattening"){
    dmi_body_fat_adj<-0.7714+0.00196*eq_shrunk_bw-0.00000371*eq_shrunk_bw^2
    if(breed_name=="holstein"){
      dmi_breed_adj<-1.08
    }else{dmi_breed_adj<-1.04}
    dmi_beef_adj<-dmi_body_fat_adj*dmi_breed_adj
  }else{dmi_beef_adj<-1}
  return(dmi_beef_adj)
}
  
# DMI prediction equations for Hanwoo - based on Japanese Feeding Standard (National Greenhouse Gas Inventory Report of Japan, 2015)
# 20220522 - 번식우와 암소의 구분 확인 필요
DMI_Hanwoo<-function(gender,full_bw,target_adg){
  if(gender=="steer"){
    DMI=-3.481+2.668*target_adg+4.548*10^(-2)*full_bw-7.207*10^(-5)*full_bw^2+3.867*10^(-8)*full_bw^3
  }else if(gender=="cow"){
    DMI=(0.1108*full_bw^0.75+(0.0609*full_bw^0.75*target_adg)/(0.78*(0.5018+0.0956*target_adg)+0.006))/((0.5018+0.0956*target_adg)*4.4)
  }else{
    DMI=(0.1067*full_bw^0.75+(0.0639*full_bw^0.75*target_adg)/(0.78*(0.4213+0.1491*target_adg)+0.006))/((0.4213+0.1491*target_adg)*4.4)
  }
  return(DMI)
}
  
DMI_Holstein_non_lact_CNCPS<-function(stage_name,age.month,full_bw,target_adg,diet_nem.mcal.kg,calf_bw,preg.day){
  
  shrunk_bw<-full_bw*q_FBW_SBW
  conceptus<-conceptus(calf_bw,preg.day)
  nem_div<-ifelse(diet_nem.mcal.kg<1,0.95,diet_nem.mcal.kg)
  dmi_gest_adj<-dmi_gest_adj(preg.day)
  
  if(age.month<12){
    # different equation for calf needed
    if(stage_name=="calf"){
      
    }else{}
    DMI<-shrunk_bw^0.75*((0.2435*diet_nem.mcal.kg-0.0466*diet_nem.mcal.kg^2-0.1128)/nem_div)
  }else{
    SBW_preg<-shrunk_bw-conceptus
    if(stage_name=="drying"){
      DMI<- 0.02*SBW_preg*dmi_gest_adj
    }else{
      DMI<-SBW_preg^0.75*((0.2435*diet_nem.mcal.kg-0.0466*diet_nem.mcal.kg^2-0.0869)/nem_div)*dmi_gest_adj
    }
  }
  return(DMI)
}

DMI_Holstein_lact_KFS<-function(stage_name,full_bw,milk_yield,milk_fat,milk.day,diet_ndf.p){
  fat4_cor_milk<-fat4_cor_milk(milk_yield,milk_fat)
  milk_lag<-milk_lag(milk.day)
  DMI = (4.103+0.112*full_bw^0.75+0.284*fat4_cor_milk-0.119*diet_ndf.p)*milk_lag
  return(DMI)
}

##############################################
##    Maintenance Nutrient Requirements     ##
##############################################

# compensatory growth adjustments

compensatory_adj_fn<-function(bcs_beef){
  compensatory_adj<-0.8+(bcs_beef-1)*0.05
  return(compensatory_adj)
}

# compensatory growth adjustments

prev_temp_adj_fn<-function(eff_temp_index_past){
  prev_temp_adj <- ((88.426-(0.758*eff_temp_index_past)+(0.0116*eff_temp_index_past^2))-77)/1000
  return(prev_temp_adj)
}

# actaivity adjustments

nem_act_fn<-function(activity,full_bw){
    nem_act<-(0.1*activity$standing_hour+0.062*activity$position_change+0.621*activity$flat_distance/1000+6.69*activity$slope_distance/1000)*full_bw/1000
    return(nem_act)
}

# surface area
surface_area_fn<-function(shrunk_bw){
  surface_area<-0.09*(shrunk_bw^0.67)
}




##########################################
##    target growth rate of heifers     ##
##########################################

target_heifer_adg<-function(breed,stage,gender,fbw,mbw,age.month,tca.month,ci.month,preg.day){
  # target = (conception, 1st calving, 2nd calving, 3rd calving, 4th calving)
  
  if(stage == "fattening" || gender == "steer"){
    target_heifer_adg<-0
  }else{
    target<-target_frame[[breed]]
    target_BW<-target*mbw
    target_WG<-target_BW-fbw
    target_day<-c(tca.month*month.day-pregnancy.day,
                  tca.month*month.day,
                  tca.month*month.day+ci.month*month.day,
                  tca.month*month.day+2*ci.month*month.day,
                  tca.month*month.day+3*ci.month*month.day
    )
    target_day_left<-target_day-age.month*month.day
    target_dailygain<-target_WG/target_day_left
    
    # find the next stage
    status<-target_day_left/(ci.month*month.day)
    target_stage<-which(status>=0&status<1)
    
    # if the heifer is pregnant although the age is earlier than
    # the targeted conception day
    # Assign the next target to the first calving
    if (age.month*month.day<target_day[2]){
      if (age.month*month.day<target_day[1] & preg.day==0){
        target_stage<-1
      }else{
        target_stage<-2
      }
    }
    target_heifer_adg<-target_dailygain[target_stage]
  }
  return(target_heifer_adg)
}


###############################################################################



# #=================#
# # Input Data List #   
# #=================#
# 
# breed_name = breed_table[[breed_code]][1]
# animal_type_name = animal_type_list[animal_type+1]
# sex_name = sex_code_list[sex]
# breed_type_name = breed_type_list[breed_type]
# additional_treat_name = additional_treat_code_list[additive]
# 
# Feeding_method_name = feed_method_list[Feeding_method]
# calf_implanted_name = implant_tag_list[calf_implanted]
# 
# HCcode_name = hair_condition_list[HCcode]
# 
# cowshed_code_name = cowshed_list[cowshed_code]
# standing_hour = standing_hour_list[cowshed_code]
# position_change = position_change_list[cowshed_code]
# flat_distance = flat_distance_list [cowshed_code]
# slop_distance = slop_distance_list[cowshed_code]
# 
# 


  

# # Calculation of dietary nutrient concentration

# diet_composition 
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



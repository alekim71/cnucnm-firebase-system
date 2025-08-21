
########################
# Check CNUCNM version #
########################

# last updated on 20240805
# snpn.p.dm -> snpn.p.cp
# by Seo


check_FL<-function(feed_data, version){

  # Variable names in the CNUCNM Feed library version 2
  # The first column is the amount of each ingredient in kg
  # fractions: CHO A, B1, B2, B3, C; PRT A, B1, B2, B3, C
  
  FL2_names<-c("AF","feed_no","feed_name","feed_class","price","conc.p","forage.p","dm.p.af",
               "ndf.p.dm","adf.p.dm","cf.p.dm","lignin.p.ndf",
               "cp.p.dm","solp.p.cp","npn.p.solp","ndicp.p.cp","adicp.p.cp",
               "starch.p.nfc","ee.p.dm","ash.p.dm","pndf.p.ndf",
               "cho_a.p.hr","cho_b1.p.hr","cho_b2.p.hr","cho_b3.p.hr","cho_c.p.hr",
               "p_a.p.hr","p_b1.p.hr","p_b2.p.hr","p_b3.p.hr","p_c.p.hr",
               "id_cho_a.p","id_cho_b1.p","id_cho_b2.p","id_cho_b3.p","id_cho_c.p",
               "id_p_a.p","id_p_b1.p","id_p_b2.p","id_p_b3.p","id_p_c.p","id_ee.p","id_ash.p",
               "met.p.uip","lys.p.uip","arg.p.uip","thr.p.uip","leu.p.uip","ile.p.uip","val.p.uip","his.p.uip","phe.p.uip","trp.p.uip",
               "tdn.p.dm","me.mcal.kg","nem.mcal.kg","neg.mcal.kg","rup3x.p.cp","rup1x.p.cp",
               "ca.p.dm","p.p.dm","mg.p.dm","cl.p.dm","k.p.dm","na.p.dm","s.p.dm",
               "co.ppm.dm","cu.ppm.dm","i.ppm.dm","fe.ppm.dm","mn.ppm.dm","se.ppm.dm","zn.ppm.dm",
               "vit_a.1000iu.kg","vit_d.1000iu.kg","vit_e.iu.kg",
               "ca_bio","p_bio","mg_bio","cl_bio","k_bio","na_bio","s_bio","co_bio","cu_bio","i_bio","fe_bio","mn_bio","se_bio","zn_bio",
               "vit_a_bio","vit_d_bio","vit_e_bio",
               "starch.p.dm","sugar.p.dm","lactic.p.dm","acetic.p.dm","propionic.p.dm","butyric.p.dm","isobutyric.p.dm","ph","ammonia.p.dm")

  FL3_names<-c("AF", "feed_no", "feed_name",	"feed_class",	"price",	"conc.p",	"forage.p",	"dm.p.af",
                    "om.p.dm",	"cp.p.dm",	"solp.p.dm",	"ndicp.p.dm",	"adicp.p.dm",	"cf.p.dm",
                    "ndf.p.dm",	"adf.p.dm",	"lignin.p.dm",	"esc.p.dm",	"wsc.p.dm",	"starch.p.dm",
                    "ee.p.dm",	"ash.p.dm",	"ca.p.dm",	"p.p.dm",	"mg.p.dm",	"k.p.dm",	"s.p.dm",
                    "na.p.dm",	"cl.p.dm",	"fe.ppm.dm",	"mn.ppm.dm",	"zn.ppm.dm",	"cu.ppm.dm",
                    "tdn.p.dm",	"me.mcal.kg",	"nem.mcal.kg",	"neg.mcal.kg",	"nel.mcal.kg",
                    "nfc.p.dm",	"carb.p.dm",	"fa.p.dm",	"snpn.p.cp",	"rom.p.dm",	"ge.mcal.kg",
                    "dndf.lg.p.dm",	"dndf.lg.p.ndf",	"dndf.iv48.p.ndf",	"rup1x.p.cp",	"met.p.uip",
                    "lys.p.uip",	"arg.p.uip",	"thr.p.uip",	"leu.p.uip",	"ile.p.uip",	"val.p.uip",
                    "his.p.uip",	"phe.p.uip",	"trp.p.uip",	"npn.p.solp",	"co.ppm.dm",	"i.ppm.dm",
                    "se.ppm.dm",	"vit_a.1000iu.kg",	"vit_d.1000iu.kg",	"vit_e.iu.kg",	"pndf.p.ndf",
                    "cho_a.p.hr",	"cho_b1.p.hr",	"cho_b2.p.hr",	"cho_b3.p.hr",	"cho_c.p.hr",
                    "p_a.p.hr",	"p_b1.p.hr",	"p_b2.p.hr",	"p_b3.p.hr",	"p_c.p.hr",	"id_cho_a.p",
                    "id_cho_b1.p",	"id_cho_b2.p",	"id_cho_b3.p",	"id_cho_c.p",	"id_p_a.p",
                    "id_p_b1.p",	"id_p_b2.p",	"id_p_b3.p",	"id_p_c.p",	"id_ee.p",	"id_ash.p",
                    "ca_bio",	"p_bio",	"mg_bio",	"cl_bio",	"k_bio",	"na_bio",	"s_bio",	"co_bio",
                    "cu_bio",	"i_bio",	"fe_bio",	"mn_bio",	"se_bio",	"zn_bio",	"vit_a_bio",
                    "vit_d_bio",	"vit_e_bio","sugar.p.dm",	"lactic.p.dm",	"acetic.p.dm",
                    "propionic.p.dm",	"butyric.p.dm",	"isobutyric.p.dm",	"ph",	"ammonia.p.dm"
  )
  
  
  if (version == 2){
    # Check if feed data is based on the feed library version 2
    
    if(ncol(feed_data)<102){
      print("The version of feed data is not compatible with CNUCNM_v2. Please check it!")
      stop()
    }
    
    feed_data_sel<-feed_data[,1:102]
    
    if(!all(FL2_names == names(feed_data_sel))){
      print("The version of feed data is not compatible with CNUCNM_v2. Please check it!")
      stop()
    }
  }else if (version == 3){
    # Check if feed data is based on the feed library version 3
    if(ncol(feed_data)<113){
      print("The version of feed data is not compatible with CNUCNM_v3. Please check it!")
      stop()
    }
    
    feed_data_sel<-feed_data[,1:113]
    
    if(!all(FL3_names == names(feed_data_sel))){
      print("The version of feed data is not compatible with CNUCNM_v3. Please check it!")
      stop()
    }
  }else{
    print("The version of feed data is not compatible with CNUCNM. Please check it!")
    stop()
  }
  
}

check_inputs<-function(input_data){
  
  # Variable names in the CNUCNM version 3 inputs
  
  variables<-c("breed_name","stage_name","gender","age.month","full_bw","preg.day","milk.day",
                 "ci.month","calf_bw","tca.month","mature_bw","bcs_beef","target_adg","milk_yield",
                 "milk_fat","milk_cp","wind.kmh","temp_past","humid_past","temp_cur","humid_cur",
                 "no_cooling_night", "hair_length","mud_depth","hide","hair_condition","panting",
                 "radiation.hr","area_head_code")
  
  
  # Check if feed data is based on the feed library version 3
  if(!all(variables == names(input_data))){
    print("The version of feed data is not compatible with CNUCNM_v3. Please check it!")
    stop()
  }
  # variables == names(input_data)
}
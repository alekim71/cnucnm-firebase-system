#########################################################################
# CNUCNM feed library converter
# by Seo 2022/03/10

library(tidyverse)

load_FL<-function(feed_library){
  dat<-read_csv(file=feed_library)
    
  # classify feeds according to their feed class
  
  feed_class_name<-list()
  
  class_name<-unique(dat$feed_class)
  for (i in class_name){
    dat.sub<-dat %>% 
      filter(feed_class==i)
    feed_class_name[[i]]<-dat.sub$feed_name
    # feed_class_name[[i]]<-dat.sub$feed_name_kor
  }
  return_list<-list(df=dat,feed_list=feed_class_name)
  return(return_list)
}


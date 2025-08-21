#################################################################
# Defining constants

month.day<-30.4
pregnancy.day<-283

# target frame by breed
target_frame<-list("hanwoo"=c(0.6,0.8,0.92,0.96,1),
                   "holstein"=c(0.55,0.82,0.92,1,1))
#################################################################

target_heifer_adg<-function(breed,fbw,mbw,age.month,tca.month,ci.month,preg.day){
  # target = (conception, 1st calving, 2nd calving, 3rd calving, 4th calving)

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
  return(target_dailygain[target_stage])
}


# last updated on 20240805

library(tidyverse)
library(lpSolve)

source("./modlib/constants_equations_v3.R")

# define functions
lp_run<-function(objective_coefficients,feed_nutrient,nutrient_constraints,feed_input){
  
  constraint_matrix <-c()
  constraint_directions <- c()
  constraint_rhs <-c()
  
  # Define the matrix of constraints coefficients
  for (nutrient in names(nutrient_constraints)){
    constraint_matrix <-rbind(constraint_matrix,feed_nutrient[[nutrient]],feed_nutrient[[nutrient]])
    constraint_directions <-c(constraint_directions,">=", "<=")
    constraint_rhs <-c(constraint_rhs, nutrient_constraints[[nutrient]]$min, nutrient_constraints[[nutrient]]$max)
  }
  
  feed_list <- feed_input$feed_name
  initial_content_DM <- feed_input$dm
  content_DM_min <- feed_input$min
  content_DM_max <- feed_input$max
  
  # Add constraints for feed content_DM min and max values
  constraint_matrix <- rbind(constraint_matrix, diag(length(feed_list)), diag(length(feed_list)))
  constraint_directions <- c(constraint_directions, rep(">=", length(feed_list)), rep("<=", length(feed_list)))
  constraint_rhs <- c(constraint_rhs, content_DM_min, content_DM_max)
  
  # Add constraints for the sum of feed content_DM
  constraint_matrix <- rbind(constraint_matrix, rep("1",length(feed_list)))
  constraint_directions <- c(constraint_directions, "=")
  constraint_rhs <- c(constraint_rhs, "100")
  
  # Solve the linear programming problem
  result <- lp("min", objective_coefficients, constraint_matrix, constraint_directions, constraint_rhs)
}


test_constraints <- function(objective_coefficients,feed_nutrient,nutrient_constraints,feed_input) {
  for (i in seq_along(nutrient_constraints)) {
    # Remove constraints one by one
    modified_constraints <- nutrient_constraints[-i]
    
    result <- lp_run(objective_coefficients,feed_nutrient,modified_constraints,feed_input)
    # Check if the solution is optimal
    if (result$status == 0) {
      cat("Optimal solution found by removing constraint:", names(nutrient_constraints)[i], "\n")
    } else {
      cat("Failed to find optimal solution even after removing constraint:", names(nutrient_constraints)[i], "\n")
    }
  }
}


CNUCNM_LP<-function(feed_data_rev,feed_price,feed_input,nutrient_input){
  
  ###########################################################
  # Seo
  # LP를 하기 위한 테이블 구성
  # Feed input matrix 생성
  
  target_dmi <- sum(feed_data_rev$dm.kg)
  
  feed_matrix<-feed_data_rev %>% 
    select(feed_name,AF,dm.p.af, dm.kg, price,cp.p.dm,rupx.p.cp, nfc.p.dm,starch.p.dm,ndf.p.dm,f_ndf.p.dm,forage.p,dtdn.p,me.mcal.kg,mp.g.kg) %>% 
    mutate(dm.af=round(dm.p.af/100,4), dm=round(dm.kg/target_dmi*100,2),cp.dm=round(cp.p.dm/100,4),rupx.dm=round(cp.p.dm/100*rupx.p.cp/100,5),
           starch.dm=round(starch.p.dm/100,4),
           ndf.dm= round(ndf.p.dm/100,4),f_ndf.dm=round(f_ndf.p.dm/100,4),forage.dm=round(forage.p/100,4),
           tdn.dm=round(dtdn.p/100,4),me.mcal.dm=round(me.mcal.kg*target_dmi/100,4),mp.g.dm=round(mp.g.kg*target_dmi/100,2)) %>% 
    select(feed_name,price,cp.dm,rupx.dm, starch.dm,ndf.dm,f_ndf.dm,forage.dm,tdn.dm,me.mcal.dm,mp.g.dm,AF,dm.kg,dm.af,dm)
  
  # feed_matrix_file_name<-sprintf("%s/feed_matrix.csv",output_dir)
  # write_csv(feed_matrix,feed_matrix_file_name)
  
  # feed_input_file_name<-sprintf("%s/feed_input.csv",output_dir)
  # write_csv(feed_input,feed_input_file_name)
  
  
  # construct nutrient matrix for LP
  feed_nutrient<-feed_matrix 
  
  nutrient_constraints <- list()
  for (i in 1:nrow(nutrient_input)) {
    nutrient_name <- nutrient_input$nutrient[i]
    nutrient_min <- nutrient_input$min[i]
    nutrient_max <- nutrient_input$max[i]
    nutrient_constraints[[nutrient_name]] <- list(min = nutrient_min, max = nutrient_max)
  }
  
  # Define the coefficients of the objective function (cost per kg of each feed)
  objective_coefficients <- feed_price
  
  # print(objective_coefficients)
  # print(feed_nutrient)
  # print(nutrient_constraints)
  # print(feed_input)
  
  result <- lp_run(objective_coefficients,feed_nutrient,nutrient_constraints,feed_input)
  
  # 리스트 초기화
  outcome <- list(
    result = character(0),  # 빈 character
    nutrients = list(0),  # 빈 list
    total_price = numeric(0),  # 빈 numeric
    further = character(0),  # 빈 character로 긴 텍스트를 수용할 수 있음
    optimal_DM = numeric(0)  # 빈 numeric 벡터
  )

  # Check if the solution is optimal
  if (result$status == 0) {
    
    outcome[["result"]]<-"succeeded"
    
    # Extract optimal values
    optimal_content_DM <- result$solution
    outcome[["optimal_DM"]]<-optimal_content_DM
    
    unit_prices<-optimal_content_DM/100*target_dmi/feed_matrix$dm.af*feed_matrix$price
    unit_prices[is.nan(unit_prices)]<-0
    total_price <- sum(unit_prices,na.rm = TRUE)
    outcome[["total_price"]]<-total_price
    
    # Calculate the total nutrients
    outcome[["nutrients"]] <- list(
      CP = sum(optimal_content_DM * feed_matrix$cp.dm),
      RUP = sum(optimal_content_DM * feed_matrix$rupx.dm),
      Starch = sum(optimal_content_DM * feed_matrix$starch.dm),
      NDF = sum(optimal_content_DM * feed_matrix$ndf.dm),
      FNDF = sum(optimal_content_DM * feed_matrix$f_ndf.dm),
      Forage = sum(optimal_content_DM * feed_matrix$forage.dm),
      TDN = sum(optimal_content_DM * feed_matrix$tdn.dm),
      ME = sum(optimal_content_DM *feed_matrix$me.mcal.dm),
      MP = sum(optimal_content_DM *feed_matrix$mp.g.dm)
    )
    
  } else {
    outcome[["result"]]<-"failed"
    outcome[["further"]]<-capture.output(test_constraints(objective_coefficients,feed_nutrient,nutrient_constraints,feed_input))
    
  }
  
  return(outcome)
}




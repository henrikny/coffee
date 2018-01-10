###################################################
## MANUAL BACKFILLING
###################################################
data_in <- tibble(name = p$name, 
                  time = "2017-12-31 00:00:00", 
                  amount = rep(0, nrow(p)))


write_coffee_manual <- function(data_in){
  data_in <- data_in %>% filter(amount != 0)
  
  if(any(!data_in$name %in% p$name)){
    stop("Name not recognized")
  }
  
  data_in <- data_in %>% left_join(p, by = "name")
  new_index <- rep(1:nrow(data_in), times = data_in$amount)
  data_in <- data_in[new_index,]
  data_in <- data_in %>% 
    select(-amount, -active) %>% 
    mutate(action = "Single pot")
  
  rs <- dbSendStatement(conn = coffee_db, 
                        statement = "INSERT INTO actions (time, name_id, active, action, backfilled) VALUES (:time, :name_id, :active, :action, :backfilled)")
  dbBind(rs, param = list(time = str_c(data_in$time), 
                          name_id = data_in$rowid,
                          active = rep(1, nrow(data_in)),
                          action = data_in$action,
                          backfilled = rep(1, nrow(data_in))))
}


###################################################
## EDIT DATA
###################################################
dbExecute(conn = coffee_db, 
          statement = "UPDATE actions SET action = 'Single pot' WHERE action = 'Single Pot'")

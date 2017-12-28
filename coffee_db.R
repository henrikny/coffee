library(DBI)
library(dbplyr)
library(tidyverse)
library(RSQLite)
library(lubridate)
# setwd("/Users/henriknyhus/Dropbox/Git/coffee")
# setwd("/srv/shiny-server/coffee")

###################################################
## CREATE NEW
###################################################
## create empty database
coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")

## drop old tables if coffee_db already exists
dbRemoveTable(conn = coffee_db, name = "persons")
dbRemoveTable(conn = coffee_db, name = "actions")

## add tables
sql <- sqlCreateTable(con = coffee_db, 
                      table = "persons", 
                      fields = c(name = "TEXT", 
                                 active = "SMALLINT"), 
                      row.names = FALSE)
dbExecute(conn = coffee_db, 
          statement = sql, 
          overwrite = TRUE)
sql <- sqlCreateTable(con = coffee_db, 
                      table = "actions", 
                      fields = c(time = "REAL",
                                 name_id = "TEXT", 
                                 active = "SMALLINT", 
                                 action = "TEXT",
                                 backfilled = "SMALLINT"), 
                      row.names = FALSE)
dbExecute(conn = coffee_db, 
          statement = sql, 
          overwrite = TRUE)
dbListTables(coffee_db)


###################################################
## ADD NAMES MANUALLY TO NEW
###################################################
rs <- dbSendStatement(conn = coffee_db, 
                      statement = "INSERT INTO persons (name, active) VALUES (:x, :y)")
dbBind(rs, param = list(x = "A Guest", y = 1))

dbGetQuery(coffee_db, "SELECT rowid, * FROM persons")


###################################################
## GET DATA
###################################################
p <- dbGetQuery(conn = coffee_db,
                statement = "SELECT rowid, * FROM persons") %>% as_tibble()
d <- dbGetQuery(conn = coffee_db, 
                statement = "SELECT rowid, * FROM actions") %>% as_tibble()
d
p
d %>% mutate(name_id = as.integer(name_id)) %>% left_join(p, by = c("name_id" = "rowid")) %>% View()


###################################################
## MANUAL BACKFILLING
###################################################
## either manually enter names or use your current persons-table as base
p$name
data_in <- tibble(name = p$name, 
                  time = "2017-12-09 00:00:00", 
                  amount = c(2, 4, 5, 7, 1, 2, 34, 2, 2, 3, 4, 8, 0, 0, 0, 1, 2, 4, 2, 0, 3, 6, 0))

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
    mutate(action = "Single Pot")
   
  rs <- dbSendStatement(conn = coffee_db, 
                        statement = "INSERT INTO actions (time, name_id, active, action, backfilled) VALUES (:time, :name_id, :active, :action, :backfilled)")
  dbBind(rs, param = list(time = str_c(data_in$time), 
                          name_id = data_in$rowid,
                          active = rep(1, nrow(data_in)),
                          action = data_in$action,
                          backfilled = rep(0, nrow(data_in))))
}




###################################################
## DISCONNECT
###################################################
dbDisconnect(coffee_db)



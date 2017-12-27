library(DBI)
library(dbplyr)
library(tidyverse)
library(RSQLite)
library(lubridate)
setwd("/Users/henriknyhus/Dropbox/Git/coffee")
setwd("/srv/shiny-server/coffee")

###################################################
## CREATE NEW
###################################################
## create empty database
coffee_db_new <- dbConnect(RSQLite::SQLite(), "coffee_new.sqlite")

## drop old tables if coffee_db_new already exists
dbRemoveTable(conn = coffee_db_new, name = "persons")
dbRemoveTable(conn = coffee_db_new, name = "actions")

## add tables
sql <- sqlCreateTable(con = coffee_db_new, 
                      table = "persons", 
                      fields = c(name = "TEXT", 
                                 active = "SMALLINT"), 
                      row.names = FALSE)
dbExecute(conn = coffee_db_new, 
          statement = sql, 
          overwrite = TRUE)
sql <- sqlCreateTable(con = coffee_db_new, 
                      table = "actions", 
                      fields = c(time = "REAL",
                                 name_id = "TEXT", 
                                 active = "SMALLINT", 
                                 action = "TEXT",
                                 backfilled = "SMALLINT"), 
                      row.names = FALSE)
dbExecute(conn = coffee_db_new, 
          statement = sql, 
          overwrite = TRUE)
dbListTables(coffee_db_new)


###################################################
## ADD NAMES MANUALLY TO NEW
###################################################
persons <- read_csv("persons.csv")
rs <- dbSendStatement(conn = coffee_db_new, 
                      statement = "INSERT INTO persons (name, active) VALUES (:x, :y)")
dbBind(rs, param = list(x = persons$name, y = persons$active))

dbGetQuery(coffee_db_new, "SELECT rowid, * FROM persons")


###################################################
## GET OLD DATA
###################################################
coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")

p <- dbGetQuery(conn = coffee_db,
                statement = "SELECT rowid, * FROM persons") %>% as_tibble()
d <- dbGetQuery(conn = coffee_db, 
                statement = "SELECT rowid, * FROM actions") %>% as_tibble()
d %>% mutate(name_id = as.integer(name_id)) %>% left_join(p, by = c("name_id" = "rowid")) %>% View()

d
p

###################################################
## MOVE REAL DATA TO NEW
###################################################
rs <- dbSendStatement(conn = coffee_db_new, 
                      statement = "INSERT INTO actions (time, name_id, active, action, backfilled) VALUES (:time, :name_id, :active, :action, :backfilled)")
dbBind(rs, param = list(time = str_c(d$time), 
                        name_id = d$name_id,
                        active = d$active,
                        action = d$action,
                        backfilled = d$backfilled))

###################################################
## GET NEW DATA
###################################################
p_new <- dbGetQuery(conn = coffee_db_new,
                statement = "SELECT rowid, * FROM persons") %>% as_tibble()
d_new <- dbGetQuery(conn = coffee_db_new, 
                    statement = "SELECT rowid, * FROM actions") %>% as_tibble()
d_new
p_new


###################################################
## MANUAL ENTER POTS OF COFFEE
## TO OLD OR NEW?
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
   
  rs <- dbSendStatement(conn = coffee_db_new, 
                        statement = "INSERT INTO actions (time, name_id, active, action, backfilled) VALUES (:time, :name_id, :active, :action, :backfilled)")
  dbBind(rs, param = list(time = str_c(data_in$time), 
                          name_id = data_in$rowid,
                          active = rep(1, nrow(data_in)),
                          action = data_in$action,
                          backfilled = rep(0, nrow(data_in))))
}




###################################################
## STATISTICS
###################################################






###################################################
## DISCONNECT
###################################################
dbDisconnect(coffee_db_new)
dbDisconnect(coffee_db)



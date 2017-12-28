library(shiny)
library(tidyverse)
library(stringr)
library(lubridate)
library(dbplyr)
library(DBI)
library(RSQLite)
getwd()
# setwd("/Users/henriknyhus/Dropbox/Git/coffee")
# setwd("/srv/shiny-server/coffee")

# db_path <- "../coffee-db/coffee.sqlite"
# db_path <- "coffee.sqlite"

###################################################
## CREATE NEW
###################################################
## connect to existing / create empty database
coffee_db <- dbConnect(RSQLite::SQLite(), db_path)

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

d %>% 
  mutate(name_id = as.integer(name_id)) %>% 
  left_join(p, by = c("name_id" = "rowid")) %>% 
  View()


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


###################################################
## SUMMARY STATISTICS
###################################################
d <- tbl(coffee_db, "actions") %>% 
  as_tibble() %>% 
  filter(active == 1) %>% 
  filter(action %in% c("Single pot", "Double pot")) %>% 
  mutate("pots" = if_else(action == "Single pot", 1, 2)) %>% 
  mutate(name_id = as.integer(name_id)) %>% 
  left_join(p, by = c("name_id" = "rowid")) %>% 
  group_by(name, time) %>% 
  summarize(pots = sum(pots)) %>% 
  arrange(desc(pots)) %>% 
  right_join(p)
View(d)


###################################################
## DISCONNECT
###################################################
dbDisconnect(coffee_db)

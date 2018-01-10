###################################################
## LOAD LIBRARIES
###################################################
library(shiny)
library(tidyverse)
library(stringr)
library(lubridate)
library(dbplyr)
library(DBI)
library(RSQLite)


###################################################
## SET PATH TO SQLite DB
###################################################
getwd()
setwd("/Users/henriknyhus/Dropbox/Git/coffee")
setwd("/srv/shiny-server/coffee")

db_path <- "../coffee-db/coffee.sqlite"
db_path <- "coffee.sqlite"


###################################################
## CONNECT
###################################################
coffee_db <- dbConnect(RSQLite::SQLite(), db_path)


###################################################
## DISCONNECT
###################################################
dbDisconnect(coffee_db)

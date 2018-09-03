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
#db_path <- "../coffee-db/coffee.sqlite"
db_path <- "coffee.sqlite"

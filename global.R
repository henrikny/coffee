library(shiny)
library(tidyverse)
library(stringr)
library(lubridate)
library(dbplyr)
library(DBI)
library(RSQLite)


## set path SQLite db
# db_path <- "coffee.sqlite"
db_path <- "../coffee-db/coffee.sqlite"


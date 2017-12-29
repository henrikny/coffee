# coffee
Shiny Coffee app


## Intro

Tired of co-worked complaining about how "no one" makes a pot of coffee?
Fire up a shiny-server with this bitchin' app, slap up a tablet next the coffee maker and voilà - the barista-of-the-week game is on!

Everyone select what they just did (mage one/two pots of coffee, drank a cup coffee/tea), their name and hit save which enters the information in the SQLite database. The app also lets you delete last entry, add new, delete and change names.

The top five baristas of the last seven days is shown on the front page.

## What you need

- You need a server (obsolete laptop workes just fine) with ubuntu + shiny-server installed.
- A tablet (Galaxy/iPad) on same WiFi network.
- This code


## Initialisation

Check out offee_db.R for more info regarding initialisation.

```{r}
## load libraries
library(shiny)
library(tidyverse)
library(stringr)
library(lubridate)
library(dbplyr)
library(DBI)
library(RSQLite)

## set path
getwd()
# setwd("/srv/shiny-server/coffee")
# db_path <- "../coffee-db/coffee.sqlite"

## connect to existing / create empty database
coffee_db <- dbConnect(RSQLite::SQLite(), db_path)

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

## list tables
dbListTables(coffee_db)

## disconnect
dbDisconnect(coffee_db)
```



## Notes

- My current department is called "FRIEND", so feel free to change this to your own :)

- Make sure to have all packages installed prior to running the app.

- To avoid sharing my own data, I set a path to a external db (separate file in parallel folder coffee-db) in global.R

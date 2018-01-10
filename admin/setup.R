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

## list tables
dbListTables(coffee_db)


###################################################
## ADD NAMES MANUALLY TO NEW
###################################################
rs <- dbSendStatement(conn = coffee_db, 
                      statement = "INSERT INTO persons (name, active) VALUES (:x, :y)")
dbBind(rs, param = list(x = "A Guest", y = 1))
dbGetQuery(coffee_db, "SELECT rowid, * FROM persons")

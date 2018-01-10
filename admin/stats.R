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
## SUMMARY STATISTICS
###################################################
## total pots
d <- tbl(coffee_db, "actions") %>% 
  as_tibble() %>% 
  filter(active == 1) %>% 
  filter(action %in% c("Single pot", "Double pot")) %>% 
  mutate("pots" = if_else(action == "Single pot", 1, 2)) %>% 
  mutate(name_id = as.integer(name_id)) %>% 
  left_join(p, by = c("name_id" = "rowid")) %>% 
  group_by(name) %>% 
  summarize(pots = sum(pots)) %>% 
  arrange(desc(pots)) %>% 
  right_join(p)
View(d)


## total coffees
d <- tbl(coffee_db, "actions") %>% 
  as_tibble() %>% 
  filter(active == 1) %>% 
  filter(action %in% c("Coffee")) %>% 
  mutate(name_id = as.integer(name_id)) %>% 
  left_join(p, by = c("name_id" = "rowid")) %>% 
  group_by(name) %>% 
  summarize(coffees = n()) %>% 
  arrange(desc(coffees)) %>% 
  right_join(p)
View(d)

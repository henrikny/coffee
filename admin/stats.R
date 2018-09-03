###################################################
## GET DATA
###################################################
p <- dbGetQuery(conn = coffee_db,
                statement = "SELECT rowid, * FROM persons") %>% as_tibble()
d <- dbGetQuery(conn = coffee_db, 
                statement = "SELECT rowid, * FROM actions") %>% as_tibble()

coffe_complete <- d %>% 
  mutate(name_id = as.integer(name_id)) %>% 
  left_join(p, by = c("name_id" = "rowid"))

View(coffe_complete)

###################################################
## EXPORT DATA
###################################################
getwd()
write_csv(x = coffe_complete, path = "coffe_complete.csv")

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

## total coffee last week
a <- floor_date(x = now(), unit = "week", week_start = 1)
b <- a - days(7)
c <- interval(start = b, end = a)
c

d <- tbl(coffee_db, "actions") %>% 
  as_tibble() %>% 
  filter(active == 1) %>% 
  filter(action %in% c("Single pot", "Double pot")) %>% 
  mutate("pots" = if_else(action == "Single pot", 1, 2)) %>% 
  mutate(name_id = as.integer(name_id),
         time = ymd_hms(time)) %>% 
  left_join(p, by = c("name_id" = "rowid")) %>% 
  filter(time %within% c) %>% 
  group_by(name) %>% 
  summarize(pots = sum(pots)) %>% 
  arrange(desc(pots)) %>% 
  right_join(p)
View(d)


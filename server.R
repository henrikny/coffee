
function(input, output, session){
  
  ###################################################
  ## SET LIVE TIME
  ###################################################
  output$time <- renderText({
    invalidateLater(millis = 1000, session = session)
    str_c(now(tzone = ""))
  })
  
  ###################################################
  ## DEFINE DATA
  ###################################################
  data <- reactiveValues(name_selected = NULL,
                         action_selected = NULL,
                         name_selection = NULL,
                         data_last = NULL,
                         data_top = NULL)
  
  ###################################################
  ## SELECT NAMES
  ###################################################
  get_names <- function(){
    coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
    data$name_selection <- dbGetQuery(conn = coffee_db, 
                                      statement = "SELECT rowid, * FROM persons") %>% 
      as_tibble()
    dbDisconnect(coffee_db)
  }
  
  get_names()
  
  output$select_name <- renderUI({
    radioButtons(inputId = "select_name",
                 label = NULL,
                 choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>%  pull(name),
                 selected = character(0))
  })
  
  
  ###################################################
  ## GET LAST DATA
  ###################################################
  get_last_data <- function(){
    coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
    data$data_last <- dbGetQuery(conn = coffee_db,
                                 statement = "SELECT rowid, * FROM actions WHERE rowid = (SELECT MAX(rowid) FROM actions WHERE active = 1)") %>%
      as_tibble() %>%
      mutate(name_id = as.integer(name_id)) %>%
      left_join(data$name_selection, by = c("name_id" = "rowid")) %>%
      select(time, name, action, rowid)
    dbDisconnect(coffee_db)
  }
  
  observeEvent(input$tab, {
    get_last_data()
  })
  
  output$data_last <- renderTable({
    data$data_last %>% select(time, name, action)
  })
  
  
  ###################################################
  ## TOP BARISTAS
  ###################################################
  get_top_data <- function(){
    coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
    data$data_top <- tbl(coffee_db, "actions") %>% 
      as_tibble() %>% 
      filter(active == 1) %>% 
      #filter(time > datetime('now', '-1 hours')) %>% 
      filter(time > now() - days(7)) %>% 
      filter(action %in% c("Single pot", "Double pot")) %>% 
      mutate("pots" = if_else(action == "Single pot", 1, 2)) %>% 
      mutate(name_id = as.integer(name_id)) %>% 
      left_join(data$name_selection, by = c("name_id" = "rowid")) %>% 
      group_by(name) %>% 
      summarize(pots = sum(pots)) %>% 
      arrange(desc(pots)) %>% 
      top_n(3, pots)
    dbDisconnect(coffee_db)
    
  }
  
  output$data_top <- renderTable({
    data$data_top
  })
  
  
  
  ###################################################
  ## ACTION
  ###################################################
  observeEvent(input$pot_single, {
    data$action_selected <- "Single pot"
  })
  observeEvent(input$pot_double, {
    data$action_selected <- "Double pot"
  })
  observeEvent(input$cup, {
    data$action_selected <- "Coffee"
  })
  observeEvent(input$tea, {
    data$action_selected <- "Tea"
  })
  output$action_selected <- renderText({
    validate(need(!is.null(data$action_selected),
                  message = "Please select action"))
    data$action_selected
  })
  
  
  ###################################################
  ## NAME
  ###################################################
  observeEvent(input$select_name, {
    data$name_selected <- input$select_name
  })
  output$name_selected <- renderText({
    validate(need(!is.null(data$name_selected),
                  message = "Please select name"))
    data$name_selected
  })
  
  
  ###################################################
  ## CLEAR
  ###################################################
  clear <- function(){
    data$name_selection <- NULL
    data$action_selected <- NULL
    data$name_selected <- NULL
    
    get_names()
    get_last_data()
    get_top_data()
    
    ## kun for å fjerne "selected" på hovedsiden
    ## ved editering så rendres navnelisten på nytt
    updateRadioButtons(session,
                       inputId = "select_name",
                       choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>% pull(name),
                       selected = character(0))
    updateSelectInput(session,
                      inputId = "edit_name_selection",
                      label = "Select name",
                      choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>% pull(name),
                      selected = 1)
    updateSelectInput(session,
                      inputId = "delete_name_selection",
                      label = "Select name",
                      choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>% pull(name),
                      selected = 1)
  }
  
  observeEvent(input$clear, {
    clear()
  })
  
  
  ###################################################
  ## SAVE DATA, SET TIME AND CHECK CONTIDIONS
  ###################################################
  observeEvent(input$save, {
    if(is.null(data$action_selected) | is.null(data$name_selected)){
      showModal(modalDialog(
        title = "ERROR",
        "Please fill out all values",
        easyClose = TRUE,
        footer = NULL))
    }
    else {
      showModal(modalDialog(
        title = "WHOOOO!",
        "Entry saved :)",
        easyClose = TRUE,
        footer = NULL))
      coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
      rs <- dbSendStatement(conn = coffee_db, 
                            statement = "INSERT INTO actions (time, name_id, active, action, backfilled) VALUES (:time, :name_id, :active, :action, :backfilled)")
      rowid <- data$name_selection %>% filter(name == data$name_selected) %>% pull(rowid)
      dbBind(rs, param = list(time = str_c(now()),
                              name_id = rowid,
                              active = 1,
                              action = data$action_selected,
                              backfilled = 0))
      dbDisconnect(coffee_db)
      clear()
    }
  })
  
  
  ###################################################
  ## DELETE LAST DATA
  ###################################################
  observeEvent(input$delete_action, {
    showModal(modalDialog(
      span("Are you sure you want to delete"),
      renderTable(data$data_last %>% select(time, name, action)),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(inputId = "data_delete_confirm", 
                     label = "Delete", 
                     icon = icon("remove"))
      )))
  })
  observeEvent(input$data_delete_confirm, {
    coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
    rs <- dbSendStatement(conn = coffee_db, 
                          statement = "UPDATE actions SET active = 0 WHERE rowid = :x")
    dbBind(rs, param = list(x = data$data_last %>% pull(rowid)))
    dbDisconnect(coffee_db)
    clear()
    removeModal()
  })
  
  
  ###################################################
  ## NEW NAME
  ###################################################
  observeEvent(input$new_name_save, {
    if(input$new_name_box %in% data$name_selection$name) {
      showModal(modalDialog(
        title = "ERROR",
        "Name already exists",
        easyClose = TRUE,
        footer = NULL))
    }
    else {
      showModal(modalDialog(
        title = "WHOOOO!",
        "Entry saved :)",
        easyClose = TRUE,
        footer = NULL))
      coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
      rs <- dbSendStatement(conn = coffee_db, 
                            statement = "INSERT INTO persons (name, active) VALUES (:x, :y)")
      dbBind(rs, param = list(x = input$new_name_box, y = 1))
      dbDisconnect(coffee_db)
      clear()
    }
  })
  
  
  ###################################################
  ## EDIT NAME
  ###################################################
  output$edit_name_selection <- renderUI({
    selectInput(inputId = "edit_name_selection",
                label = "Select name", 
                choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>% pull(name),
                selected = 1)
  })
  output$edit_name_box <- renderUI({
    textInput(inputId = "edit_name_box", label = "Edit name", value = input$edit_name_selection)
  })
  
  observeEvent(input$edit_name_save, {
    if(input$edit_name_box %in% data$name_selection$name) {
      showModal(modalDialog(
        title = "ERROR",
        "Name already exists",
        easyClose = TRUE,
        footer = NULL))
    }
    else {
      showModal(modalDialog(
        title = "WHOOOO!",
        "Entry saved :)",
        easyClose = TRUE,
        footer = NULL))
      coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
      rs <- dbSendStatement(conn = coffee_db,
                            statement = "UPDATE persons SET name = :x WHERE name = :y")
      dbBind(rs, param = list(x = input$edit_name_box, y = input$edit_name_selection))
      dbDisconnect(coffee_db)
      clear()
    }
  })
  
  ###################################################
  ## DELETE NAME
  ###################################################
  output$delete_name_selection <- renderUI({
    selectInput(inputId = "delete_name_selection",
                label = "Select name", 
                choices = data$name_selection %>% filter(active == 1) %>% arrange(name) %>% select(name) %>% pull(),
                selected = 1)
  })
  
  observeEvent(input$delete_name_delete, {
    showModal(modalDialog(
      span("Are you sure you want to delete"),
      renderText(input$delete_name_selection),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("delete_name_delete_confirm", "Delete", icon = icon("remove"))
      )))
  })
  
  observeEvent(input$delete_name_delete_confirm, {
    coffee_db <- dbConnect(RSQLite::SQLite(), "coffee.sqlite")
    rs <- dbSendStatement(conn = coffee_db, 
                          statement = "UPDATE persons SET active = 0 WHERE name = :x")
    dbBind(rs, param = list(x = input$delete_name_selection))
    dbDisconnect(coffee_db)
    clear()
    removeModal()
  })
  
  
}

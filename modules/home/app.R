##### SETUP
library(shiny)
library(shinyjs)
library(OmicSelector)
library(dplyr)

options(shiny.maxRequestSize = 30*1024^2)

library(waiter)
waiting_screen <- tagList(
    spin_3(),
    h4("OmicSelector is working...")
)

##### INIT VARS
if_analysis_id_duplicated = TRUE
while(if_analysis_id_duplicated == TRUE){
    init_random_analysis_id = stringi::stri_rand_strings(1, 15)
    if_analysis_id_duplicated = dir.exists(paste0("/OmicSelector/",init_random_analysis_id))
}

##### UI
ui <- fluidPage(
    #### STYLE
    useShinyjs(),
    tags$head(
        tags$style(HTML("
      #error_msg {
        color: red;
      }
    "))
    ),
    
    ##### MAIN
    htmlTemplate("ui.html",
                 init_random_analysis_id = init_random_analysis_id)
)

##### SERVER
server <- function(input,output){
    observeEvent(input$button_startover, {
        shinyjs::toggle(id= "panelA")
        shinyjs::toggle(id= "panelB")
    })
    
    observeEvent(input$button_start_analysis, {
        # VALIDATION:
        walidacja = ""
        if(dir.exists(paste0("/OmicSelector/",input$analysis_id)) == TRUE) { walidacja = "The analysis with the same analysis ID already exists. Choose a unique one." }
        if(is.null(input$file2)) { walidacja = "You have to provide xlsx or csv file for the analysis." }
        
        if(walidacja != "") { showNotification(walidacja, duration = 10, type = "error") }
        validate(need(walidacja == "", "Form validation error", "button_start_analysis"))
        
        # Create a Progress object
        progress <- shiny::Progress$new()
        # Make sure it closes when we exit this reactive, even if there's an error
        on.exit(progress$close())
        progress$set(message = "Validating submitted data & performing initial analysis", value = 0)
        
        
        # ACTION:
        n_steps <- 10
        
        for (i in 1:n_steps) {
          # Increment the progress bar, and update the detail text.
          progress$inc(1/n_steps)
          
          # Pause for 0.1 seconds to simulate a long computation.
          Sys.sleep(1)
        }
        
        
        
        # END:
        shinyjs::toggle(id= "panelA")
        shinyjs::toggle(id= "panelB")
    })
}

shinyApp(ui=ui,server=server)
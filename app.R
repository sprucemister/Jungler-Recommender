library(shiny)
library(tidyverse)

c_champions <- readRDS('Analysis_Data/c_champions.rds')
c_models <- readRDS('Analysis_Data/c_models.rds')

ui <- fluidPage(
  
  # Application title
  titlePanel("Jungler Recommender"),

  sidebarLayout(
    
    sidebarPanel(
      
      # Input for what junglers you play
      selectInput(inputId='my_champs',
                     label='My Junglers',
                     choices=c_champions,
                     multiple=TRUE,
                     selected=c('Amumu','Gwen','Diana','Maokai')),
      # Break line
      HTML('<hr>'),
      
      # Inputs for which champions the enemies are playing
      selectizeInput(
        'enemy1', 'Top', choices = c_champions,
        options = list(
          placeholder = 'Please select an option below',
          onInitialize = I('function() { this.setValue(""); }')
        )
      ),
      selectizeInput(
        'enemy2', 'Jungle', choices = c_champions,
        options = list(
          placeholder = 'Please select an option below',
          onInitialize = I('function() { this.setValue(""); }')
        )
      ),
      selectizeInput(
        'enemy3', 'Mid', choices = c_champions,
        options = list(
          placeholder = 'Please select an option below',
          onInitialize = I('function() { this.setValue(""); }')
        )
      ),
      selectizeInput(
        'enemy4', 'ADC', choices = c_champions,
        options = list(
          placeholder = 'Please select an option below',
          onInitialize = I('function() { this.setValue(""); }')
        )
      ),
      selectizeInput(
        'enemy5', 'Support', choices = c_champions,
        options = list(
          placeholder = 'Please select an option below',
          onInitialize = I('function() { this.setValue(""); }')
        )
      )
    ),
    
    # Main Panel with Results Visual
    mainPanel(
      uiOutput("result_viz")
      ),
    
    # Arguments for Sidebar Layout
    position = c("left"),
    fluid = TRUE
  )
)

server <- function(input, output) {
  
  
  output$result_viz <- renderUI({
    
    ranked_recomendations <- c()
    
    for (i in input$my_champs) {
      
      df_unseen <- data.frame(matrix(ncol = length(c_champions), nrow = 0))
      colnames(df_unseen) <- c_champions
      df_unseen <- df_unseen %>% add_row(!!!setNames(rep_len(FALSE,length(c_champions)), names(.)))
      if (input$enemy1 != '') {df_unseen[1,input$enemy1] <- TRUE}
      if (input$enemy2 != '') {df_unseen[1,input$enemy2] <- TRUE}
      if (input$enemy3 != '') {df_unseen[1,input$enemy3] <- TRUE}
      if (input$enemy4 != '') {df_unseen[1,input$enemy4] <- TRUE}
      if (input$enemy5 != '') {df_unseen[1,input$enemy5] <- TRUE}
      df_unseen <- df_unseen %>% mutate(across(where(is.logical), as.factor))
      if (is.null(c_models[[i]]) == FALSE) {
        ranked_recomendations[i] <- unname(predict(c_models[[i]], df_unseen, type = 'response'))
      } else {
        ranked_recomendations[i] <- -1
      }
    }
    
    # Create HTML Output String
    ranked_recomendations <- sort(ranked_recomendations, decreasing = TRUE)
    output_HTML <- ''
    for (i in 1:length(ranked_recomendations)) {
      if (ranked_recomendations[i] != -1) {
        print(ranked_recomendations[i])
        output_HTML <- paste0(output_HTML, i, ': ', '<strong>',names(ranked_recomendations[i]), '</strong><br>')
        output_HTML <- paste0(output_HTML, '&nbsp&nbsp&nbsp',unname(100*round(ranked_recomendations[i],2)), '% Win Chance<br>')
        output_HTML <- paste0(output_HTML, '<br>')
      } else {
        output_HTML <- paste0(output_HTML, '<br>N/A', ': ', '<strong>',names(ranked_recomendations[i]), '</strong><br>')
        output_HTML <- paste0(output_HTML, 'Not Enough Match Data<br>')
        output_HTML <- paste0(output_HTML, '<br>')
      }
    }
    
    HTML(output_HTML)
    
  })
}

shinyApp(ui = ui, server = server)

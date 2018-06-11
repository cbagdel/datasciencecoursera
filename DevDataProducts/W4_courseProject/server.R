#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  df <- reactive({
    data("iris")
    data <- iris
    #reduce to binary class using: "versicolor" vs "others"
    data$Species <- as.factor(ifelse(iris$Species == "versicolor", "versicolor", "others"))
    return(data)
  })
  
  adaboost <- reactive({
    data <- df()
    inTrain <- createDataPartition(y=data$Species, p=0.60, list=FALSE)
    #training <- data[inTrain,]
    #testing <- data[-inTrain,]
    #Use complete data set for visualizing purposes 
    training <- data
    
    library(adabag)
    set.seed(163)
    adaboost <- boosting(formula = Species ~ Petal.Length + Petal.Width + Sepal.Length + Sepal.Width, data = training, boos = TRUE, mfinal = 7, coeflearn='Freund')
    return(adaboost)
  })
  
  draw_line <- function(color) {
    if (!is.null(model())){
      abline(model(), col = color, lwd = 2)
    }
  }


  output$rb <- renderText({paste(input$tree_selection_radio_button[1], " was selected")})

  output$plot1 <- renderPlotly({
    #plot_misclassified
    data <- df()
    adaboost <- adaboost()
    rb <- input$tree_selection_radio_button
    if (grepl("Boosted Model", rb)) {
      pred <- predict.boosting(adaboost, newdata = data)
      predicted_class <- pred$class
    } else {
      treeIndex <- as.integer(substr(rb, 1, 1))
      tree <- adaboost$trees[[treeIndex]]
      predicted_class <- predict(tree, newdata = data, type = "class")
    }    
    
    
    p <- plot_ly(type = 'scatter', mode = 'markers')
    p <- add_trace(p, data = data, x = ~Petal.Width, y = ~Petal.Length, color = ~Species, colors = c('blue','green'), hoverinfo = 'none', legendgroup = 'group1')
    p <- add_trace(p, 
                   data = data[which(data$Species != predicted_class), ],
                   showlegend = TRUE,
                   legendgroup = 'group2',
                   name = 'misclassified',
                   mode = 'markers',
                   x = ~Petal.Width,
                   y = ~Petal.Length,
                   hoverinfo = 'text',
                   text = c('misclassified'),
                   marker = list(symbol = 'diamond-open', size = 8, color = 'red'))
    p
  })
  
})

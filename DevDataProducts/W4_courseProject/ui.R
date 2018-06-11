#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Visualize Adaboost Iterations for binary classification"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      radioButtons("tree_selection_radio_button", "Choose an intermediate tree:",
                   choices = c(
                     "1st Tree",
                     "2nd Tree",
                     "3rd Tree",
                     "4th Tree",
                     "5th Tree",
                     "6th Tree",
                     "7th Tree",
                     "Final Boosted Model"
                   ))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotlyOutput("plot1")
    )
  )
))

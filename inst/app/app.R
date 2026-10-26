# Patronage recovery explorer
#
# Intended user: a Victorian transport policy analyst or journalist.
# Question: how has each public transport mode's patronage recovered
# relative to a pre-pandemic baseline, and did free-travel periods give
# any mode a lasting boost?
#
# NOTE: this is a scaffold. Inputs, plot and explanatory text are placeholders
# to be built out in the next pass.

library(shiny)
library(bslib)
library(ggplot2)
library(vicptpatronage)

modes <- levels(vicptpatronage::monthly_patronage$mode)

ui <- page_sidebar(
  title = "Victorian public transport patronage recovery",
  sidebar = sidebar(
    selectInput(
      "modes",
      "Mode(s) to display",
      choices = modes,
      selected = modes,
      multiple = TRUE
    ),
    dateRangeInput(
      "date_range",
      "Date range",
      start = "2018-01-01",
      end = max(vicptpatronage::monthly_patronage$date),
      min = min(vicptpatronage::monthly_patronage$date),
      max = max(vicptpatronage::monthly_patronage$date)
    ),
    helpText(
      "Patronage is indexed to January 2020 = 100 so modes with very",
      "different volumes can be compared on the same scale."
    )
  ),
  card(
    card_header("Indexed patronage over time"),
    plotOutput("trend_plot")
  )
)

server <- function(input, output, session) {
  output$trend_plot <- renderPlot({
    validate(
      need(length(input$modes) > 0, "Select at least one mode to display.")
    )

    indexed <- vicptpatronage::patronage_index(
      vicptpatronage::monthly_patronage,
      baseline_date = "2020-01-01"
    )

    plot_data <- subset(
      indexed,
      mode %in%
        input$modes &
        date >= input$date_range[1] &
        date <= input$date_range[2]
    )

    ggplot(plot_data, aes(date, index, color = mode)) +
      geom_line() +
      labs(x = NULL, y = "Patronage index (Jan 2020 = 100)", color = "Mode")
  })
}

shinyApp(ui, server)

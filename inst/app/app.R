# Patronage recovery explorer
#
# Intended user: a Victorian transport policy analyst or journalist.
# Question: how has each public transport mode's patronage recovered
# relative to a pre-pandemic baseline, and did free-travel periods give
# any mode a lasting boost?

library(shiny)
library(bslib)
library(ggplot2)
library(thematic)
library(vicptpatronage)

modes <- levels(vicptpatronage::monthly_patronage$mode)
data_max_date <- max(vicptpatronage::monthly_patronage$date)
reference_year <- 2019
# The chart's selectable range starts the year after the reference year, so
# the reference year (whose index is always exactly 100, by construction)
# never has to be displayed or bridged over with a gap.
chart_min_date <- as.Date(sprintf("%d-01-01", reference_year + 1))

# Collapse the free_travel_period flag into contiguous date ranges, so the
# chart can shade whole blocks rather than one rectangle per month.
free_travel_rects <- function(data) {
  flagged <- sort(unique(data$date[data$free_travel_period]))
  if (length(flagged) == 0) {
    return(data.frame(xmin = as.Date(character()), xmax = as.Date(character())))
  }
  run_id <- cumsum(c(1, diff(flagged) > 32))
  data.frame(
    xmin = as.Date(tapply(flagged, run_id, min)),
    # shade through to the start of the month after the last flagged month
    xmax = as.Date(tapply(flagged, run_id, max)) + 31
  )
}

ui <- page_sidebar(
  title = "Victorian public transport patronage recovery",
  theme = bs_theme(version = 5, primary = "#00558C", secondary = "#6C757D"),
  sidebar = sidebar(
    width = 320,
    accordion(
      open = c("Filters", "About this app"),
      accordion_panel(
        "Filters",
        checkboxGroupInput(
          "modes",
          "Mode(s) to display",
          choices = modes,
          selected = modes
        ),
        dateRangeInput(
          "date_range",
          "Date range",
          start = chart_min_date,
          end = data_max_date,
          min = chart_min_date,
          max = data_max_date
        ),
        input_switch(
          "show_free_travel",
          "Highlight free-travel periods",
          value = TRUE
        )
      ),
      accordion_panel(
        "About this app",
        p(
          "Built for a ",
          strong("transport policy analyst or journalist"),
          " asking: how has each mode's patronage recovered relative to a ",
          "pre-pandemic baseline, and did free-travel periods leave a ",
          "lasting boost?"
        ),
        p(
          "Data: monthly patron boardings by mode, Jan 2018 onward, from ",
          "the Victorian Department of Transport and Planning Open Data ",
          "portal (CC BY 4.0)."
        ),
        p(
          "Shaded bands mark Victoria's 2025-2026 free-travel periods, ",
          "during which patronage was estimated with different methods ",
          "and should be interpreted with caution."
        ),
        p(
          "Each month is compared to the ",
          strong("same calendar month"),
          " in 2019 (e.g. March vs. March 2019), rather than to a single ",
          "fixed baseline month. Public transport patronage varies by ",
          "around 30% across the year even outside the pandemic, so ",
          "comparing like-for-like months avoids mistaking normal ",
          "seasonal swings for changes in recovery."
        ),
        p(
          "The chart starts in 2020: every 2019 month is compared to ",
          "itself, so 2019 has no meaningful index value to plot."
        )
      )
    )
  ),
  layout_column_wrap(
    width = 1 / 2,
    fill = FALSE,
    value_box(
      title = "Most recovered mode (selected range)",
      value = textOutput("most_recovered_label"),
      showcase = textOutput("most_recovered_value"),
      theme = "primary"
    ),
    value_box(
      title = "Least recovered mode (selected range)",
      value = textOutput("least_recovered_label"),
      showcase = textOutput("least_recovered_value"),
      theme = "secondary"
    )
  ),
  card(
    full_screen = TRUE,
    card_header("Patronage indexed to the same month in 2019 (2019 = 100)"),
    plotOutput("trend_plot"),
    card_footer(
      "Each line shows a mode's patronage as a percentage of the same ",
      "calendar month's patronage in 2019 (e.g. every March vs. March ",
      "2019). A mode above 100 has grown beyond its pre-pandemic level ",
      "for that month; a mode still below 100 has not yet recovered. ",
      "Use the date range to zoom into a recovery period, and compare ",
      "whether lines rise after a shaded free-travel band and hold at ",
      "the higher level, which would suggest a lasting effect rather ",
      "than a one-off bump."
    )
  )
)

server <- function(input, output, session) {
  thematic_shiny(font = "auto")

  valid_dates <- reactive({
    input$date_range[1] <= input$date_range[2]
  })

  indexed <- reactive({
    patronage_index(
      vicptpatronage::monthly_patronage,
      reference_year = reference_year
    )
  })

  filtered <- reactive({
    req(valid_dates())
    subset(
      indexed(),
      mode %in%
        input$modes &
        date >= input$date_range[1] &
        date <= input$date_range[2]
    )
  })

  # Latest index value per mode within the selected range, used for both
  # the value boxes and to rank "most/least recovered".
  latest_by_mode <- reactive({
    req(valid_dates(), length(input$modes) > 0)
    d <- filtered()
    if (nrow(d) == 0) {
      return(d)
    }
    d <- d[order(d$mode, d$date), ]
    do.call(rbind, lapply(split(d, d$mode), function(x) x[nrow(x), ]))
  })

  output$most_recovered_label <- renderText({
    d <- latest_by_mode()
    if (is.null(d) || nrow(d) == 0) {
      return("-")
    }
    as.character(d$mode[which.max(d$index)])
  })
  output$most_recovered_value <- renderText({
    d <- latest_by_mode()
    if (is.null(d) || nrow(d) == 0) {
      return("")
    }
    sprintf("Index %.0f", max(d$index))
  })
  output$least_recovered_label <- renderText({
    d <- latest_by_mode()
    if (is.null(d) || nrow(d) == 0) {
      return("-")
    }
    as.character(d$mode[which.min(d$index)])
  })
  output$least_recovered_value <- renderText({
    d <- latest_by_mode()
    if (is.null(d) || nrow(d) == 0) {
      return("")
    }
    sprintf("Index %.0f", min(d$index))
  })

  output$trend_plot <- renderPlot({
    validate(
      need(
        valid_dates(),
        "The start date is after the end date. Choose a start date before the end date."
      ),
      need(
        length(input$modes) > 0,
        "No mode selected. Choose at least one mode in the sidebar to display the chart."
      )
    )

    plot_data <- filtered()

    p <- ggplot(plot_data, aes(date, index, color = mode)) +
      geom_hline(yintercept = 100, linetype = "dashed", color = "grey50") +
      geom_line(linewidth = 0.9) +
      labs(
        x = NULL,
        y = "Patronage index (same month, 2019 = 100)",
        color = "Mode"
      ) +
      theme_minimal(base_size = 13)

    if (isTRUE(input$show_free_travel)) {
      rects <- free_travel_rects(vicptpatronage::monthly_patronage)
      rects <- rects[
        rects$xmax >= input$date_range[1] & rects$xmin <= input$date_range[2],
      ]
      if (nrow(rects) > 0) {
        p <- p +
          annotate(
            "rect",
            xmin = rects$xmin,
            xmax = rects$xmax,
            ymin = -Inf,
            ymax = Inf,
            fill = "grey70",
            alpha = 0.3
          )
      }
    }

    p
  })
}

shinyApp(ui, server)

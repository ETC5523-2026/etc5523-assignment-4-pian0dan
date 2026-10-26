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

# Official Public Transport Victoria mode colours, taken directly from the
# DTP's "Transport Pictograms" asset files (CC BY 4.0; see
# inst/app/www/icons/ATTRIBUTION.md): blue for metropolitan train, green for
# tram, orange for bus, and purple for regional services. PTV's pictogram
# set only distinguishes two regional shades (train, coach), both a
# magenta-leaning purple (hue ~285-300deg); "Regional bus" has no official
# colour of its own, so it uses a third, more blue-violet purple (hue
# ~267deg) rather than a simple interpolation, so it reads as clearly
# distinct from both official shades rather than a shade "in between" them.
mode_colors <- c(
  "Metropolitan train" = "#0072CE",
  "Metropolitan tram" = "#78BE20",
  "Metropolitan bus" = "#FF8200",
  "Regional train" = "#7F0D82",
  "Regional coach" = "#A57FB2",
  "Regional bus" = "#7A3AC9"
)

# Pictogram shown next to each mode in the filter checkboxes. PTV has no
# distinct symbol for regional (vs. metropolitan) bus, so "Regional bus"
# reuses the generic bus shape but recoloured to match its line colour
# above (see inst/app/www/icons/ATTRIBUTION.md for provenance).
mode_icons <- c(
  "Metropolitan train" = "icons/train.png",
  "Metropolitan tram" = "icons/tram.png",
  "Metropolitan bus" = "icons/bus.png",
  "Regional train" = "icons/regional_train.png",
  "Regional coach" = "icons/coach.png",
  "Regional bus" = "icons/regional_bus.png"
)
reference_year <- 2019
# The chart's selectable range starts the year after the reference year, so
# the reference year (whose index is always exactly 100, by construction)
# never has to be displayed or bridged over with a gap.
chart_min_date <- as.Date(sprintf("%d-01-01", reference_year + 1))

# Collapse a fare_period level into contiguous date ranges, so the chart can
# shade whole blocks rather than one rectangle per month.
fare_period_rects <- function(data, period) {
  flagged <- sort(unique(data$date[data$fare_period == period]))
  if (length(flagged) == 0) {
    return(data.frame(
      xmin = as.Date(character()),
      xmax = as.Date(character()),
      fare_period = character()
    ))
  }
  run_id <- cumsum(c(1, diff(flagged) > 32))
  data.frame(
    xmin = as.Date(tapply(flagged, run_id, min)),
    # shade through to the start of the month after the last flagged month
    xmax = as.Date(tapply(flagged, run_id, max)) + 31,
    fare_period = period
  )
}

# Shading intensity roughly tracks discount intensity: weekend-only free
# travel affected far fewer days per month than the later every-day free
# and half-price periods.
fare_period_colors <- c(
  "Weekend free travel" = "grey88",
  "Free travel (every day)" = "grey40",
  "Half-price fares" = "grey65"
)

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
          choiceNames = lapply(modes, function(m) {
            tagList(
              tags$img(
                src = mode_icons[[m]],
                height = "20px",
                style = "vertical-align:middle;margin-right:6px;"
              ),
              m
            )
          }),
          choiceValues = modes,
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
          "show_fare_periods",
          "Highlight free & half-price fare periods",
          value = TRUE
        )
      ),
      accordion_panel(
        "About this app",
        p(
          "Built for a ",
          strong("transport policy analyst or journalist"),
          " asking: how has each mode's patronage recovered relative to a ",
          "pre-pandemic baseline, and did Victoria's 2025-2026 free and ",
          "half-price fare periods leave a lasting boost?"
        ),
        p(
          "Data: monthly patron boardings by mode, Jan 2018 onward, from ",
          "the Victorian Department of Transport and Planning Open Data ",
          "portal (CC BY 4.0). Mode icons are the Department's official ",
          "Transport Pictograms (CC BY 4.0); there is no distinct official ",
          "icon for regional bus, so its icon reuses the bus shape, ",
          "recoloured to match its line colour above."
        ),
        p(
          "Shaded bands mark three fare-discount periods of increasing ",
          "intensity: a pale band for ",
          strong("weekend-only free travel"),
          " (Dec 2025-Jan 2026, free on weekends only), a medium band for ",
          strong("half-price fares"),
          " (from Jun 2026, every day), and a dark band for ",
          strong("free travel every day"),
          " (Apr-May 2026). Patronage in all three is inflated by the ",
          "discount itself, not by organic recovery, so treat any ",
          "apparent gains during these bands with caution."
        ),
        p(
          "Weekend-only free travel (30 Nov 2025-1 Feb 2026) and a single ",
          "free weekday (31 Mar 2026) are documented in the source ",
          "dataset's own data quality notes; the single free day in Feb ",
          "and Mar 2026 is too small a share of those months to flag ",
          "separately. The later extension to free travel every day ",
          "(Apr-May 2026), and half-price fares from June 2026, are not ",
          "yet reflected in that dataset's documentation; these dates are ",
          "instead sourced from official Victorian Government media ",
          "releases (Premier of Victoria, 19 Apr 2026; Transport ",
          "Victoria, 22 May 2026)."
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
      "whether lines rise during a shaded fare-discount band and then ",
      "fall back afterwards (a discount-driven bump) or hold at the ",
      "higher level once the discount ends (a lasting effect)."
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

    p <- ggplot(plot_data, aes(date, index, color = mode))

    if (isTRUE(input$show_fare_periods)) {
      rects <- do.call(
        rbind,
        lapply(
          setdiff(
            levels(vicptpatronage::monthly_patronage$fare_period),
            "Normal fares"
          ),
          function(p) fare_period_rects(vicptpatronage::monthly_patronage, p)
        )
      )
      rects <- rects[
        rects$xmax >= input$date_range[1] & rects$xmin <= input$date_range[2],
      ]
      if (nrow(rects) > 0) {
        p <- p +
          geom_rect(
            data = rects,
            aes(xmin = xmin, xmax = xmax, fill = fare_period),
            ymin = -Inf,
            ymax = Inf,
            alpha = 0.4,
            inherit.aes = FALSE
          ) +
          scale_fill_manual(values = fare_period_colors, name = "Fare discount")
      }
    }

    p +
      geom_hline(yintercept = 100, linetype = "dashed", color = "grey50") +
      geom_line(linewidth = 0.9) +
      scale_color_manual(values = mode_colors) +
      labs(
        x = NULL,
        y = "Patronage index (same month, 2019 = 100)",
        color = "Mode"
      ) +
      theme_minimal(base_size = 13)
  })
}

shinyApp(ui, server)

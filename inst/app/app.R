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
library(plotly)
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
# and half-price periods. These are injected directly into plotly's JSON
# (shapes/marker specs below), bypassing ggplot2's usual colour-to-hex
# translation, so they must be real hex codes: plotly.js's CSS parser
# silently rejects R-only names like "grey88" (not valid CSS), leaving
# shading invisible and legend swatches falling back to default colours.
fare_period_colors <- c(
  "Weekend free travel" = "#E0E0E0",
  "Free travel (every day)" = "#666666",
  "Half-price fares" = "#A6A6A6"
)

# Colour theming for the app's chrome (sidebar, cards, buttons, headings),
# inspired by the Victorian Government's broader navy-and-gold digital
# brand used across vic.gov.au properties (Transport Victoria's own
# pages block automated fetches, so this draws on the shared state
# government palette rather than scraping their exact CSS). Note this is
# distinct from `mode_colors` above, which must stay fixed to PTV's
# official per-mode colours for the data encoding to remain meaningful.
app_theme <- bs_theme(
  version = 5,
  bg = "#FBFBFA",
  fg = "#1B1B1B",
  primary = "#0C2340", # Victorian Government navy
  secondary = "#C9A227", # warm gold accent
  base_font = font_collection(
    font_google("Public Sans", local = TRUE),
    "Helvetica Neue",
    "Arial",
    "sans-serif"
  ),
  heading_font = font_collection(
    font_google("Public Sans", wght = 700, local = TRUE),
    "Helvetica Neue",
    "Arial",
    "sans-serif"
  )
) |>
  bs_add_rules(
    "
    .card { border-radius: 0.65rem; box-shadow: 0 2px 10px rgba(12, 35, 64, 0.08); }
    .accordion-button:not(.collapsed) {
      background-color: rgba(12, 35, 64, 0.07);
      color: $primary;
    }
    "
  )

ui <- page_sidebar(
  title = "Victorian public transport patronage recovery",
  theme = app_theme,
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
          "recoloured to match its line colour in the plot."
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
    card_header(
      "Patronage indexed to the same month in 2019 (2019 = 100)",
      class = "bg-primary text-white"
    ),
    plotlyOutput("trend_plot"),
    card_footer(
      "Each line shows a mode's patronage as a percentage of the same ",
      "calendar month's patronage in 2019 (e.g. every March vs. March ",
      "2019). A mode above 100 has grown beyond its pre-pandemic level ",
      "for that month; a mode still below 100 has not yet recovered. ",
      "Hover over (or on touch devices, tap and drag along) a line to ",
      "read its exact index and raw patronage count for that month. ",
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

  output$trend_plot <- renderPlotly({
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
    plot_data$tooltip <- paste0(
      plot_data$mode,
      "<br>",
      format(plot_data$date, "%b %Y"),
      "<br>Index: ",
      sprintf("%.1f", plot_data$index),
      "<br>Patronage: ",
      format(plot_data$patronage, big.mark = ",", scientific = FALSE)
    )

    # plotly has no native translation of geom_rect()/scale_fill_manual(),
    # so shading is drawn separately as plotly background "shapes" (below)
    # rather than as a ggplot layer. ggplotly() converts rects into
    # malformed line-mode traces with garbled legend labels, so the line
    # chart itself only ever carries mode colour.
    p <- ggplot(plot_data, aes(date, index, color = mode, group = mode)) +
      geom_hline(yintercept = 100, linetype = "dashed", color = "grey50") +
      geom_line(aes(text = tooltip), linewidth = 0.9) +
      geom_point(aes(text = tooltip), size = 1, alpha = 0) +
      scale_color_manual(values = mode_colors) +
      labs(
        x = NULL,
        y = "Patronage index (same month, 2019 = 100)",
        color = "Mode"
      ) +
      theme_minimal(base_size = 13)

    pl <- ggplotly(p, tooltip = "text") |>
      layout(
        hovermode = "closest",
        xaxis = list(
          showspikes = TRUE,
          spikemode = "across",
          spikesnap = "cursor",
          spikedash = "dot"
        ),
        legend = list(title = list(text = "Mode"))
      )

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
        # ggplotly() renders a Date x-axis as numeric days-since-epoch on
        # a "linear" axis, so shape x0/x1 must match (not Date objects).
        shapes <- lapply(seq_len(nrow(rects)), function(i) {
          list(
            type = "rect",
            xref = "x",
            yref = "paper",
            x0 = as.numeric(rects$xmin[i]),
            x1 = as.numeric(rects$xmax[i]),
            y0 = 0,
            y1 = 1,
            fillcolor = fare_period_colors[[rects$fare_period[i]]],
            opacity = 0.4,
            line = list(width = 0),
            layer = "below"
          )
        })
        # plotly::layout(shapes = ...) and add_trace(name = ...) both
        # silently fail to merge onto a ggplotly()-derived object (a
        # library quirk with its layoutAttrs merge path in this plotly
        # version), so shapes and the legend swatches below are assigned
        # directly onto the built object instead.
        pl$x$layout$shapes <- shapes

        # Background shapes never appear in plotly's legend, so append a
        # trace with no real data (x/y = NA) per shaded period purely to
        # give it a correctly-coloured legend swatch.
        for (period in unique(rects$fare_period)) {
          pl$x$data[[length(pl$x$data) + 1]] <- list(
            x = NA_real_,
            y = NA_real_,
            type = "scatter",
            mode = "markers",
            marker = list(
              symbol = "square",
              size = 14,
              color = fare_period_colors[[period]],
              opacity = 0.6
            ),
            name = period,
            legendgroup = "fare_period",
            hoverinfo = "skip",
            showlegend = TRUE
          )
        }
      }
    }

    pl
  })
}

shinyApp(ui, server)

skip_if_not_installed("shiny")
skip_if_not_installed("bslib")
skip_if_not_installed("plotly")
skip_if_not_installed("thematic")

app_dir <- system.file("app", package = "vicptpatronage")
all_modes <- levels(vicptpatronage::monthly_patronage$mode)

# Run code inside the app's server. The app's plot code emits harmless
# ggplot2/thematic warnings outside a browser, so silence them here.
serve <- function(expr) {
  expr <- substitute(expr)
  suppressWarnings(eval(bquote(shiny::testServer(app_dir, .(expr)))))
}

test_that("any day in a month selects the whole month", {
  serve({
    session$setInputs(
      modes = all_modes,
      date_range = as.Date(c("2023-03-17", "2024-08-29")),
      show_fare_periods = TRUE
    )
    expect_null(problem())
    expect_equal(range(filtered()$date), as.Date(c("2023-03-01", "2024-08-01")))

    # Both ends inside one month still select that month
    session$setInputs(date_range = as.Date(c("2023-03-17", "2023-03-29")))
    expect_null(problem())
    expect_equal(unique(filtered()$date), as.Date("2023-03-01"))
  })
})

test_that("a start month after the end month gives a message", {
  serve({
    session$setInputs(
      modes = all_modes,
      date_range = as.Date(c("2024-03-17", "2023-03-29")),
      show_fare_periods = TRUE
    )
    expect_match(problem(), "start month is after the end month")
  })
})

test_that("an incomplete date range gives a message", {
  serve({
    session$setInputs(
      modes = all_modes,
      date_range = as.Date(c(NA, NA)),
      show_fare_periods = TRUE
    )
    expect_match(problem(), "incomplete")
  })
})

test_that("no mode selected gives a message", {
  serve({
    session$setInputs(
      modes = NULL,
      date_range = as.Date(c("2023-03-01", "2024-03-01")),
      show_fare_periods = TRUE
    )
    expect_match(problem(), "No mode selected")
  })
})

test_that("a range with no data gives a message", {
  serve({
    session$setInputs(
      modes = all_modes,
      date_range = as.Date(c("2018-03-01", "2019-06-30")),
      show_fare_periods = TRUE
    )
    expect_match(problem(), "No data for this selection")
  })
})

test_that("value boxes and plot all report the problem", {
  serve({
    session$setInputs(
      modes = NULL,
      date_range = as.Date(c("2023-03-01", "2024-03-01")),
      show_fare_periods = TRUE
    )
    expect_match(
      as.character(output$most_recovered_box$html),
      "No mode selected"
    )
    expect_match(
      as.character(output$least_recovered_box$html),
      "No mode selected"
    )
    expect_error(output$trend_plot, "No mode selected")
  })
})

test_that("value boxes name a mode when the selection is valid", {
  serve({
    session$setInputs(
      modes = c("Metropolitan train", "Metropolitan tram"),
      date_range = as.Date(c("2024-01-01", "2024-12-01")),
      show_fare_periods = FALSE
    )
    expect_null(problem())
    expect_match(as.character(output$most_recovered_box$html), "Metropolitan")
    expect_no_match(
      as.character(output$most_recovered_box$html),
      "No data to show"
    )
  })
})

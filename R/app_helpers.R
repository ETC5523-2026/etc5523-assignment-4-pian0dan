# Internal helper functions for the bundled Shiny app (inst/app/app.R).
# Non-exported; accessed from the app via `:::`, since the app ships inside
# this package rather than as a separate consumer of its public API.

#' Collapse a fare period into contiguous date ranges
#'
#' Lets the chart shade whole blocks rather than one rectangle per month.
#'
#' @param data A data frame with `date` and `fare_period` columns, such as
#'   [monthly_patronage].
#' @param period A single `fare_period` level.
#' @return A data frame with columns `xmin`, `xmax` and `fare_period`.
#' @noRd
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
    xmin = as.Date(as.vector(tapply(flagged, run_id, min))),
    # shade through to the start of the month after the last flagged month
    xmax = as.Date(as.vector(tapply(flagged, run_id, max))) + 31,
    fare_period = period
  )
}

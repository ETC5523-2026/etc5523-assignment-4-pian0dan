# Internal helper functions for the bundled Shiny app (inst/app/app.R).
# Non-exported; accessed from the app via `:::`, since the app ships inside
# this package rather than as a separate consumer of its public API.

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

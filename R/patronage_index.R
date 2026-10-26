#' Index monthly patronage to a baseline month
#'
#' Rescales each mode's monthly patronage so that a chosen baseline month
#' equals 100, making it possible to compare the relative recovery of modes
#' with very different patronage volumes (e.g. metropolitan train vs.
#' regional coach).
#'
#' @param data A data frame with the same structure as [monthly_patronage],
#'   containing at least the columns `date`, `mode` and `patronage`.
#' @param baseline_date A `Date`, or a string coercible to one (e.g.
#'   `"2020-01-01"`), giving the month to use as the index base (100).
#'   Matched to the first day of the month.
#'
#' @return A data frame with the same rows as `data`, plus an `index`
#'   column giving each mode's patronage as a percentage of its value in
#'   `baseline_date`.
#'
#' @examples
#' indexed <- patronage_index(monthly_patronage, baseline_date = "2020-01-01")
#' head(indexed)
#'
#' @export
patronage_index <- function(data, baseline_date = "2020-01-01") {
  baseline_date <- as.Date(baseline_date)

  if (!all(c("date", "mode", "patronage") %in% names(data))) {
    stop("`data` must contain `date`, `mode` and `patronage` columns.")
  }

  baseline <- data[data$date == baseline_date, c("mode", "patronage")]
  names(baseline)[2] <- "baseline_patronage"

  if (nrow(baseline) == 0) {
    stop(
      "No rows found for baseline_date = ",
      baseline_date,
      ". Check that this month exists in `data`."
    )
  }

  merged <- merge(data, baseline, by = "mode", all.x = TRUE)
  merged$index <- 100 * merged$patronage / merged$baseline_patronage
  merged[order(merged$mode, merged$date), ]
}

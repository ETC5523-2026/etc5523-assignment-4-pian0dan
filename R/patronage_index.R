#' Index monthly patronage to the same calendar month in a reference year
#'
#' Rescales each mode's monthly patronage as a percentage of that *same
#' calendar month* in a chosen reference year (e.g. March is compared to
#' the reference year's March, January to the reference year's January).
#' This avoids conflating genuine recovery with ordinary seasonal
#' variation: Victorian metropolitan train patronage, for example, is
#' routinely 30-35% higher in March or May than in January even in
#' pre-pandemic years, so indexing every month to a single fixed baseline
#' month would make seasonal swings look like changes in recovery.
#'
#' @param data A data frame with the same structure as [monthly_patronage],
#'   containing at least the columns `date`, `year`, `month`, `mode` and
#'   `patronage`.
#' @param reference_year An integer giving the year whose monthly values
#'   are used as the 100 baseline for the matching calendar month. Defaults
#'   to 2019, the last full year before the COVID-19 pandemic affected
#'   patronage.
#'
#' @return A data frame with the same rows as `data`, plus an `index`
#'   column giving each mode's patronage as a percentage of the same
#'   calendar month's patronage in `reference_year`.
#'
#' @examples
#' indexed <- patronage_index(monthly_patronage, reference_year = 2019)
#' head(indexed)
#'
#' @export
patronage_index <- function(data, reference_year = 2019) {
  if (!all(c("date", "year", "month", "mode", "patronage") %in% names(data))) {
    stop("`data` must contain `date`, `year`, `month`, `mode` and `patronage` columns.")
  }

  baseline <- data[data$year == reference_year, c("mode", "month", "patronage")]
  names(baseline)[3] <- "baseline_patronage"

  if (nrow(baseline) == 0) {
    stop(
      "No rows found for reference_year = ", reference_year,
      ". Check that this year exists in `data`."
    )
  }

  merged <- merge(data, baseline, by = c("mode", "month"), all.x = TRUE)
  merged$index <- 100 * merged$patronage / merged$baseline_patronage
  merged[order(merged$mode, merged$date), ]
}

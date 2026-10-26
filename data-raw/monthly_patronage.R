## code to prepare `monthly_patronage` dataset

library(readr)
library(dplyr)
library(stringr)

# Source: Victorian Department of Transport and Planning, Open Data portal.
# "Monthly public transport patronage by mode"
# https://opendata.transport.vic.gov.au/dataset/monthly-public-transport-patronage-by-mode
# Licence: Creative Commons Attribution 4.0
src_url <- paste0(
  "https://opendata.transport.vic.gov.au/dataset/",
  "1ab35aa9-f21d-4f00-939b-60dade427d45/resource/",
  "07141b34-08f7-430e-bf83-99e9462cc59f/download/",
  "monthly_public_transport_patronage_by_mode.csv"
)

raw <- read_csv(src_url, show_col_types = FALSE)

# Data quality fix: the "Regional bus" column is read as character because
# one cell (Nov 2024) contains "940930Jan-25" instead of a plain number -
# a spreadsheet artefact where the Nov-2024 figure appears to have been
# concatenated with the "Jan-25" label of an adjacent cell during the
# source's export. The leading digits (940930) are consistent with the
# surrounding months (Oct 2024: 1,193,762; Dec 2024: 921,439), so we
# extract them as the true value rather than discarding the observation.
raw <- raw |>
  mutate(
    `Regional bus` = if_else(
      `Regional bus` == "940930Jan-25",
      "940930",
      `Regional bus`
    ),
    `Regional bus` = as.numeric(`Regional bus`)
  )

# Reshape to long/tidy form: one row per year-month-mode, and flag months
# affected by the 2025-2026 free-travel periods, during which patronage was
# estimated using alternative methods (see dataset documentation) and should
# be interpreted with caution.
free_travel_months <- tibble::tribble(
  ~Year , ~Month ,
  2025L , 12L    , # Nov 30 2025 - Feb 1 2026 free weekends span Dec 2025...
  2026L ,  1L    , # ...Jan 2026...
  2026L ,  2L    , # ...and Feb 2026
  2026L ,  3L # 31 Mar 2026 free weekday travel
)

monthly_patronage <- raw |>
  rename(
    metropolitan_train = `Metropolitan train`,
    metropolitan_tram = `Metropolitan tram`,
    metropolitan_bus = `Metropolitan bus`,
    regional_train = `V/Line train`,
    regional_coach = `V/Line coach`,
    regional_bus = `Regional bus`,
    month = Month,
    month_name = `Month name`,
    year = Year
  ) |>
  tidyr::pivot_longer(
    cols = c(
      metropolitan_train,
      metropolitan_tram,
      metropolitan_bus,
      regional_train,
      regional_coach,
      regional_bus
    ),
    names_to = "mode",
    values_to = "patronage"
  ) |>
  mutate(
    date = as.Date(sprintf("%d-%02d-01", year, month)),
    mode = factor(
      mode,
      levels = c(
        "metropolitan_train",
        "metropolitan_tram",
        "metropolitan_bus",
        "regional_train",
        "regional_coach",
        "regional_bus"
      ),
      labels = c(
        "Metropolitan train",
        "Metropolitan tram",
        "Metropolitan bus",
        "Regional train",
        "Regional coach",
        "Regional bus"
      )
    ),
    free_travel_period = purrr::map2_lgl(
      year,
      month,
      \(y, m) any(free_travel_months$Year == y & free_travel_months$Month == m)
    )
  ) |>
  select(date, year, month, month_name, mode, patronage, free_travel_period) |>
  arrange(mode, date)

usethis::use_data(monthly_patronage, overwrite = TRUE)

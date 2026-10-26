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
# affected by Victoria's 2025-2026 fare-discount periods. These periods
# differ substantially in intensity, so they are kept as separate levels
# rather than one undifferentiated "free travel" flag. Two source tiers,
# kept distinct because they carry different levels of authority:
#
# 1) The DTP dataset's own "Data Quality" notes document free WEEKEND
#    travel only from 30 Nov 2025 to 1 Feb 2026 (not every day), and a
#    single free weekday on 31 Mar 2026 (see the dataset page linked
#    above), during which patronage was estimated using alternative
#    methods rather than myki ticketing data. Dec 2025 and Jan 2026 are
#    flagged as "Weekend free travel" months. Feb 2026 (just 1 overlapping
#    day, 1 Feb) and Mar 2026 (just the 31st) are left as "Normal fares":
#    at monthly granularity, a single day is too small a share of the
#    month to usefully flag, and flagging it would overstate how much of
#    the month's patronage was discount-affected.
# 2) The DTP dataset's notes do NOT mention that free travel was then
#    extended as a genuinely continuous (every day, not weekend-only)
#    period through April and May 2026, nor that half-price fares applied
#    from 1 June 2026 onward. These are sourced instead from official
#    Victorian Government media releases, since the dataset's own
#    documentation has not been updated to reflect them:
#    - https://www.premier.vic.gov.au/extra-month-free-pt-then-half-price-fares-all
#      (19 Apr 2026): free travel extended to the end of May 2026; half-price
#      fares from 1 June 2026 "until the end of the year".
#    - https://transport.vic.gov.au/news-and-resources/news/public-transport-now-half-price-for-everyone
#      (22 May 2026): half-price fares confirmed "from Monday 1 June 2026
#      until 1 January 2027".
#    Apr-May 2026 are flagged "Free travel (every day)"; Jun 2026 onward
#    "Half-price fares". Patronage during any of these periods is expected
#    to be inflated by the fare discount itself, independent of any
#    genuine recovery or demand trend.
fare_discount_months <- tibble::tribble(
  ~Year , ~Month , ~fare_period              ,
  2025L , 12L    , "Weekend free travel"     , # Nov 30 2025 - Feb 1 2026 free weekends span Dec 2025...
  2026L ,  1L    , "Weekend free travel"     , # ...and Jan 2026
  2026L ,  4L    , "Free travel (every day)" , # Continuous free travel through April...
  2026L ,  5L    , "Free travel (every day)" , # ...and May 2026
  2026L ,  6L    , "Half-price fares" # Half-price fares from 1 Jun 2026
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
    fare_period = purrr::map2_chr(
      year,
      month,
      \(y, m) {
        match_row <- fare_discount_months$Year == y &
          fare_discount_months$Month == m
        if (any(match_row)) {
          fare_discount_months$fare_period[match_row][1]
        } else {
          "Normal fares"
        }
      }
    ),
    fare_period = factor(
      fare_period,
      levels = c(
        "Normal fares",
        "Weekend free travel",
        "Free travel (every day)",
        "Half-price fares"
      )
    )
  ) |>
  select(date, year, month, month_name, mode, patronage, fare_period) |>
  arrange(mode, date)

usethis::use_data(monthly_patronage, overwrite = TRUE)

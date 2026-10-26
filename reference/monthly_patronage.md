# Monthly Victorian public transport patronage by mode

Monthly patronage (patron boardings) for metropolitan train, tram and
bus, and V/Line (regional) train, coach and bus services in Victoria,
Australia, from January 2018 onwards.

## Usage

``` r
monthly_patronage
```

## Format

A data frame with one row per mode per month, and columns:

- date:

  Date of the first day of the reporting month.

- year:

  Calendar year.

- month:

  Month number (1-12).

- month_name:

  Month name.

- mode:

  Transport mode: Metropolitan train, Metropolitan tram, Metropolitan
  bus, Regional train, Regional coach, or Regional bus.

- patronage:

  Count of patron boardings for that mode and month.

- fare_period:

  Factor flagging months substantially affected by a Victorian
  Government fare discount: `"Normal fares"`, `"Weekend free travel"`
  (Dec 2025-Jan 2026, weekends only), `"Free travel (every day)"`
  (Apr-May 2026) or `"Half-price fares"` (from Jun 2026). Patronage
  during non-"Normal fares" months is expected to be inflated by the
  discount itself and should not be read as organic recovery or demand
  growth; see Details.

## Source

Victorian Department of Transport and Planning, Open Data portal,
"Monthly public transport patronage by mode",
<https://opendata.transport.vic.gov.au/dataset/monthly-public-transport-patronage-by-mode>,
licensed under Creative Commons Attribution 4.0.

## Details

One data quality issue was corrected during preparation: the raw
"Regional bus" figure for November 2024 was exported as the string
`"940930Jan-25"` rather than a plain number. The leading digits were
extracted as the true value; see `data-raw/monthly_patronage.R` for the
full justification and cleaning code.

`fare_period` draws on two source tiers. Free WEEKEND travel only (30
Nov 2025-1 Feb 2026) and a single free weekday (31 Mar 2026) are
documented in the source dataset's own "Data Quality" notes; Dec 2025
and Jan 2026 are flagged `"Weekend free travel"`, while Feb and Mar 2026
are left as `"Normal fares"` since only a single day of each month was
affected. The subsequent extension to genuinely continuous (every-day)
free travel through April-May 2026, and half-price fares from 1 June
2026, are not mentioned in the dataset's documentation (as at the time
this package's data was last refreshed) and are instead sourced from
official Victorian Government media releases: the Premier's "Extra Month
Of Free PT - Then Half-Price Fares For All" (19 Apr 2026) and Transport
Victoria's "Public transport now half price for everyone" (22 May 2026).
See `data-raw/monthly_patronage.R` for full source URLs.

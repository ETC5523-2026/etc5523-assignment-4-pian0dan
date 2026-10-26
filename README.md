# vicptpatronage

<!-- badges: start -->
[![pkgdown](https://github.com/ETC5523-2026/etc5523-assignment-4-pian0dan/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/ETC5523-2026/etc5523-assignment-4-pian0dan/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

An R package and Shiny app for exploring how Victorian public transport
patronage has recovered since the COVID-19 pandemic, and whether Victoria's
2025-2026 free-travel and half-price fare periods left a lasting boost.

**Website:** <https://etc5523-2026.github.io/etc5523-assignment-4-pian0dan/>

## Who this is for

Built for a **Victorian transport policy analyst or journalist** asking: how
has each public transport mode's patronage recovered relative to its
pre-pandemic baseline, and did recent fare discounts produce a lasting
change or just a temporary bump?

## Data

`vicptpatronage` bundles `monthly_patronage`: monthly patron boardings for
six Victorian public transport modes (metropolitan train, tram and bus;
V/Line regional train, coach and bus) from January 2018 onward.

- **Source**: Victorian Department of Transport and Planning, Open Data
  portal, ["Monthly public transport patronage by
  mode"](https://opendata.transport.vic.gov.au/dataset/monthly-public-transport-patronage-by-mode),
  licensed under [Creative Commons Attribution
  4.0](https://creativecommons.org/licenses/by/4.0/).
- **Mode icons**: the Department's official [Transport
  Pictograms](https://opendata.transport.vic.gov.au/dataset/transport-pictograms)
  dataset, also CC BY 4.0.
- One data-quality issue was found and corrected during preparation (a
  corrupted cell in the raw "Regional bus" column), and a `fare_period`
  column flags months affected by fare discounts, with sources for each
  date range documented in `data-raw/monthly_patronage.R` and
  `?monthly_patronage`.

## Installation

Not on CRAN; install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-pian0dan")
```

## Launching the app

```r
library(vicptpatronage)
run_app()
```

See `vignette("vicptpatronage")` for a full walkthrough of the data, the
`patronage_index()` function, and how to use and interpret the app.

## License

MIT &copy; Daniel Loza. See [LICENSE.md](LICENSE.md).

## Generative AI declaration

I used Posit Assistant (built on Claude, via Posit AI Pass in Positron)
throughout the development of this assignment, for:

- scaffolding the R package structure (`DESCRIPTION`, `data-raw/`,
  `inst/app/`, roxygen documentation, `pkgdown` configuration);
- writing and iterating on the data cleaning script, including identifying
  and resolving a corrupted value in the source CSV;
- building and substantially revising the Shiny app, including diagnosing
  and fixing several `plotly`/`ggplotly` integration issues (e.g. invisible
  background shading, a malformed legend, and low-contrast hover text);
- researching and sourcing the app's colour palette and icons from official
  Public Transport Victoria assets, and verifying fare-discount dates
  against official government sources;
- identifying and correcting a methodological issue in the patronage
  indexing approach (an unaddressed seasonality confound, and later an
  overstated free-travel period that didn't distinguish weekend-only from
  every-day free travel);
- refactoring app code into the package's `R/` directory as internal
  functions, instead of loose script-level code;
- drafting this README, the package vignette, and `_pkgdown.yml`.

I reviewed, tested, and revised all generated code and text, ran
`devtools::check()` throughout to verify correctness, and take full
responsibility for the content of this submission.

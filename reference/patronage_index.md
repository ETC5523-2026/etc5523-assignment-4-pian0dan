# Index monthly patronage to the same calendar month in a reference year

Rescales each mode's monthly patronage as a percentage of that *same
calendar month* in a chosen reference year (e.g. March is compared to
the reference year's March, January to the reference year's January).
This avoids conflating genuine recovery with ordinary seasonal
variation: Victorian metropolitan train patronage, for example, is
routinely 30-35% higher in March or May than in January even in
pre-pandemic years, so indexing every month to a single fixed baseline
month would make seasonal swings look like changes in recovery.

## Usage

``` r
patronage_index(data, reference_year = 2019)
```

## Arguments

- data:

  A data frame with the same structure as
  [monthly_patronage](https://etc5523-2026.github.io/etc5523-assignment-4-pian0dan/reference/monthly_patronage.md),
  containing at least the columns `date`, `year`, `month`, `mode` and
  `patronage`.

- reference_year:

  An integer giving the year whose monthly values are used as the 100
  baseline for the matching calendar month. Defaults to 2019, the last
  full year before the COVID-19 pandemic affected patronage.

## Value

A data frame with the same rows as `data`, plus an `index` column giving
each mode's patronage as a percentage of the same calendar month's
patronage in `reference_year`.

## Examples

``` r
indexed <- patronage_index(monthly_patronage, reference_year = 2019)
head(indexed)
#>                   mode month       date year month_name patronage  fare_period
#> 103 Metropolitan train     1 2018-01-01 2018    January  16809932 Normal fares
#> 136 Metropolitan train     2 2018-02-01 2018   February  19554477 Normal fares
#> 145 Metropolitan train     3 2018-03-01 2018      March  22659010 Normal fares
#> 155 Metropolitan train     4 2018-04-01 2018      April  20312040 Normal fares
#> 165 Metropolitan train     5 2018-05-01 2018        May  22768447 Normal fares
#> 174 Metropolitan train     6 2018-06-01 2018       June  19284755 Normal fares
#>     baseline_patronage     index
#> 103           17074623  98.44980
#> 136           20011823  97.71462
#> 145           22250796 101.83460
#> 155           18579825 109.32310
#> 165           23045436  98.79807
#> 174           19099513 100.96988
```

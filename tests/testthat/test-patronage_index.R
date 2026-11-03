toy <- data.frame(
  date = as.Date(c("2019-01-01", "2019-02-01", "2020-01-01", "2020-02-01")),
  year = c(2019, 2019, 2020, 2020),
  month = c(1, 2, 1, 2),
  mode = "Tram",
  patronage = c(100, 200, 50, 300)
)

test_that("reference year indexes to 100", {
  out <- patronage_index(toy, reference_year = 2019)
  expect_true(all(out$index[out$year == 2019] == 100))
})

test_that("each month is compared to the same month in the reference year", {
  out <- patronage_index(toy, reference_year = 2019)
  expect_equal(out$index[out$year == 2020], c(50, 150))
})

test_that("a different reference year changes the baseline", {
  out <- patronage_index(toy, reference_year = 2020)
  expect_equal(out$index[out$year == 2019], c(200, 100 * 200 / 300))
})

test_that("rows are preserved and sorted by mode then date", {
  out <- patronage_index(toy)
  expect_equal(nrow(out), nrow(toy))
  expect_false(is.unsorted(out$date))
})

test_that("modes are indexed independently", {
  two <- rbind(toy, transform(toy, mode = "Bus", patronage = patronage * 10))
  out <- patronage_index(two)
  expect_equal(
    out$index[out$mode == "Bus"],
    out$index[out$mode == "Tram"]
  )
})

test_that("bundled data indexes to 100 in the default reference year", {
  out <- patronage_index(monthly_patronage)
  expect_equal(nrow(out), nrow(monthly_patronage))
  expect_true(all(out$index[out$year == 2019] == 100))
})

test_that("missing columns give an informative error", {
  expect_error(patronage_index(toy[, c("date", "year")]), "must contain")
})

test_that("an absent reference year gives an informative error", {
  expect_error(patronage_index(toy, reference_year = 1999), "No rows found")
})

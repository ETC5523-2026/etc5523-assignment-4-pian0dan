test_that("contiguous flagged months collapse into one block", {
  d <- data.frame(
    date = as.Date(c("2025-12-01", "2026-01-01", "2026-02-01")),
    fare_period = c(
      "Weekend free travel",
      "Weekend free travel",
      "Normal fares"
    )
  )
  r <- fare_period_rects(d, "Weekend free travel")
  expect_equal(nrow(r), 1)
  expect_equal(r$xmin, as.Date("2025-12-01"))
  expect_equal(r$fare_period, "Weekend free travel")
})

test_that("blocks run to the start of the month after the last flagged month", {
  d <- data.frame(
    date = as.Date(c("2026-04-01", "2026-05-01")),
    fare_period = "Free travel (every day)"
  )
  r <- fare_period_rects(d, "Free travel (every day)")
  expect_gte(r$xmax, as.Date("2026-06-01"))
  expect_lte(r$xmax, as.Date("2026-06-04"))
})

test_that("separate runs of the same period give separate blocks", {
  d <- data.frame(
    date = as.Date(c("2025-01-01", "2025-02-01", "2025-06-01")),
    fare_period = "Half-price fares"
  )
  r <- fare_period_rects(d, "Half-price fares")
  expect_equal(nrow(r), 2)
  expect_equal(r$xmin, as.Date(c("2025-01-01", "2025-06-01")))
})

test_that("duplicate dates across modes do not create extra blocks", {
  d <- data.frame(
    date = rep(as.Date(c("2026-04-01", "2026-05-01")), each = 6),
    fare_period = "Free travel (every day)"
  )
  expect_equal(nrow(fare_period_rects(d, "Free travel (every day)")), 1)
})

test_that("a period with no flagged months returns an empty, typed data frame", {
  r <- fare_period_rects(vicptpatronage::monthly_patronage, "No such period")
  expect_equal(nrow(r), 0)
  expect_named(r, c("xmin", "xmax", "fare_period"))
  expect_s3_class(r$xmin, "Date")
})

test_that("works on the bundled data", {
  r <- fare_period_rects(
    vicptpatronage::monthly_patronage,
    "Free travel (every day)"
  )
  expect_equal(nrow(r), 1)
  expect_equal(r$xmin, as.Date("2026-04-01"))
})

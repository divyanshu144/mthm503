
source(here::here("R", "load_data.R"))
# source(here::here("R", "impute_missing.R"))
# source(here::here("R", "clean_ped_df.R"))

test_that("mocked data is returned with CI", {
  withr::with_envvar(c(CI = "true"), {
    df <- load_data()
    expect_true(is.data.frame(df))
    expect_true(all(c("casualty_severity", "sex_of_casualty") %in% names(df)))
  })
})

test_that("impute_missing handles NAs correctly", {
  df <- data.frame(
    age = c(20, 30, NA, 40),
    speed = c(NA, 45, 55, 65),
    gender = factor(c("Male", NA, "Female", NA)),
    stringsAsFactors = TRUE
  )
  
  result <- impute_missing(df)
  
  expect_false(any(is.na(result$age)))
  expect_false(any(is.na(result$speed)))
  expect_true("Missing" %in% levels(result$gender))
  expect_false(any(is.na(result$gender)))
})

test_that("clean_ped_df drops unused factor levels", {
  df <- data.frame(
    severity = factor(c("Slight", "Serious"), levels = c("Slight", "Serious", "Fatal", "Missing")),
    value = c(1, 2)
  )
  
  cleaned <- clean_ped_df(df)
  
  expect_false("Fatal" %in% levels(cleaned$severity))
  expect_false("Missing" %in% levels(cleaned$severity))
})
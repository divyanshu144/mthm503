# Task 2: Modeling Fire Brigade Extrication Rates
# --------------------------------------------------
# This script processes fire brigade casualty extrication data,
# and fits a Poisson GLM to examine effects of age and sex.

# ─────────────────────────────
# TASK 2: REGRESSION MODELING OF EXTRICATION RATES
# ─────────────────────────────

library(dplyr)
library(tidyr)
library(forcats)
library(broom)
library(ggplot2)
library(lubridate)

# Load and merge extrication + year summary
load_extrication_data <- function(fire_data, year_data) {
  
  year_summary <- year_data %>%
    group_by(financial_year) %>%
    summarise(
      total_collisions = sum(number_of_stat19_reported_casualties, na.rm = TRUE),
      .groups = "drop"
    )
  
  counted_fire <- fire_data %>%
    filter(!is.na(extrication), extrication != "Unknown") %>%
    group_by(financial_year, sex, age_band) %>%
    summarise(extrications = sum(n_casualties), .groups = "drop")
  
  joined <- counted_fire %>%
    left_join(year_summary, by = "financial_year") %>%
    rename(
      collisions_reported = total_collisions,
      sex_of_casualty = sex,
      age_band_raw = age_band
    ) %>%
    mutate(
      age_band_of_casualty = case_when(
        age_band_raw == "0-16" ~ "0-17",
        age_band_raw %in% c("17-24", "25-39") ~ "18-34",
        age_band_raw == "40-64" ~ "35-64",
        age_band_raw == "65+" ~ "65+",
        TRUE ~ NA_character_
      ),
      rate = extrications / collisions_reported,
      sex_of_casualty = factor(sex_of_casualty),
      age_band_of_casualty = factor(age_band_of_casualty, levels = c("0-17", "18-34", "35-64", "65+"))
    ) %>%
    drop_na(sex_of_casualty, age_band_of_casualty)
  
  return(joined)
}

# Clean the data
clean_extrication_dataset <- function(df) {
  df %>%
    mutate(
      sex_of_casualty = factor(sex_of_casualty),
      age_group = age_band_of_casualty
    ) %>%
    drop_na(sex_of_casualty, age_group)
}

# Fit Poisson regression
fit_poisson_model <- function(df) {
  glm(
    extrications ~ age_band_of_casualty * sex_of_casualty + offset(log(collisions_reported)),
    data = df,
    family = poisson(link = "log")
  )
}

fit_nb_model <- function(df) {
  library(MASS)
  glm.nb(
    extrications ~ age_band_of_casualty * sex_of_casualty + offset(log(collisions_reported)),
    data = df
  )
}

# Summarise model output
summarize_poisson_model <- function(mod) {
  broom::tidy(mod, conf.int = TRUE, exponentiate = TRUE) %>%
    mutate(term = recode(term,
                         `(Intercept)` = "Baseline (0–17, Female)",
                         `age_band_of_casualty18-34` = "Age 18–34",
                         `age_band_of_casualty35-64` = "Age 35–64",
                         `age_band_of_casualty65+` = "Age 65+",
                         `sex_of_casualtyMale` = "Male",
                         `age_band_of_casualty18-34:sex_of_casualtyMale` = "18–34 × Male",
                         `age_band_of_casualty35-64:sex_of_casualtyMale` = "35–64 × Male",
                         `age_band_of_casualty65+:sex_of_casualtyMale` = "65+ × Male"))
}
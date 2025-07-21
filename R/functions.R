library(dplyr)
library(mgcv)
library(lubridate)
library(forcats)

utils::globalVariables(c(
  "casualty_severity", "age_of_driver", "sex_of_driver", "accident_index",
  "casualty_class", "age_of_casualty", "sex_of_casualty", "weather_conditions",
  "light_conditions", "speed_limit_mph", "urban_or_rural_area", "obs_date",
  "obs_datetime"
))

summarise_data <- function(df) {
  df %>%
    mutate(casualty_severity = as.factor(casualty_severity)) %>%
    group_by(casualty_severity) %>%
    summarise(Casualties = n(), .groups = "drop")
}

build_vehicle_summary <- function(vehicles) {
  vehicles %>%
    mutate(
      age_of_driver = na_if(age_of_driver, -1),
      sex_of_driver = factor(sex_of_driver)
    ) %>%
    group_by(accident_index) %>%
    summarise(
      total_vehicles = n(),
      avg_driver_age = mean(age_of_driver, na.rm = TRUE),
      prop_male_driver = mean(sex_of_driver == "Male", na.rm = TRUE),
      .groups = "drop"
    )
}

build_ped_df <- function(casualties, accidents, veh_sum) {
  casualties %>%
    filter(casualty_class == "Pedestrian") %>%
    left_join(accidents, by = "accident_index") %>%
    left_join(veh_sum, by = "accident_index") %>%
    transmute(
      severity = factor(casualty_severity, levels = 
                          c("Slight", "Serious", "Fatal")),
      ped_age = age_of_casualty,
      ped_sex = factor(sex_of_casualty),
      avg_driver_age,
      prop_male_driver,
      weather = factor(weather_conditions),
      light = factor(light_conditions),
      speed_limit = speed_limit_mph,
      urban_rural = factor(urban_or_rural_area),
      total_vehicles,
      obs_datetime = ymd_hms(obs_date)
    ) %>%
    mutate(
      hour = hour(obs_datetime),
      weekend = wday(obs_datetime, label = TRUE) %in% c("Sat", "Sun")
    ) %>%
    select(-obs_datetime)
}

clean_ped_df <- function(ped_df, missing_thresh = 0.5) {
  ped_df %>%
    drop_sparse_cols(threshold = missing_thresh) %>%
    impute_missing()
}

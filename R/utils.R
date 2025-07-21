# R/utils.R

library(dplyr)
library(tidyr)
library(forcats)
df
# Calculate percent missing per column (0–100%)
missing_pct <- function(df) {
  df %>%
    summarise(across(everything(), ~ mean(is.na(.)))) %>%
    pivot_longer(everything(),
                 names_to  = "feature",
                 values_to = "pct_missing") %>%
    mutate(pct_missing = pct_missing * 100)
}

# Drop columns with > threshold fraction of missing values
drop_sparse_cols <- function(df, threshold = 0.5) {
  pct   <- df %>% summarise(across(everything(), ~ mean(is.na(.)))) %>% unlist()
  keep  <- names(pct)[pct <= threshold]
  df %>% select(all_of(keep))
}

# Impute numerics with median, factors with explicit "Missing"
impute_missing <- function(df) {
  df %>%
    mutate(
      across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)),
      across(where(is.factor), ~fct_na_value_to_level(., level = "Missing")) )%>%
    droplevels()
}
# _targets.R

library(targets)
library(tarchetypes)
library(here)

# Source your helper scripts
source(here("R", "load_data.R"))
source(here("R", "utils.R"))
source(here("R", "functions.R"))

# Declare packages for all targets
tar_option_set(
  packages = c(
    "DBI","RPostgres","RSQLite","here",
    "dplyr","lubridate","forcats",
    "caret","pROC","MLmetrics","kernlab", "ranger"
  )
)

# Define the pipeline
list(
  # 1. Load raw tables
  tar_target(
    raw_casualties,
    load_data()
  ),
  tar_target(
    accidents,
    {
      con <- get_db_connection()
      df  <- DBI::dbGetQuery(con, "SELECT * FROM stats19_accidents;")
      DBI::dbDisconnect(con)
      df
    }
  ),
  tar_target(
    vehicles,
    {
      con <- get_db_connection()
      df  <- DBI::dbGetQuery(con, "SELECT * FROM stats19_vehicles;")
      DBI::dbDisconnect(con)
      df
    }
  ),
  
  # 2. Quick severity summary
  tar_target(
    summary_data,
    summarise_data(raw_casualties)
  ),
  
  # 3. Build & clean pedestrian data
  tar_target(
    veh_sum,
    build_vehicle_summary(vehicles)
  ),
  tar_target(
    ped_raw,
    build_ped_df(raw_casualties, accidents, veh_sum)
  ),
  tar_target(
    ped_clean,
    clean_ped_df(ped_raw)
  ),
  
  # 4. Train/test split (80/20)
  tar_target(
    split_idx,
    createDataPartition(ped_clean$severity, p = 0.8, list = FALSE)
  ),
  tar_target(
    train_df,
    ped_clean[split_idx, ],
    pattern = map(split_idx)
  ),
  tar_target(
    test_df,
    ped_clean[-split_idx, ],
    pattern = map(split_idx)
  ),
  
  # 5. Model training: Random Forest & SVM
  tar_target(
    rf_fit,
    train(
      severity ~ ., data = train_df,
      method    = "ranger",
      trControl = trainControl(
        method          = "cv",
        number          = 5,
        classProbs      = TRUE,
        summaryFunction = multiClassSummary
      ),
      tuneLength = 5
    )
  ),
  tar_target(
    svm_fit,
    train(
      severity ~ ., data = train_df,
      method    = "svmRadial",
      trControl = trainControl(
        method          = "cv",
        number          = 5,
        classProbs      = TRUE,
        summaryFunction = multiClassSummary
      ),
      tuneLength = 5
    )
  ),
  
  # 6. Model evaluation
  tar_target(
    rf_eval,
    {
      preds <- predict(rf_fit, test_df)
      probs <- predict(rf_fit, test_df, type = "prob")
      cm   <- confusionMatrix(preds, test_df$severity)
      auc  <- multiclass.roc(test_df$severity, probs)$auc
      list(confusion = cm, auc = auc)
    }
  ),
  
  tar_target(
    svm_eval,
    {
      preds <- predict(svm_fit, test_df)
      probs <- predict(svm_fit, test_df, type = "prob")
      cm   <- confusionMatrix(preds, test_df$severity)
      auc  <- multiclass.roc(test_df$severity, probs)$auc
      list(confusion = cm, auc = auc)
    }
  ),
  
  # 7. Render the final report
  tar_render(
    report,
    path = "vignettes/Report.Rmd"
  )
)
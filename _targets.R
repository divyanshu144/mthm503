library(targets)
library(tarchetypes)
library(here)

# Source your helper scripts
source(here("R", "load_data.R"))
source(here("R", "utils.R"))
source(here("R", "functions.R"))
source(here("R", "Task-2.R"))
source(here("R", "Task-3.R"))

tar_option_set(
  packages = c(
    "DBI", "RPostgres", "RSQLite", "here",
    "dplyr", "lubridate", "forcats",
    "caret", "pROC", "MLmetrics", "kernlab", "ranger", "randomForest", "knitr", "ggplot2", "tibble", "gt", "kableExtra"
  )
)

list(
  tar_target(raw_casualties, load_data()),
  tar_target(accidents, read_accidents()),
  tar_target(vehicles, read_vehicles()),
  tar_target(summary_data, summarise_data(raw_casualties)),
  tar_target(veh_sum, build_vehicle_summary(vehicles)),
  tar_target(ped_raw, build_ped_df(raw_casualties, accidents, veh_sum)),
  tar_target(ped_clean, clean_ped_df(ped_raw)),
  tar_target(split_idx, createDataPartition(ped_clean$severity, p = 0.8, list = FALSE)),
  
  
  # tar_target(train_df, ped_clean[split_idx, ]),
  tar_target(
    train_df,
    {
      df <- ped_clean[split_idx, ]
      nzv <- nearZeroVar(df[, setdiff(names(df), "severity")], saveMetrics = TRUE)
      keep_cols <- rownames(nzv[nzv$nzv == FALSE, ])
      df <- df[, c("severity", keep_cols)]
      df
    }
  ),
  
  tar_target(test_df, ped_clean[-split_idx, ]),
  tar_target(
    selected_features,
    {
      control <- rfeControl(functions = rfFuncs, method = "cv", number = 5)
      rfe_result <- rfe(
        x = train_df[, setdiff(names(train_df), "severity")],
        y = train_df$severity,
        sizes = c(5, 10, 15),
        rfeControl = control
      )
      predictors(rfe_result)
    }
  ),
  tar_target(
    rf_fit,
    train(
      severity ~ ., data = train_df,
      method = "ranger",
      importance = "impurity",
      trControl = trainControl(
        method = "cv",
        number = 5,
        classProbs = TRUE,
        summaryFunction = multiClassSummary
      ),
      tuneLength = 5
    )
  ),
  tar_target(
    svm_fit,
    train(
      severity ~ ., data = train_df,
      method = "svmRadial",
      trControl = trainControl(
        method = "cv",
        number = 5,
        classProbs = TRUE,
        summaryFunction = multiClassSummary
      ),
      tuneLength = 5
    )
  ),
  tar_target(
    rf_eval,
    {
      preds <- predict(rf_fit, test_df)
      probs <- predict(rf_fit, test_df, type = "prob")
      cm <- confusionMatrix(preds, test_df$severity)
      auc <- multiclass.roc(test_df$severity, probs)$auc
      list(confusion = cm, auc = auc)
    }
  ),
  tar_target(
    svm_eval,
    {
      preds <- predict(svm_fit, test_df)
      probs <- predict(svm_fit, test_df, type = "prob")
      cm <- confusionMatrix(preds, test_df$severity)
      auc <- multiclass.roc(test_df$severity, probs)$auc
      list(confusion = cm, auc = auc)
    }
  ),
  
  # ─────────────────────────────
  # TASK 2: REGRESSION MODEL
  # ─────────────────────────────
  
  # 5. Load extrication data from DB
  tar_target(
    fire_data,
    load_extrication_data_from_db()
  ),
  
  # 6. Load STATS19 yearly summary
  tar_target(
    year_data,
    load_stats19_by_year()
  ),
  
  # 7. Merge and engineer extrication dataset
  tar_target(
    extrication_merged,
    load_extrication_data(fire_data, year_data)
  ),
  
  # 8. Clean extrication dataset for modeling
  tar_target(
    extrication_clean,
    clean_extrication_dataset(extrication_merged)
  ),
  
  # 9. Fit Poisson regression model
  tar_target(
    model_poisson_extrication,
    fit_poisson_model(extrication_clean)
  ),
  
  tar_target(
    model_nb_extrication,
    fit_nb_model(extrication_clean)
  ),
  tar_target(
    summary_nb_extrication,
    summarize_poisson_model(model_nb_extrication)
  ),
  
  # # 10. Summarize the Poisson model
  # tar_target(
  #   summary_poisson_extrication,
  #   summarize_poisson_model(model_poisson_extrication)
  # ),
  
 #------------------------------------------------------------
 
 # ─────────────────────────────
 # TASK 3: UNSUPERVISED CLUSTERING – Olive Oil
 # ─────────────────────────────
 tar_target(
   raw_olive_oil,
   load_olive_oil_from_db()
 ),
 tar_target(
   olive_data_clean,
   inspect_olive_data(raw_olive_oil)
 ),
 tar_target(
   olive_data_scaled,
   normalize_numeric_features(raw_olive_oil)
 ),
 tar_target(
   elbow_plot,
   calculate_elbow_plot(olive_data_scaled)
 ),
 tar_target(
   olive_clusters,
   perform_kmeans_clustering(olive_data_scaled, clusters = 5)
 ),
 tar_target(
   olive_pca_cluster_plot,
   visualize_clusters_pca(olive_data_scaled, olive_clusters)
 ),
 tar_target(
   kmeans_summary,
   summarize_cluster_output(olive_clusters)
 ),
 
 tar_target(
   silhouette_plot,
   generate_silhouette_plot(olive_data_scaled, olive_clusters)
 ),
 tar_target(
   silhouette_plot_path,
   save_silhouette_plot(olive_clusters, olive_data_scaled)
 ),
 
 tar_target(
   test_results,
   testthat::test_dir("tests/testthat", reporter = "summary"),
   format = "rds"
 ),
  
  tar_render(
    report,
    path = "vignettes/Report.Rmd"
  )
)
# TASK 3: Unsupervised Clustering on Olive Oil Dataset
# ----------------------------------------------------

# Load libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(cluster)
library(tibble)

# Step 1: Load and Inspect Data
inspect_olive_data <- function(data) {
  cat("\n🔍 Data Preview:\n")
  print(head(data))
  cat("\n📏 Structure:\n")
  print(str(data))
  cat("\n🧼 Missing Value Summary:\n")
  print(colSums(is.na(data)))
  return(data)
}

# Step 2: Visualize Distributions
plot_numeric_distributions <- function(data) {
  num_vars <- data %>% select(where(is.numeric)) %>% names()
  for (col in num_vars) {
    print(
      ggplot(data, aes_string(x = col)) +
        geom_histogram(bins = 30, fill = "darkgreen", color = "white") +
        theme_minimal() +
        ggtitle(paste("Distribution of", col))
    )
  }
}

# Step 3: Normalize Data
normalize_numeric_features <- function(data) {
  acid_features <- data %>% select(where(is.numeric))
  scaled <- scale(acid_features)
  return(as.data.frame(scaled))
}

# Step 4: Elbow Method for K
calculate_elbow_plot <- function(scaled_data, max_k = 10) {
  wss <- sapply(1:max_k, function(k) {
    kmeans(scaled_data, centers = k, nstart = 20)$tot.withinss
  })
  df_elbow <- data.frame(k = 1:max_k, wss = wss)
  ggplot(df_elbow, aes(x = k, y = wss)) +
    geom_line() +
    geom_point(size = 2) +
    labs(title = "Elbow Plot for Optimal k", x = "k (Clusters)", y = "Within-cluster SS") +
    theme_minimal()
}

# Step 5: K-Means Clustering
perform_kmeans_clustering <- function(scaled_data, clusters = 3) {
  set.seed(123)
  kmeans(scaled_data, centers = clusters, nstart = 25)
}

# Step 6: Visualize Clusters using PCA
visualize_clusters_pca <- function(scaled_data, cluster_result) {
  pca_model <- prcomp(scaled_data)
  pca_df <- as.data.frame(pca_model$x[, 1:2])
  pca_df$cluster <- as.factor(cluster_result$cluster)
  ggplot(pca_df, aes(x = PC1, y = PC2, color = cluster)) +
    geom_point(alpha = 0.8, size = 2.5) +
    labs(title = "Cluster Visualization via PCA", color = "Cluster") +
    theme_minimal()
}

# Step 7: Summarize Clustering Results
summarize_cluster_output <- function(cluster_result) {
  tibble(
    Total_WSS = cluster_result$tot.withinss,
    Between_SS = cluster_result$betweenss,
    Total_SS = cluster_result$totss,
    Ratio = round(cluster_result$betweenss / cluster_result$totss, 3),
    Sizes = paste(cluster_result$size, collapse = ", ")
  )
}

# Step 8: Silhouette Plot
generate_silhouette_plot <- function(scaled_data, cluster_result) {
  # Compute dissimilarity matrix
  dist_matrix <- dist(scaled_data)
  
  # Compute silhouette scores
  sil <- cluster::silhouette(cluster_result$cluster, dist_matrix)
  
  # Convert to data frame for ggplot
  sil_df <- as.data.frame(sil)
  sil_df$cluster <- as.factor(sil_df$cluster)
  
  # Plot
  ggplot(sil_df, aes(x = cluster, y = sil_width, fill = cluster)) +
    geom_boxplot(alpha = 0.7) +
    labs(
      title = "Silhouette Plot of Cluster Quality",
      x = "Cluster",
      y = "Silhouette Width"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
}

# Save silhouette plot to file
save_silhouette_plot <- function(cluster_result, scaled_data, path = "vignettes/silhouette_plot.png") {
  library(cluster)
  sil <- silhouette(cluster_result$cluster, dist(scaled_data))
  png(filename = path, width = 800, height = 600)
  plot(sil, main = "Silhouette Plot for K-Means Clustering")
  dev.off()
  return(path)
}
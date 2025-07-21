

get_db_connection <- function() {
  is_ci <- Sys.getenv("CI") == "true"
  if (is_ci) {
    # CI path: return SQLite connection (in-memory)
    DBI::dbConnect(
      RSQLite::SQLite(),
      here::here("mock_data", "mockdb.sqlite")
    )
  } else {
    # Production path: return Postgres connection
    DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = Sys.getenv("PGRDATABASE"),
      host = Sys.getenv("PGRHOST"),
      user = Sys.getenv("PGRUSER"),
      password = Sys.getenv("PGRPASSWORD"),
      port = Sys.getenv("PGRPORT")
    )
  }
}

load_data <- function() {
  con <- get_db_connection()
  sql <- "SELECT * FROM stats19_casualties"
  df <- DBI::dbGetQuery(con, sql)
  DBI::dbDisconnect(con)
  df
}

read_accidents <- function() {
  con <- get_db_connection()
  df <- DBI::dbGetQuery(con, "SELECT * FROM stats19_accidents;")
  DBI::dbDisconnect(con)
  df
}

read_vehicles <- function() {
  con <- get_db_connection()
  df <- DBI::dbGetQuery(con, "SELECT * FROM stats19_vehicles;")
  DBI::dbDisconnect(con)
  df
}

# -------------------------- Task 2 -----------------------------------

load_extrication_data_targets <- function() {
  tar_read("fire_rescue_extrication_casualties")
}

load_extrication_data <- function() {
  con <- get_db_connection()
  df <- DBI::dbReadTable(con, "fire_rescue_extrication_casualties")
  DBI::dbDisconnect(con)
  df
}

load_stats19_by_year_targets <- function() {
  tar_read("stats19_by_financial_year")
}

load_stats19_by_year <- function() {
  con <- get_db_connection()
  df <- DBI::dbReadTable(con, "stats19_by_financial_year")
  DBI::dbDisconnect(con)
  df
}

load_extrication_data_from_db <- function() {
  con <- get_db_connection()
  df <- DBI::dbReadTable(con, "fire_rescue_extrication_casualties")
  DBI::dbDisconnect(con)
  df
}

# -------------------------- Task 3 -----------------------------------

load_olive_oil_from_db <- function() {
  con <- get_db_connection()
  df <- DBI::dbReadTable(con, "olive_oil")
  DBI::dbDisconnect(con)
  df
}

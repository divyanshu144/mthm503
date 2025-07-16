get_db_connection <- function() {
  is_ci <- Sys.getenv("CI") == "true"

  if (is_ci) {
    # CI path: return SQLite connection (in-memory)
    DBI::dbConnect(RSQLite::SQLite(), here::here("mock_data", "mockdb.sqlite"))
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

  sql_text <- "
    SELECT *
    FROM stats19_casualties
  "
  df <- DBI::dbGetQuery(con, sql_text)

  DBI::dbDisconnect(con)
  df
}


# Read the full accidents table
read_accidents <- function() {
  con <- get_db_connection()
  df  <- DBI::dbGetQuery(con, "SELECT * FROM stats19_accidents;")
  DBI::dbDisconnect(con)
  df
}

# Read the full vehicles table
read_vehicles <- function() {
  con <- get_db_connection()
  df  <- DBI::dbGetQuery(con, "SELECT * FROM stats19_vehicles;")
  DBI::dbDisconnect(con)
  df
}



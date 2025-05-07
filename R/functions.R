#' Import data from the DIME study data set
#'
#' @param file_path Path to the CSV file
#'
#' @returns A data frame
#'
import_dime <- function(file_path) {
  data <- file_path %>%
    readr::read_csv(
      show_col_types = FALSE,
      name_repair = snakecase::to_snake_case,
      n_max = 100
    )

  return(data)
}


#' Import all DIME csv files in a folder into one data frame
#'
#' @param folder_path The path to the folder that has the CSV files
#'
#' @returns A single data frame/tibble
#'
import_csv_files <- function(folder_path) {
  files <- folder_path %>%
    fs::dir_ls(glob = "*.csv")

  data <- files %>%
    purrr::map(import_dime) %>%
    purrr::list_rbind(names_to = "file_path_id")
  return(data)
}


#' A function with regex for ID extraction
#'
#' @param data Which data we want to look at
#'
#' @returns Data with regex
#'
get_participant_id <- function(data) {
  data_with_id <- data %>%
    dplyr::mutate(
      id = stringr::str_extract(
        file_path_id,
        "[:digit:]+\\.csv$"
      ) %>%
        stringr::str_remove("\\.csv$") %>%
        as.integer(),
      .before = file_path_id
    ) %>%
    dplyr::select(-file_path_id)

  return(data_with_id)
}


#' Split up and change column names
#'
#' @param data The data frame we look at
#' @param column The column that we need to spilt up
#'
#' @returns Prepared data
#'
prepare_dates <- function(data, column) {
  prepared_dates <- data %>%
    mutate(
      date = as_date({{ column }}),
      hour = hour({{ column }}),
      .before = {{ column }}
    )

  return(prepared_dates)
}


#' Cleaned and prepare the CGM data for joining
#'
#'
#' @param data The CGM dataset
#'
#' @returns A cleaner data frame
#'
clean_cgm <- function(data) {
  cleaned <- data %>%
    get_participant_id() %>%
    prepare_dates(device_timestamp) %>%
    dplyr::rename(glucose = historic_glucose_mmol_l)

  return(cleaned)
}

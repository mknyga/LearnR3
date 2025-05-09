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
      name_repair = snakecase::to_snake_case
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
#' @param data The CGM data set
#'
#' @returns A cleaner data frame
#'
clean_cgm <- function(data) {
  cleaned <- data %>%
    get_participant_id() %>%
    prepare_dates(device_timestamp) %>%
    dplyr::rename(glucose = historic_glucose_mmol_l) %>%
    summarize_column(glucose, list(
      mean = mean,
      sd = sd
    ))

  return(cleaned)
}


#' Summarize a single column based one or more functions
#'
#' @param data Either the CGM or sleep data in DIME
#' @param column The column we want to summarzise = glucose
#' @param functions One or more functions to apply to the column. If more than one added, use list()
#'
#' @returns
#'
summarize_column <- function(data, column, functions) {
  summarized_data <- data %>%
    dplyr::select(-tidyselect::contains("timestamp"), -tidyselect::contains("datetime")) %>%
    dplyr::group_by(dplyr::pick(-{{ column }})) %>%
    dplyr::summarise(
      dplyr::across(
        {{ column }},
        functions
      ),
      .groups = "drop"
    )

  return(summarized_data)
}


#' Cleaned and prepare the sleep data for joining
#'
#' @param data The sleep data set
#'
#' @returns A cleaner data frame
#'
clean_sleep <- function(data) {
  cleaned <- data %>%
    get_participant_id() |>
    dplyr::rename(datetime = date) %>%
    prepare_dates(datetime) %>%
    summarize_column(seconds, list(sum = sum)) %>%
    sleep_types_to_wider()

  return(cleaned)
}


#' Convert the participant details data to long and clean it up
#'
#' @param data The DIME participant detail data
#'
#' @returns A data frame
#'
clean_participant_detail <- function(data) {
  cleaned <- data %>%
    tidyr::pivot_longer(tidyselect::ends_with("date"), names_to = NULL, values_to = "date") %>%
    dplyr::group_by(dplyr::pick(-date)) %>%
    tidyr::complete(
      date = seq(min(date), max(date), by = "1 day")
    )

  return(cleaned)
}


#' Sleep data from DIME to wider
#'
#' @param data Sleep data
#'
#' @returns A wider data frame
#'
sleep_types_to_wider <- function(data) {
  wider <- data %>%
    tidyr::pivot_wider(names_from = sleep_type, values_from = seconds_sum, names_prefix = "seconds_")

  return(wider)
}


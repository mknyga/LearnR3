#' Import data from thr DIME study dataset
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

#' Import DIME csv files
#'
#' @param folder_path Path to DIME data
#'
#' @returns Returns to all the data frame
#'
import_csv_files <- function(folder_path) {
  files <- folder_path %>%
    fs::dir_ls(glob = "*.csv")
  data <- files %>%
    purrr::map(import_dime) %>%
    purrr::list_rbind(names_to = "file_path_id")

  return(data)
}

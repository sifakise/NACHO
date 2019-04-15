#' geometric_housekeeping
#'
#' @param data [data.frame] A \code{data.frame} with the count data.
#' @param positive_factor [vector(numeric)] A \code{vector(numeric)} with the positive probe
#'   normalisation factor.
#' @param intercept [vector(numeric)] A \code{vector(numeric)} with the average counts value.
#' @inheritParams summarise
#'
#' @keywords internal
#'
#' @return [numeric]
geometric_housekeeping <- function(data, positive_factor, intercept, housekeeping_genes) {
  house_data <- as.data.frame(data[, c("Name", "CodeClass", "Count")])
  if (is.null(housekeeping_genes)) {
    house_data <- house_data[house_data[["CodeClass"]] %in% "Housekeeping", ]
  } else {
    house_data <- house_data[house_data[["Name"]] %in% housekeeping_genes, ]
  }

  house_data[["Count"]] <- house_data[["Count"]] - intercept
  house_data[["Count"]] <- house_data[["Count"]] * positive_factor
  house_data[["Count"]][house_data[["Count"]] <= 0] <- 1
  geometric_mean(house_data[["Count"]])
}
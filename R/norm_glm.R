#' norm_glm
#'
#' @param data [[data.frame]] A `list` of `data.frame` with the count data.
#'
#' @keywords internal
#' @usage NULL
#'
#' @return [[list]]
norm_glm <- function(data) {
  progress <- dplyr::progress_estimated(length(data)+1)
  glms <- sapply(
    X = data,
    FUN = function(.data) {
      progress$tick()$print()
      control_labels <- c("Positive", "Negative")
      .data <- .data[.data[["CodeClass"]] %in% control_labels, ]
      y <- .data[["Count"]] + 1
      check_name <- grepl("^[^(]*\\((.*)\\)$", .data[["Name"]])
      if (all(check_name)) {
        x <- as.numeric(gsub("^[^(]*\\((.*)\\)$", "\\1", .data[["Name"]]))
      } else {
        x <- c(NEG = 0, POS = 32)[gsub("(NEG).*|(POS).*", "\\1\\2", .data[["Name"]])]
      }
      stats::glm(y ~ x, family = stats::poisson(link = "identity"))$coeff[c(1, 2)]
    }
  )
  progress$pause(0.05)$tick()$print()
  cat("\n")

  list(
    geometric_mean_neg = glms[1, ],
    positive_factor = mean(glms[2, ]) / glms[2, ]
  )
}


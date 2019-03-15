#' normalise
#'
#' @param nacho_object [list] List obtained from \code{\link{summarise}} or \code{\link{normalise}}.
#' @inheritParams summarise
#' @param remove_outliers [logical] A boolean to indicate if outliers should be excluded.
#'
#' @details Outliers definition (\code{remove_outliers}):
#' \itemize{
#'  \item Binding Density (\code{BD}) < 0.1
#'  \item Binding Density (\code{BD}) > 2.25
#'  \item Imaging (\code{FoV}) < 75
#'  \item Positive Control Linearity (\code{PC}) < 0.95
#'  \item Limit of Detection (\code{LoD}) < 2
#'  \item Positive normalisation factor (\code{Positive_factor}) < 0.25
#'  \item Positive normalisation factor (\code{Positive_factor}) > 4
#'  \item Housekeeping normalisation factor (\code{house_factor}) < 1/11
#'  \item Housekeeping normalisation factor (\code{house_factor}) > 11
#' }
#'
#' @return [list] A list containing parameters and data.
#' \describe{
#'   \item{access}{[character] Value passed to \code{\link{summarise}} in \code{id_colname}.}
#'   \item{housekeeping_genes}{[character] Value passed to \code{\link{summarise}} or \code{\link{normalise}}.}
#'   \item{housekeeping_predict}{[logical] Value passed to \code{\link{summarise}}.}
#'   \item{housekeeping_norm}{[logical] Value passed to \code{\link{summarise}} or \code{\link{normalise}}.}
#'   \item{normalisation_method}{[character] Value passed to \code{\link{summarise}} or \code{\link{normalise}}.}
#'   \item{remove_outliers}{[logical] Value passed to \code{\link{normalise}}.}
#'   \item{n_comp}{[ numeric] Value passed to \code{\link{summarise}}.}
#'   \item{data_directory}{[character] Value passed to \code{\link{summarise}}.}
#'   \item{pc_sum}{[data.frame] A \code{data.frame} with \code{n_comp} rows and four columns:
#'    "Standard deviation", "Proportion of Variance", "Cumulative Proportion" and "PC".}
#'   \item{nacho}{[data.frame] A \code{data.frame} with all columns from the sample sheet \code{ssheet_csv}
#'   and all computed columns, i.e., quality-control metrics and counts, with one sample per row.}
#'   \item{raw_counts}{[data.frame] Raw counts with probes as rows and samples as columns.
#'   With \code{"CodeClass"} (first column), the type of the probes and
#'   \code{"Name"} (second column), the Name of the probes.}
#'   \item{normalised_counts}{[data.frame] Normalised counts with probes as rows and samples as columns.
#'   With \code{"CodeClass"} (first column)), the type of the probes and
#'   \code{"Name"} (second column), the name of the probes.}
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(GEOquery)
#' library(NACHO)
#'
#' # Import data from GEO
#' gse <- GEOquery::getGEO(GEO = "GSE74821")
#' targets <- Biobase::pData(Biobase::phenoData(gse[[1]]))
#' GEOquery::getGEOSuppFiles(GEO = "GSE74821", baseDir = tempdir())
#' utils::untar(
#'   tarfile = paste0(tempdir(), "/GSE74821/GSE74821_RAW.tar"),
#'   exdir = paste0(tempdir(), "/GSE74821")
#' )
#' targets$IDFILE <- list.files(
#'   path = paste0(tempdir(), "/GSE74821"),
#'   pattern = ".RCC.gz$"
#' )
#' targets[] <- lapply(X = targets, FUN = iconv, from = "latin1", to = "ASCII")
#' utils::write.csv(
#'   x = targets,
#'   file = paste0(tempdir(), "/GSE74821/Samplesheet.csv")
#' )
#'
#'
#' # Read RCC files and format
#' nacho <- summarise(
#'    data_directory = paste0(tempdir(), "/GSE74821"),
#'    ssheet_csv = paste0(tempdir(), "/GSE74821/Samplesheet.csv"),
#'    id_colname = "IDFILE",
#'    housekeeping_genes = NULL,
#'    housekeeping_predict = FALSE,
#'    housekeeping_norm = TRUE,
#'    normalisation_method = "GEO",
#'    n_comp = 10
#' )
#'
#'
#' # (re)Normalise data
#' nacho_norm <- normalise(
#'   nacho_object = nacho,
#'   housekeeping_genes = nacho[["housekeeping_genes"]],
#'   housekeeping_norm = TRUE,
#'   normalisation_method = "GEO",
#'   remove_outliers = TRUE
#' )
#'
#' }
#'
normalise <- function(
  nacho_object,
  housekeeping_genes = nacho_object[["housekeeping_genes"]],
  housekeeping_norm = nacho_object[["housekeeping_norm"]],
  normalisation_method = nacho_object[["normalisation_method"]],
  remove_outliers = TRUE
) {
  if (missing(nacho_object)) {
    stop('[NACHO] "nacho_object" must be provided.')
  }
  mandatory_fields <- c(
    "access",
    "housekeeping_genes",
    "housekeeping_predict",
    "housekeeping_norm",
    "normalisation_method",
    "remove_outliers",
    "n_comp",
    "data_directory",
    "pc_sum",
    "nacho",
    "raw_counts",
    "normalised_counts"
  )
  if (!all(mandatory_fields%in%names(nacho_object))) {
    stop('[NACHO] "summarise()" must be used before "normalise()".')
  }

  id_colname <- nacho_object[["access"]]
  type_set <- attr(nacho_object, "RCC_type")

  if (!isTRUE(all.equal(sort(nacho_object[["housekeeping_genes"]]), sort(housekeeping_genes)))) {
    message(
      paste0(
        '[NACHO] Note: "housekeeping_genes" is different from the parameter used in "summarise()".\n',
        '- "summarise()":\n',
        '    housekeeping_genes=c("', paste(nacho_object[["housekeeping_genes"]], collapse = '", "'), '")\n',
        '- "normalise()":\n',
        '    housekeeping_genes=c("', paste(housekeeping_genes, collapse = '", "'), '")\n'
      )
    )
  }

  if (nacho_object[["housekeeping_norm"]]!=housekeeping_norm) {
    message(
      paste0(
        '[NACHO] Note: "housekeeping_norm" is different from the parameter used in "summarise()".\n',
        '- "summarise()":\n',
        '    housekeeping_norm=', nacho_object[["housekeeping_norm"]], '\n',
        '- "normalise()":\n',
        '    housekeeping_norm=', housekeeping_norm, '\n'
      )
    )
  }

  if (nacho_object[["normalisation_method"]]!=normalisation_method) {
    message(
      paste0(
        '[NACHO] Note: "normalisation_method" is different from the parameter usedin "summarise()".\n',
        '- "summarise()":\n',
        '    normalisation_method="', nacho_object[["normalisation_method"]], '"\n',
        '- "normalise()":\n',
        '    normalisation_method="', normalisation_method, '"\n'
      )
    )
  }

  if (nacho_object[["remove_outliers"]]) {
    message("[NACHO] Outliers have already been removed!")
  }

  if (remove_outliers & !nacho_object[["remove_outliers"]]) {
    nacho_df <- exclude_outliers(object = nacho_object)
    outliers <- setdiff(
      unique(nacho_object[["nacho"]][[nacho_object[["access"]]]]),
      unique(nacho_df[[nacho_object[["access"]]]])
    )
    if (length(outliers)!=0) {
      nacho_object <- qc_rcc(
        data_directory = nacho_object[["data_directory"]],
        nacho_df = nacho_df,
        id_colname = id_colname,
        housekeeping_genes = housekeeping_genes,
        housekeeping_predict = FALSE,
        housekeeping_norm = housekeeping_norm,
        normalisation_method = normalisation_method,
        n_comp = nacho_object[["n_comp"]]
      )
    }
    nacho_object[["remove_outliers"]] <- remove_outliers
  }

  nacho_object[["nacho"]][["Count_Norm"]] <- normalise_counts(
    data = nacho_object[["nacho"]],
    housekeeping_norm = housekeeping_norm
  )

  raw_counts <- format_counts(
    data = nacho_object[["nacho"]],
    id_colname = id_colname,
    count_column = "Count"
  )
  nacho_object[["raw_counts"]] <- raw_counts

  norm_counts <- format_counts(
    data = nacho_object[["nacho"]],
    id_colname = id_colname,
    count_column = "Count_Norm"
  )
  nacho_object[["normalised_counts"]] <- norm_counts

  if (!"RCC_type"%in%names(attributes(nacho_object))) {
    attributes(nacho_object) <- c(attributes(nacho_object), RCC_type = type_set)
  }

  message(paste(
    "[NACHO] Returning a list.",
    "  $ access              : character",
    "  $ housekeeping_genes  : character" ,
    "  $ housekeeping_predict: logical",
    "  $ housekeeping_norm   : logical",
    "  $ normalisation_method: character",
    "  $ remove_outliers     : logical",
    "  $ n_comp              : numeric",
    "  $ data_directory      : character",
    "  $ pc_sum              : data.frame",
    "  $ nacho               : data.frame",
    "  $ raw_counts          : data.frame",
    "  $ normalised_counts   : data.frame",
    sep = "\n"
  ))

  nacho_object
}


#' @export
#' @rdname normalise
#' @usage NULL
normalize <- normalise
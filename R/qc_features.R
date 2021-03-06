#' qc_features
#'
#' @param data [[data.frame]] A `data.frame` with the count data.
#' @inheritParams load_rcc
#'
#' @keywords internal
#' @usage NULL
#'
#' @return [[data.frame]]
qc_features <- function(data, id_colname) {
  nested_data_df <- tidyr::nest(dplyr::group_by(.data = data, get(id_colname)))
  colnames(nested_data_df)[1] <- id_colname

  output <- lapply(X = nested_data_df[["data"]], FUN = function(.data) {
    positives <- .data[.data[["CodeClass"]] %in% "Positive", c("Name", "Count")]
    counts <- .data[grep("Endogenous", .data[["CodeClass"]]), ][["Count"]]

    if (any(grepl("POS_E", positives[["Name"]]))) {
      pcl <- qc_positive_control(counts = positives)
      negatives <- .data[.data[["CodeClass"]] %in% "Negative", ][["Count"]]
      lod <- qc_limit_detection(
        pos_e = positives[[grep("POS_E", positives[["Name"]]), "Count"]],
        negatives = negatives
      )
    } else {
      pcl <- 0
      lod <- 0
    }
    fov <- qc_imaging(
      fov_counted = as.numeric(unique(.data[["lane_FovCounted"]])),
      fov_count = as.numeric(unique(.data[["lane_FovCount"]]))
    )

    mean_count <- round(mean(counts), 2)
    median_count <- stats::median(counts)

    c(
      "Date" = unique(.data[["sample_Date"]]),
      "ID" = unique(.data[["lane_ID"]]),
      "BD" = unique(.data[["lane_BindingDensity"]]),
      "ScannerID" = unique(.data[["lane_ScannerID"]]),
      "StagePosition" = unique(.data[["lane_StagePosition"]]),
      "CartridgeID" = unique(.data[["lane_CartridgeID"]]),
      "FoV" = fov,
      "PCL" = ifelse(is.na(pcl), 0, pcl),
      "LoD" = lod,
      "MC" = mean_count,
      "MedC" = median_count
    )
  })

  output <- as.data.frame(do.call("rbind", output), stringsAsFactors = FALSE)
  output[[id_colname]] <- nested_data_df[[id_colname]]
  output[c("BD", "FoV", "PCL", "LoD", "MC", "MedC")] <- lapply(
    X = output[c("BD", "FoV", "PCL", "LoD", "MC", "MedC")],
    FUN = as.numeric
  )

  output
}
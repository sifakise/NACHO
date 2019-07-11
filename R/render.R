#' render
#'
#' This function create a `Rmarkdown` script and render it as a HTML document.
#' The HTML document is a quality-control report using all the metrics from `visualise()`
#' based on recommendations from NanoString.
#'
#' @inheritParams normalise
#' @param colour [character] Character string of the column in \code{ssheet_csv}
#'   or more generally in \code{nacho_object$nacho} to be used as grouping colour.
#' @param output_file [character] The name of the output file.
#'   If using `NULL` then the output filename will be based on filename for the input file.
#'   If a filename is provided, a path to the output file can also be provided.
#'   Note that the `output_dir` option allows for specifying the output file path as well,
#'   however, if also specifying the path, the directory must exist.
#'   If `output_file` is specified but does not have a file extension,
#'   an extension will be automatically added according to the output format.
#'   To avoid the automatic file extension, put the output_file value in `I()`, e.g., I('my-output').
#' @param output_dir [character] The output directory for the rendered output_file.
#'   This allows for a choice of an alternate directory to which the output file should be written
#'   (the default output directory is the working directory, i.e., `getwd()`).
#'   If a path is provided with a filename in `output_file` the directory specified here will take precedence.
#'   Please note that any directory path provided will create any necessary directories if they do not exist.
#' @param show_legend [logical] Boolean to indicate whether the plot legends should
#'   be plotted (\code{TRUE}) or not (\code{FALSE}). Default is \code{TRUE}.
#' @param keep_rmd [logical] Boolean to indicate whether the Rmd file used to produce the HTML report
#'   is copied to the directory provided in `output_dir`. Default is \code{FALSE}.
#'
#' @export
#'
#' @examples
#'
#' data(GSE74821)
#' render(nacho_object = GSE74821, output_dir = NULL)
#'
render <- function(
  nacho_object,
  colour = "CartridgeID",
  output_file = "NACHO_QC.html",
  output_dir = getwd(),
  show_legend = TRUE,
  keep_rmd = FALSE
) {
  temp_file <- gsub("\\\\", "/", tempfile())

  if (is.null(output_dir)) output_dir <- dirname(temp_file)

  temp_file_rmd <- paste0(temp_file, ".Rmd")
  temp_file_data <- paste0(temp_file, ".Rdata")

  cat(
    '---',
    'title: "NanoString Quality-Control Report"',
    # 'author: "[NACHO](https://mcanouil.github.io/NACHO)"',
    'output:',
    '  html_document:',
    '    theme: simplex',
    '    toc: true',
    '    toc_depth: 2',
    '    toc_float:' ,
    '      collapsed: false',
    '    fig_width: 6.3',
    '    fig_height: 4.7',
    '    number_sections: true',
    '    self_contained: true',
    '    mathjax: default',
    '    df_print: kable',
    '---',
    sep = "\n",
    file = temp_file_rmd,
    append = FALSE
  )

  cat(
    '\n',
    paste0(
      '<a href = "https://mcanouil.github.io/NACHO"><center>![](',
      system.file("help", "figures", "nacho_hex.png", package = "NACHO"),
      '){width=150px}</center></a>'
    ),
    file = temp_file_rmd,
    append = TRUE
  )

  save(list = c("nacho_object", "colour", "show_legend"), file = temp_file_data)

  cat(
    '\n',
    '```{r setup, include = FALSE}',
    'options(stringsAsFactors = FALSE)',
    'knitr::opts_chunk$set(',
    '  results = "asis",',
    '  include = TRUE,',
    '  echo = FALSE,',
    '  warning = FALSE,',
    '  message = FALSE,',
    '  tidy = FALSE,',
    '  crop = TRUE,',
    '  autodep = TRUE',
    ')',
    '```',
    sep = "\n",
    file = temp_file_rmd,
    append = TRUE
  )

  cat(
    '\n',
    '```{r nacho_qc}',
    'nacho_env <- new.env()',
    paste0('load("', temp_file_data, '", envir = nacho_env)'),
    'print_nacho(',
    '  nacho_object = nacho_env[["nacho_object"]],',
    '  colour = nacho_env[["colour"]],',
    '  show_legend = nacho_env[["show_legend"]]',
    ')',
    '```',
    sep = "\n",
    file = temp_file_rmd,
    append = TRUE
  )

  cat(
    "\n\n# R session information\n",
    '```{r session_info, results = "markup"}',
    'options("width" = 110)',
    'sessioninfo::session_info()',
    '```',
    sep = "\n",
    file = temp_file_rmd,
    append = TRUE
  )

  if (keep_rmd) {
    file.copy(
      from = temp_file_rmd,
      to = file.path(output_dir, gsub(".html", ".Rmd", output_file))
    )
  }

  rmarkdown::render(
    input = temp_file_rmd,
    output_file = output_file,
    output_dir = output_dir,
    encoding = "UTF-8"
  )

  unlink(temp_file_data)
  unlink(temp_file_rmd)
  invisible()
}


#' print_nacho
#'
#' This function allows to print text and figures from the results of a call to `summarise()`
#' or `normalise()`.
#' It is intended to be used in a `Rmarkdown` chunk.
#'
#' @inheritParams render
#'
#' @keywords internal
#'
#' @return NULL
print_nacho <- function(nacho_object, colour = "CartridgeID", show_legend = FALSE) {
  if (is.numeric(nacho_object$nacho[[colour]])) {
    nacho_object$nacho[[colour]] <- as.character(nacho_object$nacho[[colour]])
  }

  cat("\n\n# RCC Summary\n\n")
  cat('  - Samples:', length(unique(nacho_object$nacho[[nacho_object$access]])), "\n")
  genes <- table(nacho_object$nacho[["CodeClass"]]) /
    length(unique(nacho_object$nacho[[nacho_object$access]]))
  cat(paste0("  - ", names(genes), ": ", genes, "\n"))

  cat("\n\n# Settings\n\n")
  cat('  - Predict housekeeping genes:', nacho_object$housekeeping_predict, "\n")
  cat('  - Normalise using housekeeping genes:', nacho_object$housekeeping_norm, "\n")
  cat(
    '  - Housekeeping genes available:',
    paste(nacho_object$housekeeping_genes[-length(nacho_object$housekeeping_genes)], collapse = ", "),
    "and",
    nacho_object$housekeeping_genes[length(nacho_object$housekeeping_genes)], "\n"
  )
  cat('  - Normalise using:', nacho_object$normalisation_method, "\n")
  cat('  - Principal components to compute:', nacho_object$n_comp, "\n")
  cat('  - Remove outliers:', nacho_object$remove_outliers, "\n")
  cat(
    "\n",
    '    + ', 'Binding Density (BD) <',
      round(nacho_object$outliers_thresholds[["BD"]][1], 3), '\n',
    '    + ', 'Binding Density (BD) >',
      round(nacho_object$outliers_thresholds[["BD"]][2], 3), '\n',
    '    + ', 'Imaging (FoV) <',
      round(nacho_object$outliers_thresholds[["FoV"]], 3), '\n',
    '    + ', 'Positive Control Linearity (PC) <',
      round(nacho_object$outliers_thresholds[["PC"]], 3), '\n',
    '    + ', 'Limit of Detection (LoD) <',
      round(nacho_object$outliers_thresholds[["LoD"]], 3), '\n',
    '    + ', 'Positive normalisation factor (Positive_factor) <',
      round(nacho_object$outliers_thresholds[["Positive_factor"]][1], 3), '\n',
    '    + ', 'Positive normalisation factor (Positive_factor) >',
      round(nacho_object$outliers_thresholds[["Positive_factor"]][2], 3), '\n',
    '    + ', 'Housekeeping normalisation factor (house_factor) <',
      round(nacho_object$outliers_thresholds[["House_factor"]][1], 3), '\n',
    '    + ', 'Housekeeping normalisation factor (house_factor) >',
      round(nacho_object$outliers_thresholds[["House_factor"]][2], 3), '\n'
  )

  cat("\n\n# QC Metrics\n\n")
  labels <- c(
    "MC" = "Average Counts",
    "MedC" = "Median Counts",
    "BD" = "Binding Density",
    "FoV" = "Field of View",
    "PC" = "Positive Control linearity",
    "LoD" = "Limit of Detection"
  )
  units <- c(
    "BD" = '"(Optical features / ", mu, m^2, ")"',
    "FoV" = '"(% Counted)"',
    "PC" = '(R^2)',
    "LoD" = '"(Z)"'
  )
  details <- c(
    "FoV" = paste(
      "Each individual lane scanned on an nCounter system is divided into a few hundred imaging sections, called Fields of View (**FOV**), the exact number of which will depend on the system being used (*i.e.*, **MAX/FLEX** or **SPRINT**), and the scanner settings selected by the user.",
      "The system images these FOVs separately, and sums the barcode counts of all **FOV**s from a single lane to form the final raw data count for each unique barcode target.",
      "Finally, the system reports the number of **FOV**s successfully imaged as FOV Counted.",
      "Significant discrepancy between the number of **FOV** for which imaging was attempted (**FOV Count**) and for which imaging was successful (**FOV Counted**) may indicate an issue with imaging performance.",
      "Recommended percentage of registered FOVs (*i.e.*, **FOV Counted** over **FOV Count**) is `75 %`.",
      "Lanes will be flagged if this percentage is lower.",
      sep = "\n"
    ),
    "BD" = paste(
      "The imaging unit only counts the codes that are unambiguously distinguishable.",
      "It simply will not count codes that overlap within an image.",
      "This provides increased confidence that the molecular counts you receive are from truly recognizable codes.",
      "Under most conditions, forgoing the few barcodes that do overlap will not impact your data.",
      "Too many overlapping codes in the image, however, will create a condition called image saturation in which significant data loss could occur (critical data loss from saturation is uncommon).",
      "To determine the level of image saturation, the nCounter instrument calculates the number of optical features per square micron for each lane as it processes the images.",
      "This is called the **Binding Density**.",
      "The **Binding Density** is useful for determining whether data collection has been compromised due to image saturation.",
      "The acceptable range for **Binding Density** is:",
      "\n",
      "* `0.1 - 2.25` for MAX/FLEX instruments",
      "* `0.1 - 1.8` for SPRINT instruments",
      "\n",
      "Within these ranges, relatively few reporters on the slide surface will overlap, enabling the instrument to accurately tabulate counts for each reporter species.",
      "A **Binding Density** significantly greater than the upper limit in either range is indicative of overlapping reporters on the slide surface.",
      "The counts observed in lanes with a **Binding Density** at this level may have had significant numbers of codes ignored, which could potentially affect quantification and linearity of the assay.",
      "Some of the factors that may contribute to increased **Binding Density** are listed in the Factors affecting **Binding Density** box.",
      sep = "\n"
    ),
    "PC" = paste(
      "Six synthetic DNA control targets are included with every nCounter Gene Expression assay.",
      "Their concentrations range linearly from `128 fM` to `0.125 fM`, and they are referred to as **POS_A** to **POS_F**, respectively.",
      "These **Positive Controls** are typically used to measure the efficiency of the hybridization reaction, and their step-wise concentrations also make them useful in checking the linearity performance of the assay.",
      "An R2 value is calculated from the regression between the known concentration of each of the **Positive Controls** and the resulting counts from them (this calculation is performed using log2-transformed values).",
      "Since the known concentrations of the **Positive Controls** increase in a linear fashion, the resulting counts should, as well.",
      "Therefore, R2 values should be higher than `0.95`.",
      "Note that because POS_F has a known concentration of `0.125 fM`, which is considered below the limit of detection of the system, it should be excluded from this calculation (although you will see that **POS_F** counts are significantly higher than the negative control counts in most cases).",
      sep = "\n"
    ),
    "LoD" = paste(
      "The limit of detection is determined by measuring the ability to detect **POS_E**, the `0.5 fM` positive control probe, which corresponds to about 10,000 copies of this target within each sample tube.",
      "On a **FLEX**/**MAX** system, the standard input of `100 ng` of total RNA will roughly correspond to about 10,000 cell equivalents (assuming one cell contains `10 pg` total RNA on average).",
      "An nCounter assay run on the **FLEX**/**MAX** system should thus conservatively be able to detect roughly one transcript copy per cell for each target (or 10,000 total transcript copies).",
      "In most assays, you will observe that even the **POS_F** probe (equivalent to 0.25 copies per cell) is detectable above background.",
      "To determine whether **POS_E** is detectable, it can be compared to the counts for the negative control probes.",
      "Every nCounter Gene Expression assay is manufactured with eight negative control probes that should not hybridize to any targets within the sample.",
      "Counts from these will approximate general non-specific binding of probes within the samples being run.",
      "The counts of **POS_E** should be higher than two times the standard deviation above the mean of the negative control.",
      sep = "\n"
    )
  )

  metrics <- switch(
    EXPR = attr(nacho_object, "RCC_type"),
    "n1" = c("BD", "FoV", "PC", "LoD"),
    "n8" = c("BD", "FoV")
  )

  for (imetric in metrics) {
    cat("\n\n##", labels[imetric], "\n\n")
    cat(details[imetric], "\n")
    p <- ggplot2::ggplot(
      data = nacho_object$nacho %>%
        dplyr::select(
          "CartridgeID",
          !!colour,
          !!nacho_object$access,
          !!imetric
        ) %>%
        dplyr::distinct(),
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("CartridgeID"),
        y = !!ggplot2::sym(imetric),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggbeeswarm::geom_quasirandom(size = 0.5, width = 0.25, na.rm = TRUE, groupOnX = TRUE) +
      {if (!show_legend) ggplot2::guides(colour = "none")} +
      ggplot2::labs(
        x = "CartridgeID",
        y = parse(text = paste0('paste("', labels[imetric], '", " ", ',  units[imetric], ")"))
      ) +
      ggplot2::geom_hline(
        data = dplyr::tibble(value = nacho_object$outliers_thresholds[[imetric]]),
        mapping = ggplot2::aes(yintercept = !!ggplot2::sym("value")),
        colour = "firebrick2",
        linetype = "longdash"
      )

    print(p)
    cat("\n")
  }

  cat("\n\n# Control Genes\n\n")
  for (icodeclass in c("Positive", "Negative", "Housekeeping")) {
    cat("\n\n")
    cat("##", icodeclass, "\n\n")
    p <- ggplot2::ggplot(
      data = nacho_object$nacho %>%
        dplyr::filter(!!dplyr::sym("CodeClass") %in% icodeclass) %>%
        dplyr::select(
          "CartridgeID",
          !!colour,
          !!nacho_object$access,
          "Name",
          "Count"
        ) %>%
        dplyr::distinct(),
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("Name"),
        y = !!ggplot2::sym("Count"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggbeeswarm::geom_quasirandom(size = 0.5, width = 0.25, na.rm = TRUE, groupOnX = TRUE) +
      ggplot2::scale_y_log10(limits = c(1, NA)) +
      ggplot2::labs(
        x = if (icodeclass%in%c("Negative", "Positive")) "Control Name" else "Gene Name",
        y = "Counts + 1"
      ) +
      {if (!show_legend) ggplot2::guides(colour = "none")} +
      ggplot2::theme(axis.text.x = ggplot2::element_text(face = "italic"))

    number_ticks_x <- nacho_object$nacho %>%
      dplyr::filter(!!dplyr::sym("CodeClass") %in% icodeclass) %>%
      dplyr::select("Name") %>%
      unlist() %>%
      unique() %>%
      length()

    if (number_ticks_x > 10 | show_legend) {
      p <- p +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5))
    }

    print(p)
    cat("\n")
  }

  cat("\n\n## Control Probe Expression\n\n")
  p <- ggplot2::ggplot(
    data = nacho_object$nacho %>%
      dplyr::filter(!!dplyr::sym("CodeClass") %in% c("Positive", "Negative")) %>%
      dplyr::select(
        "CartridgeID",
        !!colour,
        !!nacho_object$access,
        "CodeClass",
        "Name",
        "Count"
      ) %>%
      dplyr::distinct(),
    mapping = ggplot2::aes(
      x = !!ggplot2::sym(nacho_object$access),
      y = !!ggplot2::sym("Count"),
      colour = !!ggplot2::sym("Name"),
      group = !!ggplot2::sym("Name")
    )
  ) +
    ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
    ggplot2::geom_line() +
    ggplot2::facet_wrap(facets = "CodeClass", scales = "free_y", ncol = 2) +
    ggplot2::scale_y_log10(limits = c(1, NA)) +
    ggplot2::scale_x_discrete(labels = NULL) +
    ggplot2::labs(x = "Sample Index", y = "Counts + 1", colour = "Control") +
    ggplot2::theme(
      axis.ticks.x = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank()
    ) +
    {if (!show_legend) ggplot2::guides(colour = "none")}
  print(p)
  cat("\n")

  cat("\n\n# QC Visuals\n\n")

  cat("\n\n## Average Count vs. Binding Density\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!colour,
      !!nacho_object$access,
      "MC",
      "BD"
    ) %>%
    dplyr::distinct() %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("MC"),
        y = !!ggplot2::sym("BD"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::labs(
        x = labels["MC"],
        y = parse(text = paste0('paste("', labels["BD"], '", " ", ',  units["BD"], ")"))
      )
  print(p)
  cat("\n")

  cat("\n\n## Average Count vs. Median Count\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!colour,
      !!nacho_object$access,
      "MC",
      "MedC"
    ) %>%
    dplyr::distinct() %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("MC"),
        y = !!ggplot2::sym("MedC"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::labs(
        x = labels["MC"],
        y = labels["MedC"]
      )
  print(p)
  cat("\n")

  cat("\n\n## Principal Component\n\n")
  cat("\n\n### PC1 vs. PC2\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!colour,
      !!nacho_object$access,
      "PC1",
      "PC2"
    ) %>%
    dplyr::distinct() %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("PC1"),
        y = !!ggplot2::sym("PC2"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::stat_ellipse(na.rm = TRUE) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      {if (!show_legend) ggplot2::guides(colour = "none")}
  print(p)
  cat("\n")

  cat("\n\n### Factorial planes\n\n")
  p <- dplyr::full_join(
    x = nacho_object$nacho %>%
      dplyr::select(
        "CartridgeID",
        !!colour,
        !!nacho_object$access,
        paste0("PC", 1:min(nacho_object$n_comp, 5))
      ) %>%
      dplyr::distinct() %>%
      tidyr::gather(key = "X.PC", value = "X", paste0("PC", 1:min(nacho_object$n_comp, 5))),
    y = nacho_object$nacho %>%
      dplyr::select(
        "CartridgeID",
        !!colour,
        !!nacho_object$access,
        paste0("PC", 1:min(nacho_object$n_comp, 5))
      ) %>%
      dplyr::distinct() %>%
      tidyr::gather(key = "Y.PC", value = "Y", paste0("PC", 1:min(nacho_object$n_comp, 5))),
    by = unique(c("CartridgeID", nacho_object$access, colour))
  ) %>%
    dplyr::filter(
      as.numeric(gsub("PC", "", !!dplyr::sym("X.PC"))) <
        as.numeric(gsub("PC", "", !!dplyr::sym("Y.PC")))
    ) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("X"),
        y = !!ggplot2::sym("Y"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::stat_ellipse(na.rm = TRUE) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::labs(x = NULL, y = NULL) +
      ggplot2::facet_grid(
        rows = ggplot2::vars(!!ggplot2::sym("Y.PC")),
        cols = ggplot2::vars(!!ggplot2::sym("X.PC")),
        scales = "free"
      ) +
      {if (!show_legend) ggplot2::guides(colour = "none")}
  print(p)
  cat("\n")

  cat("\n\n### Inertia\n\n")
  p <- nacho_object$pc_sum %>%
    dplyr::mutate(PoV = scales::percent(!!dplyr::sym("Proportion of Variance"))) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(x = !!ggplot2::sym("PC"), y = !!dplyr::sym("Proportion of Variance"))
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::geom_text(
        mapping = ggplot2::aes(label = !!ggplot2::sym("PoV")),
        vjust = -1,
        show.legend = FALSE
      ) +
      ggplot2::scale_y_continuous(
        labels = scales::percent,
        expand = ggplot2::expand_scale(mult = c(0, 0.15))
      ) +
      ggplot2::labs(x = "Number of Principal Component", y = "Proportion of Variance")
  print(p)
  cat("\n")

  cat("\n\n# Normalisation Factors\n\n")

  cat("\n\n## Positive Factor vs. Background Threshold\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!colour,
      !!nacho_object$access,
      "Negative_factor",
      "Positive_factor"
    ) %>%
    dplyr::distinct() %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("Negative_factor"),
        y = !!ggplot2::sym("Positive_factor"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::labs(x = "Negative Factor", y = "Positive Factor") +
      ggplot2::scale_y_log10()
  print(p)
  cat("\n")

  cat("\n\n## Housekeeping Factor\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!colour,
      !!nacho_object$access,
      "House_factor",
      "Positive_factor"
    ) %>%
    dplyr::distinct() %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym("Positive_factor"),
        y = !!ggplot2::sym("House_factor"),
        colour = !!ggplot2::sym(colour)
      )
    ) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::geom_point(size = 0.5, na.rm = TRUE) +
      ggplot2::labs(x = "Positive Factor", y = "Houskeeping Factor") +
      ggplot2::scale_x_log10() +
      ggplot2::scale_y_log10()
  print(p)
  cat("\n")

  cat("\n\n## Normalisation Result\n\n")
  p <- nacho_object$nacho %>%
    dplyr::select(
      "CartridgeID",
      !!nacho_object$access,
      "Count",
      "Count_Norm",
      "Name"
    ) %>%
    dplyr::distinct() %>%
    dplyr::filter(
      if (is.null(nacho_object$housekeeping_genes)) {
        !!dplyr::sym("CodeClass") %in% "Positive"
      } else {
        !!dplyr::sym("Name") %in% nacho_object$housekeeping_genes
      }
    ) %>%
    tidyr::gather(key = "Status", value = "Count", c("Count", "Count_Norm")) %>%
    dplyr::mutate(
      Status = factor(
        x = c("Count" = "Raw", "Count_Norm" = "Normalised")[!!dplyr::sym("Status")],
        levels = c("Count" = "Raw", "Count_Norm" = "Normalised")
      ),
      Count = !!dplyr::sym("Count") + 1
    ) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = !!ggplot2::sym(nacho_object$access),
        y = !!ggplot2::sym("Count")
      )
    ) +
      ggplot2::geom_line(
        mapping = ggplot2::aes(colour = !!ggplot2::sym("Name"), group = !!ggplot2::sym("Name")),
        size = 0.1,
        na.rm = TRUE
      ) +
      ggplot2::facet_grid(cols = ggplot2::vars(!!ggplot2::sym("Status"))) +
      ggplot2::scale_colour_viridis_d(option = "plasma", direction = -1, end = 0.9) +
      ggplot2::scale_x_discrete(label = NULL) +
      ggplot2::scale_y_log10(limits = c(1, NA)) +
      ggplot2::labs(
        x = "Sample Index",
        y = "Counts + 1",
        colour = if (is.null(nacho_object$housekeeping_genes)) "Positive Control" else "Housekeeping Genes"
      ) +
      ggplot2::theme(
        axis.ticks.x = ggplot2::element_blank(),
        panel.grid.major.x = ggplot2::element_blank(),
        panel.grid.minor.x = ggplot2::element_blank()
      ) +
      {if (!show_legend |  length(nacho_object$housekeeping_genes)>10) ggplot2::guides(colour = "none")} +
      ggplot2::geom_smooth(
        mapping = ggplot2::aes(
          x = as.numeric(as.factor(!!ggplot2::sym(nacho_object$access))),
          linetype = "Loess"
        ),
        colour = "black",
        se = TRUE,
        method = "loess"
      ) +
      ggplot2::labs(linetype = "Smooth")
  print(p)
  cat("\n")

  invisible()
}
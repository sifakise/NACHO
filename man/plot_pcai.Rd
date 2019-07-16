% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autoplot.R
\name{plot_pcai}
\alias{plot_pcai}
\title{plot_pcai}
\usage{
plot_pcai(x, nacho_object, colour, size, show_legend)
}
\arguments{
\item{x}{[\link{character}] Character string naming the quality-control metrics to plot from \code{nacho_object}.
The possible values are:
\itemize{
\item \code{"BD"} (Binding Density)
\item \code{"FoV"} (Imaging)
\item \code{"PC"} (Positive Control Linearity)
\item \code{"LoD"} (Limit of Detection)
\item \code{"Positive"} (Positive Controls)
\item \code{"Negative"} (Negative Controls)
\item \code{"Housekeeping"} (Housekeeping Genes)
\item \code{"PN"} (Positive Controls vs. Negative Controls)
\item \code{"ACBD"} (Average Counts vs. Binding Density)
\item \code{"ACMC"} (Average Counts vs. Median Counts)
\item \code{"PCA12"} (Principal Component 1 vs. 2)
\item \code{"PCAi"} (Principal Component scree plot)
\item \code{"PCA"} (Principal Components planes)
\item \code{"PFNF"} (Positive Factor vs. Negative Factor)
\item \code{"HF"} (Housekeeping Factor)
\item \code{"NORM"} (Normalisation Factor)
}}

\item{colour}{[\link{character}] Character string of the column in \code{ssheet_csv}
or more generally in \code{nacho_object$nacho} to be used as grouping colour.}

\item{size}{[\link{numeric}] A \code{numeric} controlling point size (\link{geom_point} or \link{geom_beeswarm})
or line size (\link{geom_line}).}

\item{show_legend}{[\link{logical}] Boolean to indicate whether the plot legends should
be plotted (\code{TRUE}) or not (\code{FALSE}). Default is \code{TRUE}.}
}
\description{
plot_pcai
}
\keyword{internal}
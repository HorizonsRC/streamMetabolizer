% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mm_sd_to_ci.R
\name{mm_sd_to_ci}
\alias{mm_sd_to_ci}
\title{Convert SD columns into CI columns in a data.frame}
\usage{
mm_sd_to_ci(data, alpha = 0.05)
}
\arguments{
\item{data}{a data.frame with 1+ pairs of columns named var and var.sd 
(where var can be anything)}

\item{alpha}{the desired significance level described by the confidence 
interval}
}
\description{
Convert data with var and var.sd columns into data with var, var.lower, and 
var.upper columns
}
\keyword{internal}

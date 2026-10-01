#' vstar: VTK spatial data and rendering
#' @useDynLib vstar, .registration = TRUE
#' @importFrom Rcpp evalCpp
#' @importFrom R6 R6Class
#' @keywords internal
"_PACKAGE"


.onAttach <- function(libname, pkgname) {
  packageStartupMessage(paste0("Don't hesitate to contact me if you ",
                               "have any question:\n",
                               "emanuel.huber@pm.me"))
}

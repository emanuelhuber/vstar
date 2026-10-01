#' Read VTK XML data
#' @param filename Existing `.vti` or `.vtp` file.
#' @return An `ImageData` or `PolyData` object.
#' @name read_vtk
NULL
#' @rdname read_vtk
#' @export
read_image_data <- function(filename){filename<-path.expand(filename);if(!file.exists(filename))stop("File does not exist.",call.=FALSE);if(tolower(tools::file_ext(filename))!="vti")stop("Filename must end in .vti.",call.=FALSE);ImageData$new(cpp_read_image_data(filename))}
#' @rdname read_vtk
#' @export
read_poly_data <- function(filename){filename<-path.expand(filename);if(!file.exists(filename))stop("File does not exist.",call.=FALSE);if(tolower(tools::file_ext(filename))!="vtp")stop("Filename must end in .vtp.",call.=FALSE);PolyData$new(cpp_read_poly_data(filename))}

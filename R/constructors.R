#' Create structured image data
#' @param array_data Finite numeric 3D array.
#' @param spacing Positive `(dx, dy, dz)`.
#' @param origin `(x0, y0, z0)`.
#' @return An `ImageData` object.
#' @export
imageData <- function(array_data, spacing = c(1,1,1), origin = c(0,0,0)) {
  d <- dim(array_data)
  if (!is.numeric(array_data) || length(d) != 3L || any(d < 1L) || any(!is.finite(array_data)))
    stop("`array_data` must be a finite, non-empty numeric 3D array.", call. = FALSE)
  .vs_numeric(spacing, "spacing", 3L, TRUE); .vs_vec3(origin, "origin")
  ImageData$new(cpp_create_image_data(as.numeric(array_data), as.integer(d), as.numeric(spacing), as.numeric(origin)))
}
#' Create polygonal data
#' @param vertices Finite numeric n by 3 matrix.
#' @param faces,lines Optional one-based connectivity lists or matrices with cells in columns.
#' @return A `PolyData` object.
#' @export
polyData <- function(vertices, faces = NULL, lines = NULL) {
  vertices <- as.matrix(vertices)
  if (!is.numeric(vertices) || ncol(vertices) != 3L || nrow(vertices) < 1L || any(!is.finite(vertices)))
    stop("`vertices` must be a finite numeric matrix with three columns.", call. = FALSE)
  cv <- function(x, min_n, name) {
    if (is.null(x)) return(NULL)
    if (is.matrix(x)) x <- lapply(seq_len(ncol(x)), function(i) x[,i])
    if (!is.list(x)) stop(sprintf("`%s` must be a list or matrix.", name), call. = FALSE)
    lapply(x, function(z) {
      if (!is.numeric(z) || length(z) < min_n || any(!is.finite(z)) ||
          any(z != as.integer(z)) || any(z < 1L | z > nrow(vertices)))
        stop(sprintf("Invalid one-based connectivity in `%s`.", name), call. = FALSE)
      as.integer(z)
    })
  }
  PolyData$new(cpp_create_poly_data(vertices, cv(faces,3L,"faces"), cv(lines,2L,"lines")))
}

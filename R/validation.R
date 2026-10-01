.vs_numeric <- function(x, name, length = NULL, positive = FALSE) {
  if (!is.numeric(x) || (!is.null(length) && length(x) != length) || any(!is.finite(x)))
    stop(sprintf("`%s` must be a finite numeric value/vector%s.", name,
                 if (is.null(length)) "" else sprintf(" of length %d", length)), call. = FALSE)
  if (positive && any(x <= 0)) stop(sprintf("`%s` must be strictly positive.", name), call. = FALSE)
  invisible(x)
}
.vs_vec3 <- function(x, name) .vs_numeric(x, name, 3L)
.vs_color <- function(x, name = "color") {
  .vs_numeric(x, name, 3L)
  if (any(x < 0 | x > 1)) stop(sprintf("`%s` components must lie in [0, 1].", name), call. = FALSE)
  invisible(x)
}
.vs_object <- function(x, class, name) {
  if (!inherits(x, class)) stop(sprintf("`%s` must be a %s object.", name, class), call. = FALSE)
}
.vs_colormap <- function(x) match.arg(x, c("viridis", "plasma", "magma", "inferno", "grayscale"))
.vs_scalar_range <- function(x, default) {
  if (is.null(x)) return(default)
  .vs_numeric(x, "scalar_range", 2L)
  if (x[1] >= x[2]) stop("`scalar_range` must be strictly increasing.", call. = FALSE)
  as.numeric(x)
}
.vs_opacity <- function(x, range) {
  if (is.null(x)) return(matrix(c(range[1], 0, range[2], 1), 2L, byrow = TRUE))
  if (is.numeric(x) && is.null(dim(x))) {
    if (length(x) < 4L || length(x) %% 2L != 0L) stop("`opacity` must contain value/opacity pairs.", call. = FALSE)
    x <- matrix(x, ncol = 2L, byrow = TRUE)
  }
  if (!is.matrix(x) || !is.numeric(x) || ncol(x) != 2L || nrow(x) < 2L || any(!is.finite(x)))
    stop("`opacity` must be a finite numeric two-column matrix with at least two rows.", call. = FALSE)
  if (any(x[,2] < 0 | x[,2] > 1)) stop("Opacity values must lie in [0, 1].", call. = FALSE)
  x <- x[order(x[,1]),,drop=FALSE]
  if (anyDuplicated(x[,1])) stop("Opacity scalar positions must be unique.", call. = FALSE)
  x
}

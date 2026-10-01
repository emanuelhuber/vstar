#' Structured VTK image data
#' @export
ImageData <- R6::R6Class(
  "ImageData",
  cloneable = FALSE,
  private = list(
    ptr = NULL,
    slice_index = function(index, axis) {
      d <- cpp_image_dimensions(private$ptr)
      if (length(index) != 1L || !is.numeric(index) || !is.finite(index) ||
          index != as.integer(index) || index < 1L || index > d[axis]) {
        stop(sprintf("`index` must be in 1:%d.", d[axis]), call. = FALSE)
      }
      o <- cpp_image_origin(private$ptr)
      s <- cpp_image_spacing(private$ptr)
      private$slice_coord(o[axis] + (index - 1) * s[axis], axis)
    },
    slice_coord = function(coord, axis) {
      .vs_numeric(coord, "coordinate", 1L)
      b <- cpp_image_bounds(private$ptr)
      lim <- b[c(2 * axis - 1L, 2 * axis)]
      if (coord < lim[1] || coord > lim[2]) {
        stop(sprintf("Coordinate must lie in [%g, %g].", lim[1], lim[2]), call. = FALSE)
      }
      o <- c(mean(b[1:2]), mean(b[3:4]), mean(b[5:6]))
      o[axis] <- coord
      n <- c(0, 0, 0)
      n[axis] <- 1
      PolyData$new(cpp_image_slice(private$ptr, o, n))
    }
  ),
  active = list(
    pointer = function(value) {
      if (!missing(value)) stop("`pointer` is read-only.", call. = FALSE)
      private$ptr
    }
  ),
  public = list(
    initialize = function(ptr) private$ptr <- ptr,
    contour = function(thresholds) {
      .vs_numeric(thresholds, "thresholds")
      if (!length(thresholds)) stop("At least one threshold is required.", call. = FALSE)
      PolyData$new(cpp_image_contour(private$ptr, thresholds))
    },
    slice = function(origin, normal) {
      .vs_vec3(origin, "origin")
      .vs_vec3(normal, "normal")
      if (sum(normal^2) == 0) stop("`normal` must be nonzero.", call. = FALSE)
      PolyData$new(cpp_image_slice(private$ptr, origin, normal))
    },
    slice_x = function(index) private$slice_index(index, 1L),
    slice_y = function(index) private$slice_index(index, 2L),
    slice_z = function(index) private$slice_index(index, 3L),
    slice_x_coordinate = function(x) private$slice_coord(x, 1L),
    slice_y_coordinate = function(y) private$slice_coord(y, 2L),
    slice_z_coordinate = function(z) private$slice_coord(z, 3L),
    dimensions = function() cpp_image_dimensions(private$ptr),
    spacing = function() cpp_image_spacing(private$ptr),
    origin = function() cpp_image_origin(private$ptr),
    bounds = function() cpp_image_bounds(private$ptr),
    scalar_range = function() cpp_image_scalar_range(private$ptr),
    scalar_name = function() cpp_image_scalar_name(private$ptr),
    deep_copy = function() ImageData$new(cpp_image_deep_copy(private$ptr)),
    write = function(filename, overwrite = FALSE) {
      filename <- path.expand(filename)
      if (tolower(tools::file_ext(filename)) != "vti") stop("ImageData filename must end in .vti.", call. = FALSE)
      if (file.exists(filename) && !isTRUE(overwrite)) stop("File exists; use `overwrite = TRUE`.", call. = FALSE)
      cpp_write_image_data(private$ptr, filename)
      invisible(self)
    },
    print = function(...) {
      d <- self$dimensions()
      cat(sprintf("<vstar ImageData> %d x %d x %d; scalars=%s\n", d[1], d[2], d[3], self$scalar_name()))
      invisible(self)
    }
  )
)

#' VTK polygonal data
#' @export
PolyData <- R6::R6Class(
  "PolyData",
  cloneable = FALSE,
  private = list(ptr = NULL),
  active = list(
    pointer = function(value) {
      if (!missing(value)) stop("`pointer` is read-only.", call. = FALSE)
      private$ptr
    }
  ),
  public = list(
    initialize = function(ptr) private$ptr <- ptr,
    tube = function(radius = 0.05, sides = 20L, capping = TRUE) {
      .vs_numeric(radius, "radius", 1L, TRUE)
      sides <- as.integer(sides)
      if (length(sides) != 1L || is.na(sides) || sides < 3L) stop("`sides` must be at least three.", call. = FALSE)
      PolyData$new(cpp_poly_tube(private$ptr, radius, sides, isTRUE(capping)))
    },
    delaunay_2d = function(tolerance = 1e-5, alpha = 0) {
      .vs_numeric(tolerance, "tolerance", 1L)
      .vs_numeric(alpha, "alpha", 1L)
      if (tolerance < 0 || alpha < 0) stop("`tolerance` and `alpha` must be nonnegative.", call. = FALSE)
      PolyData$new(cpp_poly_delaunay_2d(private$ptr, tolerance, alpha))
    },
    transform = function(matrix) {
      if (!is.matrix(matrix) || !is.numeric(matrix) || !identical(dim(matrix), c(4L, 4L)) || any(!is.finite(matrix))) {
        stop("`matrix` must be a finite numeric 4 x 4 matrix.", call. = FALSE)
      }
      PolyData$new(cpp_poly_transform(private$ptr, matrix))
    },
    points = function() cpp_poly_points(private$ptr),
    faces = function() cpp_poly_faces(private$ptr),
    triangles = function() cpp_poly_triangles(private$ptr),
    as_mesh3d = function(triangulate = TRUE) {
      x <- cpp_poly_as_mesh3d(private$ptr, isTRUE(triangulate))
      class(x) <- c("mesh3d", "shape3d")
      x
    },
    n_points = function() cpp_poly_n_points(private$ptr),
    n_cells = function() cpp_poly_n_cells(private$ptr),
    bounds = function() cpp_poly_bounds(private$ptr),
    center = function() {
      b <- self$bounds()
      c(mean(b[1:2]), mean(b[3:4]), mean(b[5:6]))
    },
    has_scalars = function() cpp_poly_has_scalars(private$ptr),
    scalar_range = function() if (self$has_scalars()) cpp_poly_scalar_range(private$ptr) else NULL,
    scalar_name = function() if (self$has_scalars()) cpp_poly_scalar_name(private$ptr) else NULL,
    deep_copy = function() PolyData$new(cpp_poly_deep_copy(private$ptr)),
    write = function(filename, overwrite = FALSE) {
      filename <- path.expand(filename)
      if (tolower(tools::file_ext(filename)) != "vtp") stop("PolyData filename must end in .vtp.", call. = FALSE)
      if (file.exists(filename) && !isTRUE(overwrite)) stop("File exists; use `overwrite = TRUE`.", call. = FALSE)
      cpp_write_poly_data(private$ptr, filename)
      invisible(self)
    },
    print = function(...) {
      cat(sprintf("<vstar PolyData> %d point(s), %d cell(s), scalars=%s\n", self$n_points(), self$n_cells(), self$has_scalars()))
      invisible(self)
    }
  )
)

#' Persistent native VTK plotter
#' @export
Plotter <- R6::R6Class(
  "Plotter",
  cloneable = FALSE,
  private = list(
    ptr = NULL,
    closed = FALSE,
    check = function() {
      if (private$closed) stop("Plotter is closed.", call. = FALSE)
    },
    finalize = function() {
      if (!private$closed && !is.null(private$ptr)) {
        try(cpp_plotter_close(private$ptr), silent = TRUE)
        private$closed <- TRUE
      }
    }
  ),
  active = list(
    pointer = function(value) {
      if (!missing(value)) stop("`pointer` is read-only.", call. = FALSE)
      private$check()
      private$ptr
    }
  ),
  public = list(
    initialize = function(background = c(0.15, 0.15, 0.18), size = c(1024L, 768L), title = "vstar") {
      .vs_color(background, "background")
      .vs_numeric(size, "size", 2L, TRUE)
      private$ptr <- cpp_plotter_create(background, as.integer(size), as.character(title)[1])
    },
    add_mesh = function(poly_data, color = c(0.8, 0.8, 0.8), opacity = 1,
                        representation = c("surface", "wireframe", "points"),
                        scalars = FALSE, colormap = "viridis", scalar_range = NULL, show_scalar_bar = FALSE) {
      private$check()
      .vs_object(poly_data, "PolyData", "poly_data")
      .vs_color(color)
      .vs_numeric(opacity, "opacity", 1L)
      if (opacity < 0 || opacity > 1) stop("`opacity` must lie in [0, 1].", call. = FALSE)
      representation <- match.arg(representation)
      colormap <- .vs_colormap(colormap)
      if (isTRUE(scalars)) {
        if (!poly_data$has_scalars()) stop("PolyData has no active point scalars.", call. = FALSE)
        scalar_range <- .vs_scalar_range(scalar_range, poly_data$scalar_range())
      } else {
        scalar_range <- c(0, 1)
      }
      invisible(cpp_plotter_add_mesh(
        private$ptr, poly_data$pointer, color, opacity, representation,
        isTRUE(scalars), colormap, scalar_range, isTRUE(show_scalar_bar)
      ))
    },
    add_volume = function(volume, colormap = "viridis", opacity = NULL, scalar_range = NULL, shade = TRUE) {
      private$check()
      .vs_object(volume, "ImageData", "volume")
      colormap <- .vs_colormap(colormap)
      scalar_range <- .vs_scalar_range(scalar_range, volume$scalar_range())
      opacity <- .vs_opacity(opacity, scalar_range)
      invisible(cpp_plotter_add_volume(private$ptr, volume$pointer, colormap, opacity, scalar_range, isTRUE(shade)))
    },
    set_background = function(color) {
      private$check()
      .vs_color(color)
      cpp_plotter_set_background(private$ptr, color)
      invisible(self)
    },
    reset_camera = function() {
      private$check()
      cpp_plotter_reset_camera(private$ptr)
      invisible(self)
    },
    clear = function() {
      private$check()
      cpp_plotter_clear(private$ptr)
      invisible(self)
    },
    render = function() {
      private$check()
      cpp_plotter_render(private$ptr)
      invisible(self)
    },
    show = function() {
      private$check()
      cpp_plotter_show(private$ptr)
      invisible(self)
    },
    screenshot = function(filename, scale = 1L, transparent_background = FALSE) {
      private$check()
      filename <- path.expand(filename)
      if (tolower(tools::file_ext(filename)) != "png") stop("Screenshot filename must end in .png.", call. = FALSE)
      scale <- as.integer(scale)
      if (length(scale) != 1L || is.na(scale) || scale < 1L) stop("`scale` must be positive.", call. = FALSE)
      cpp_plotter_screenshot(private$ptr, filename, scale, isTRUE(transparent_background))
      if (!file.exists(filename) || file.info(filename)$size <= 0) stop("VTK did not create a valid screenshot.", call. = FALSE)
      invisible(normalizePath(filename, mustWork = TRUE))
    },
    close = function() {
      if (!private$closed) {
        cpp_plotter_close(private$ptr)
        private$closed <- TRUE
      }
      invisible(self)
    },
    
    print = function(...) {
      cat(sprintf("<vstar Plotter> %s\n", if (private$closed) "closed" else "open"))
      invisible(self)
    }
  )
)
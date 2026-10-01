# vstar 0.1.2: Complete Tutorial
# =================================
#
# This script demonstrates the complete public API of vstar 0.1.2.
# Run it section by section while developing the package.
#
# Important:
# - Plotter$show() is interactive and blocks the R console until the VTK window
#   closes.
# - Plotter$render() renders without starting the interactive event loop.
# - Rendering and screenshots require a functioning VTK/OpenGL environment.
# - ImageData and PolyData filters return new objects and do not mutate inputs.

library(vstar)

# -----------------------------------------------------------------------------
# 1. Create a synthetic ImageData volume
# -----------------------------------------------------------------------------

n <- 35L
x <- seq(-1, 1, length.out = n)
y <- seq(-1, 1, length.out = n)
z <- seq(-1, 1, length.out = n)

# Array dimension 1 maps to VTK x, dimension 2 to VTK y, and dimension 3 to
# VTK z. Create two smooth anomalies to make slices and volume rendering useful.
values <- array(0, dim = c(n, n, n))

for (k in seq_len(n)) {
  xy1 <- outer(
    x,
    y,
    function(x, y) exp(-5 * ((x + 0.25)^2 + (y + 0.15)^2))
  )

  xy2 <- outer(
    x,
    y,
    function(x, y) 0.75 * exp(-12 * ((x - 0.35)^2 + (y - 0.30)^2))
  )

  values[, , k] <-
    xy1 * exp(-4 * (z[k] + 0.15)^2) +
    xy2 * exp(-10 * (z[k] - 0.35)^2)
}

volume <- imageData(
  values,
  spacing = c(0.05, 0.05, 0.04),
  origin = c(-0.85, -0.85, -0.68)
)

print(volume)

# -----------------------------------------------------------------------------
# 2. Inspect ImageData metadata
# -----------------------------------------------------------------------------

volume$dimensions()
volume$spacing()
volume$origin()
volume$bounds()
volume$scalar_name()
volume$scalar_range()

# Create an independent VTK deep copy.
volume_copy <- volume$deep_copy()
volume_copy$dimensions()

# The pointer exists for interoperability with the package internals but is
# intentionally read-only.
volume$pointer

# -----------------------------------------------------------------------------
# 3. Extract isosurfaces
# -----------------------------------------------------------------------------

surface_low <- volume$contour(0.20)
surface_mid <- volume$contour(0.45)
surface_high <- volume$contour(0.70)

# Several contour levels may be generated in one PolyData object.
surfaces_combined <- volume$contour(c(0.20, 0.45, 0.70))

print(surface_mid)
surface_mid$n_points()
surface_mid$n_cells()
surface_mid$bounds()
surface_mid$center()
surface_mid$has_scalars()
surface_mid$scalar_name()
surface_mid$scalar_range()

# -----------------------------------------------------------------------------
# 4. Extract arbitrary and axis-aligned slices
# -----------------------------------------------------------------------------

# Arbitrary oblique plane.
oblique_slice <- volume$slice(
  origin = c(0, 0, 0),
  normal = c(1, 1, 0.5)
)

# One-based R indices.
slice_x <- volume$slice_x(18)
slice_y <- volume$slice_y(18)
slice_z <- volume$slice_z(18)

# Physical VTK coordinates.
slice_x0 <- volume$slice_x_coordinate(0)
slice_y0 <- volume$slice_y_coordinate(0)
slice_z0 <- volume$slice_z_coordinate(0)

slice_z$has_scalars()
slice_z$scalar_name()
slice_z$scalar_range()

# Invalid indices and coordinates produce clear errors.
try(volume$slice_x(0))
try(volume$slice_z(100))
try(volume$slice_x_coordinate(100))

# -----------------------------------------------------------------------------
# 5. Create PolyData geometry
# -----------------------------------------------------------------------------

line <- pd_line(
  point1 = c(-0.8, -0.8, -0.6),
  point2 = c(0.8, 0.8, 0.6),
  resolution = 20L
)

spline_points <- rbind(
  c(-0.8, -0.7, -0.5),
  c(-0.3,  0.2, -0.2),
  c( 0.2, -0.1,  0.2),
  c( 0.8,  0.7,  0.5)
)

spline <- pd_spline(
  points = spline_points,
  n_points = 100L,
  closed = FALSE
)

sphere <- pd_sphere(
  center = c(0, 0, 0),
  radius = 0.25,
  theta_resolution = 30L,
  phi_resolution = 30L
)

cylinder <- pd_cylinder(
  center = c(0.55, -0.55, 0),
  radius = 0.08,
  height = 0.9,
  resolution = 30L,
  capping = TRUE,
  direction = c(0, 0, 1)
)

# -----------------------------------------------------------------------------
# 6. Construct PolyData directly
# -----------------------------------------------------------------------------

vertices <- rbind(
  c(-0.5, -0.5, -0.5),
  c( 0.5, -0.5, -0.5),
  c( 0.5,  0.5, -0.5),
  c(-0.5,  0.5, -0.5)
)

quad <- polyData(
  vertices = vertices,
  faces = list(c(1L, 2L, 3L, 4L))
)

# Line connectivity is also one-based.
polyline <- polyData(
  vertices = spline_points,
  lines = list(seq_len(nrow(spline_points)))
)

quad$n_points()
quad$n_cells()
quad$faces()

# -----------------------------------------------------------------------------
# 7. Apply PolyData filters
# -----------------------------------------------------------------------------

pipe <- spline$tube(
  radius = 0.035,
  sides = 16L,
  capping = TRUE
)

# Delaunay triangulation of a planar point cloud.
set.seed(1)
points_2d <- cbind(
  runif(30, -0.7, 0.7),
  runif(30, -0.7, 0.7),
  rep(-0.65, 30)
)

point_cloud <- polyData(points_2d)
triangulated <- point_cloud$delaunay_2d(
  tolerance = 1e-5,
  alpha = 0
)

# Homogeneous 4 x 4 transform. This example translates along x.
translation <- diag(4)
translation[1:3, 4] <- c(0.30, 0, 0)
moved_sphere <- sphere$transform(translation)

# Explicit deep copy.
sphere_copy <- sphere$deep_copy()

# -----------------------------------------------------------------------------
# 8. Extract PolyData geometry into R
# -----------------------------------------------------------------------------

surface_points <- surface_mid$points()
surface_faces <- surface_mid$faces()
surface_triangles <- surface_mid$triangles()

head(surface_points)
head(surface_faces)
head(t(surface_triangles))

# Convert to an rgl-compatible mesh3d object. This is an interchange format;
# native VTK rendering should use surface_mid directly.
mesh3d <- surface_mid$as_mesh3d(triangulate = TRUE)
str(mesh3d, max.level = 1)

# Optional rgl interoperability:
# rgl::open3d()
# rgl::shade3d(mesh3d, color = "steelblue")

# -----------------------------------------------------------------------------
# 9. Uniformly colored VTK mesh rendering
# -----------------------------------------------------------------------------

plotter_mesh <- Plotter$new(
  background = c(0.06, 0.07, 0.09),
  size = c(1000L, 750L),
  title = "vstar 0.1.2: PolyData scene"
)

plotter_mesh$add_mesh(
  surface_low,
  color = c(0.20, 0.55, 0.95),
  opacity = 0.25,
  representation = "surface"
)

plotter_mesh$add_mesh(
  surface_high,
  color = c(0.95, 0.30, 0.15),
  opacity = 0.85
)

plotter_mesh$add_mesh(
  pipe,
  color = c(0.15, 0.90, 0.30)
)

plotter_mesh$add_mesh(
  cylinder,
  color = c(0.95, 0.80, 0.15),
  opacity = 0.9
)

plotter_mesh$add_mesh(
  triangulated,
  color = c(0.85, 0.85, 0.90),
  representation = "wireframe"
)

plotter_mesh$reset_camera()
plotter_mesh$render()

# Save the current scene as a PNG.
plotter_mesh$screenshot(
  "vstar_polydata_scene.png",
  scale = 1L,
  transparent_background = FALSE
)

# Interactive and blocking. Uncomment when desired.
# plotter_mesh$show()

# Remove all current scene objects, then close native resources.
plotter_mesh$clear()
plotter_mesh$close()

# close() is intentionally idempotent.
plotter_mesh$close()

# Operations after closure are rejected safely.
try(plotter_mesh$render())

# -----------------------------------------------------------------------------
# 10. Scalar-colored slices and isosurfaces
# -----------------------------------------------------------------------------

plotter_slice <- Plotter$new(
  background = c(0.10, 0.10, 0.12),
  title = "vstar 0.1.2: scalar-colored slice"
)

plotter_slice$add_mesh(
  slice_z,
  scalars = TRUE,
  colormap = "viridis",
  scalar_range = volume$scalar_range(),
  show_scalar_bar = TRUE
)

plotter_slice$reset_camera()
plotter_slice$render()
plotter_slice$screenshot("vstar_scalar_slice.png")
# plotter_slice$show()
plotter_slice$close()

# Supported colormaps are:
# "viridis", "plasma", "magma", "inferno", and "grayscale".

plotter_contour <- Plotter$new(title = "Scalar-colored isosurface")
plotter_contour$add_mesh(
  surfaces_combined,
  scalars = TRUE,
  colormap = "plasma",
  scalar_range = surfaces_combined$scalar_range(),
  show_scalar_bar = TRUE
)
plotter_contour$reset_camera()
plotter_contour$render()
# plotter_contour$show()
plotter_contour$close()

# -----------------------------------------------------------------------------
# 11. Direct volume rendering
# -----------------------------------------------------------------------------

scalar_range <- volume$scalar_range()

# A two-column opacity transfer function: scalar value and opacity.
opacity <- matrix(
  c(
    scalar_range[1],                              0.00,
    scalar_range[1] + 0.20 * diff(scalar_range), 0.00,
    scalar_range[1] + 0.45 * diff(scalar_range), 0.04,
    scalar_range[1] + 0.70 * diff(scalar_range), 0.30,
    scalar_range[2],                              0.90
  ),
  ncol = 2,
  byrow = TRUE
)

plotter_volume <- Plotter$new(
  background = c(0.02, 0.02, 0.03),
  size = c(1000L, 750L),
  title = "vstar 0.1.2: direct volume rendering"
)

plotter_volume$add_volume(
  volume,
  colormap = "magma",
  opacity = opacity,
  scalar_range = scalar_range,
  shade = TRUE
)

plotter_volume$reset_camera()
plotter_volume$render()
plotter_volume$screenshot(
  "vstar_volume.png",
  scale = 1L,
  transparent_background = FALSE
)
# plotter_volume$show()
plotter_volume$close()

# Default rendering uses a linear opacity ramp from zero to one.
plotter_default_volume <- Plotter$new()
plotter_default_volume$add_volume(volume)
plotter_default_volume$reset_camera()
plotter_default_volume$render()
plotter_default_volume$close()

# -----------------------------------------------------------------------------
# 12. Native VTK XML I/O
# -----------------------------------------------------------------------------

vti_file <- tempfile(fileext = ".vti")
vtp_file <- tempfile(fileext = ".vtp")

volume$write(vti_file)
surface_mid$write(vtp_file)

volume_from_disk <- read_image_data(vti_file)
surface_from_disk <- read_poly_data(vtp_file)

volume_from_disk$dimensions()
volume_from_disk$scalar_range()
surface_from_disk$n_points()
surface_from_disk$n_cells()

# Existing files require overwrite = TRUE.
volume$write(vti_file, overwrite = TRUE)
surface_mid$write(vtp_file, overwrite = TRUE)

unlink(c(vti_file, vtp_file))

# -----------------------------------------------------------------------------
# 13. Ownership and garbage-collection smoke tests
# -----------------------------------------------------------------------------

make_temporary_pipe <- function() {
  pd_line(c(0, 0, 0), c(1, 0, 0))$tube(radius = 0.05)
}

temporary_pipe <- make_temporary_pipe()
gc()
temporary_pipe$n_points()

independent_pipe <- temporary_pipe$deep_copy()
rm(temporary_pipe)
gc()
independent_pipe$n_cells()

# A Plotter that is not explicitly closed is finalized by R6 during garbage
# collection. Explicit close() is still preferred because release timing is
# deterministic.
make_temporary_plotter <- function() {
  p <- Plotter$new()
  invisible(NULL)
}

make_temporary_plotter()
gc()

# -----------------------------------------------------------------------------
# 14. Development diagnostics
# -----------------------------------------------------------------------------

# Confirm the development DLL is loaded.
getLoadedDLLs()[["vstar"]]

# Inspect registered .Call routines.
registered <- getDLLRegisteredRoutines("vstar")$.Call
head(names(registered))

stopifnot(
  "_vstar_cpp_create_image_data" %in% names(registered),
  "_vstar_cpp_plotter_add_volume" %in% names(registered),
  "_vstar_cpp_plotter_close" %in% names(registered)
)

# On Linux, inspect shared-library dependencies and unresolved symbols.
if (Sys.info()[["sysname"]] == "Linux") {
  dll <- getLoadedDLLs()[["vstar"]][["path"]]
  native_dependencies <- system2(
    "ldd",
    c("-r", shQuote(dll)),
    stdout = TRUE,
    stderr = TRUE
  )

  print(native_dependencies)

  unresolved <- grep(
    "undefined symbol|not found",
    native_dependencies,
    value = TRUE
  )

  print(unresolved)
}

# -----------------------------------------------------------------------------
# 15. Package-development checks
# -----------------------------------------------------------------------------

# Run these from the package root, not while sourcing this tutorial:
#
# devtools::clean_dll()
# Rcpp::compileAttributes()
# devtools::document()
# devtools::load_all(recompile = TRUE)
# devtools::test()
# devtools::build_vignettes()
# devtools::check()
#
# For a final installed-package test:
# archive <- devtools::build(vignettes = TRUE)
# install.packages(archive, repos = NULL, type = "source")

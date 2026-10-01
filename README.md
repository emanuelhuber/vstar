# vstar 0.1.2

Where Python has pyVista (Python + Vista), R gets Vista-R $\rightarrow$ vee-sta-R $\rightarrow$ v-star $\rightarrow$ vstar.

`vstar` provides ownership-safe R6 interfaces to selected VTK functionality.
Version 0.1.2 provides visualization support for the existing `ImageData`
and `PolyData` types with direct volume rendering, scalar-colored meshes,
transfer functions, screenshots, and convenient image slicing.

## Documentation

- [inst/vstar_0.1.2_complete_tutorial.R](inst/vstar_0.1.2_complete_tutorial.R)
- [vignettes/vstar-overview.2Rmd](vignettes/vstar-overview2.Rmd)
- [vignettes/vstar-overview2.html](vignettes/vstar-overview2.html)

## Build

The supplied Unix `src/Makevars` targets VTK 9.1 under `/usr/include/vtk-9.1`.
Adapt it when your VTK installation differs.

```r
devtools::clean_dll()
Rcpp::compileAttributes()
devtools::document()
devtools::load_all(recompile = TRUE)
devtools::test()
devtools::check()
```

```r
rmarkdown::render(
  "vignettes/vstar-overview2.Rmd"
)
```

## Smoke test

```
library(vstar)

volume <- imageData(
  array(runif(20^3), dim = c(20, 20, 20))
)

slice <- volume$slice_z(10)

plotter <- Plotter$new()

plotter$add_mesh(
  slice,
  scalars = TRUE,
  show_scalar_bar = TRUE
)

plotter$reset_camera()
plotter$show()
plotter$close()

plotter <- Plotter$new()
plotter$add_volume(volume, colormap = "magma")
plotter$reset_camera()
plotter$show()
plotter$close()

# ---------------
volume <- imageData(
  array(runif(20^3), dim = c(20, 20, 20))
)

vti <- tempfile(fileext = ".vti")

volume$write(vti)

file.exists(vti)
file.info(vti)$size

volume_read <- read_image_data(vti)

volume_read$dimensions()
volume_read$scalar_range()

# ------------------------
surface <- volume$contour(0.5)

vtp <- tempfile(fileext = ".vtp")

surface$write(vtp)

surface_read <- read_poly_data(vtp)

surface_read$n_points()
surface_read$n_cells()

```


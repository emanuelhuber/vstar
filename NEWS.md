# vstar 0.1.2

* Hardened external-pointer type and null validation.
* Made plotter shutdown idempotent and guarded all operations after closure.
* Added explicit retention of mapper, actor, volume, transfer-function, lookup-table, and scalar-bar objects.
* Added the missing `vtkRenderingAnnotation` linker module.
* Improved argument validation, I/O checks, screenshots, and scalar handling.
* Regenerated native registration for all exported C++ routines.
* Added headless-safe tests, lifetime tests, validation tests, and a package vignette.

# vstar 0.1.1

* Added direct volume rendering, scalar-colored meshes and slices, slice helpers,
  scalar metadata, screenshots, non-blocking rendering, and plotter shutdown.

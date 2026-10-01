has_display <- function() nzchar(Sys.getenv("DISPLAY")) || nzchar(Sys.getenv("WAYLAND_DISPLAY")) || identical(.Platform$OS.type,"windows")

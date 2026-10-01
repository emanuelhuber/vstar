#' VTK geometry constructors
#' @param point1,point2,center,direction Numeric vectors of length three.
#' @param points Numeric n by 3 matrix.
#' @param resolution,theta_resolution,phi_resolution,n_points Integer resolutions.
#' @param closed,capping Logical values.
#' @param radius,height Positive values.
#' @return A `PolyData` object.
#' @name geometry
NULL
#' @rdname geometry
#' @export
pd_line <- function(point1, point2, resolution=1L) {
  .vs_vec3(point1,"point1"); .vs_vec3(point2,"point2"); resolution<-as.integer(resolution)
  if (length(resolution)!=1L || is.na(resolution) || resolution<1L) stop("`resolution` must be positive.",call.=FALSE)
  PolyData$new(cpp_pd_line(point1,point2,resolution))
}
#' @rdname geometry
#' @export
pd_spline <- function(points,n_points=100L,closed=FALSE) {
  points<-as.matrix(points); n_points<-as.integer(n_points)
  if(!is.numeric(points)||ncol(points)!=3L||nrow(points)<2L||any(!is.finite(points))) stop("Invalid `points`.",call.=FALSE)
  if(length(n_points)!=1L||is.na(n_points)||n_points<2L) stop("`n_points` must be at least two.",call.=FALSE)
  PolyData$new(cpp_pd_spline(points,n_points,isTRUE(closed)))
}
#' @rdname geometry
#' @export
pd_sphere <- function(center=c(0,0,0),radius=1,theta_resolution=30L,phi_resolution=30L) {
  .vs_vec3(center,"center");.vs_numeric(radius,"radius",1L,TRUE)
  tr<-as.integer(theta_resolution);pr<-as.integer(phi_resolution)
  if(anyNA(c(tr,pr))||tr<3L||pr<3L) stop("Sphere resolutions must be at least three.",call.=FALSE)
  PolyData$new(cpp_pd_sphere(center,radius,tr,pr))
}
#' @rdname geometry
#' @export
pd_cylinder <- function(center=c(0,0,0),radius=1,height=1,resolution=30L,capping=TRUE,direction=c(0,1,0)) {
  .vs_vec3(center,"center");.vs_numeric(radius,"radius",1L,TRUE);.vs_numeric(height,"height",1L,TRUE);.vs_vec3(direction,"direction")
  if(sum(direction^2)==0)stop("`direction` must be nonzero.",call.=FALSE);resolution<-as.integer(resolution)
  if(length(resolution)!=1L||is.na(resolution)||resolution<3L)stop("`resolution` must be at least three.",call.=FALSE)
  PolyData$new(cpp_pd_cylinder(center,radius,height,resolution,isTRUE(capping),direction))
}

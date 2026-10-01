#include "vstar_types.h"
#include <vtkPointData.h>
#include <vtkDataArray.h>
using namespace Rcpp;static NumericVector bnd(vtkDataSet*x){double b[6];x->GetBounds(b);return NumericVector(b,b+6);}static NumericVector rng(vtkDataArray*a){if(!a)stop("No active point scalars.");double r[2];a->GetRange(r);return NumericVector::create(r[0],r[1]);}static std::string nm(vtkDataArray*a){if(!a)return "";return a->GetName()?a->GetName():"";}
// [[Rcpp::export]]
IntegerVector cpp_image_dimensions(SEXP p){int d[3];checked_image(p)->data->GetDimensions(d);return IntegerVector::create(d[0],d[1],d[2]);}
// [[Rcpp::export]]
NumericVector cpp_image_spacing(SEXP p){double x[3];checked_image(p)->data->GetSpacing(x);return NumericVector::create(x[0],x[1],x[2]);}
// [[Rcpp::export]]
NumericVector cpp_image_origin(SEXP p){double x[3];checked_image(p)->data->GetOrigin(x);return NumericVector::create(x[0],x[1],x[2]);}
// [[Rcpp::export]]
NumericVector cpp_image_bounds(SEXP p){return bnd(checked_image(p)->data);}
// [[Rcpp::export]]
NumericVector cpp_image_scalar_range(SEXP p){return rng(checked_image(p)->data->GetPointData()->GetScalars());}
// [[Rcpp::export]]
std::string cpp_image_scalar_name(SEXP p){return nm(checked_image(p)->data->GetPointData()->GetScalars());}
// [[Rcpp::export]]
int cpp_poly_n_points(SEXP p){return checked_poly(p)->data->GetNumberOfPoints();}
// [[Rcpp::export]]
int cpp_poly_n_cells(SEXP p){return checked_poly(p)->data->GetNumberOfCells();}
// [[Rcpp::export]]
NumericVector cpp_poly_bounds(SEXP p){return bnd(checked_poly(p)->data);}
// [[Rcpp::export]]
bool cpp_poly_has_scalars(SEXP p){return checked_poly(p)->data->GetPointData()->GetScalars()!=nullptr;}
// [[Rcpp::export]]
NumericVector cpp_poly_scalar_range(SEXP p){return rng(checked_poly(p)->data->GetPointData()->GetScalars());}
// [[Rcpp::export]]
std::string cpp_poly_scalar_name(SEXP p){return nm(checked_poly(p)->data->GetPointData()->GetScalars());}

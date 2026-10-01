#include "vstar_types.h"
#include <vtkFlyingEdges3D.h>
#include <vtkCutter.h>
#include <vtkPlane.h>
#include <vtkTubeFilter.h>
#include <vtkDelaunay2D.h>
#include <vtkTransform.h>
#include <vtkTransformPolyDataFilter.h>
#include <vtkPointData.h>
using namespace Rcpp;static vtkSmartPointer<vtkPolyData> detach(vtkPolyData*x){auto y=vtkSmartPointer<vtkPolyData>::New();y->ShallowCopy(x);return y;}
// [[Rcpp::export]]
SEXP cpp_image_contour(SEXP p,NumericVector levels){auto x=checked_image(p);if(levels.size()<1||!x->data->GetPointData()->GetScalars())stop("Contour requires active scalars and at least one level.");auto f=vtkSmartPointer<vtkFlyingEdges3D>::New();f->SetInputData(x->data);for(R_xlen_t i=0;i<levels.size();++i)f->SetValue(i,levels[i]);f->ComputeNormalsOn();f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_image_slice(SEXP p,NumericVector o,NumericVector n){auto x=checked_image(p);if(o.size()!=3||n.size()!=3)stop("Origin and normal must have length three.");auto plane=vtkSmartPointer<vtkPlane>::New();plane->SetOrigin(o[0],o[1],o[2]);plane->SetNormal(n[0],n[1],n[2]);auto f=vtkSmartPointer<vtkCutter>::New();f->SetInputData(x->data);f->SetCutFunction(plane);f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_image_deep_copy(SEXP p){auto x=checked_image(p);auto y=vtkSmartPointer<vtkImageData>::New();y->DeepCopy(x->data);return wrap_image(y);}
// [[Rcpp::export]]
SEXP cpp_poly_tube(SEXP p,double r,int sides,bool cap){auto x=checked_poly(p);if(r<=0||sides<3)stop("Invalid tube arguments.");auto f=vtkSmartPointer<vtkTubeFilter>::New();f->SetInputData(x->data);f->SetRadius(r);f->SetNumberOfSides(sides);f->SetCapping(cap);f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_poly_delaunay_2d(SEXP p,double tol,double alpha){auto x=checked_poly(p);if(tol<0||alpha<0)stop("Invalid Delaunay arguments.");auto f=vtkSmartPointer<vtkDelaunay2D>::New();f->SetInputData(x->data);f->SetTolerance(tol);f->SetAlpha(alpha);f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_poly_transform(SEXP p,NumericMatrix m){auto x=checked_poly(p);if(m.nrow()!=4||m.ncol()!=4)stop("Matrix must be 4 x 4.");double a[16];for(int i=0;i<4;++i)for(int j=0;j<4;++j)a[4*i+j]=m(i,j);auto t=vtkSmartPointer<vtkTransform>::New();t->SetMatrix(a);auto f=vtkSmartPointer<vtkTransformPolyDataFilter>::New();f->SetInputData(x->data);f->SetTransform(t);f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_poly_deep_copy(SEXP p){auto x=checked_poly(p);auto y=vtkSmartPointer<vtkPolyData>::New();y->DeepCopy(x->data);return wrap_poly(y);}

#include "vstar_types.h"
#include <vtkLineSource.h>
#include <vtkSphereSource.h>
#include <vtkCylinderSource.h>
#include <vtkParametricSpline.h>
#include <vtkParametricFunctionSource.h>
#include <vtkPoints.h>
#include <vtkTransform.h>
#include <vtkTransformPolyDataFilter.h>
#include <vtkMath.h>
#include <algorithm>
#include <cmath>
using namespace Rcpp;static vtkSmartPointer<vtkPolyData> detach(vtkPolyData*x){auto y=vtkSmartPointer<vtkPolyData>::New();y->ShallowCopy(x);return y;}
// [[Rcpp::export]]
SEXP cpp_pd_line(NumericVector a,NumericVector b,int r){if(a.size()!=3||b.size()!=3||r<1)stop("Invalid line arguments.");auto s=vtkSmartPointer<vtkLineSource>::New();s->SetPoint1(a[0],a[1],a[2]);s->SetPoint2(b[0],b[1],b[2]);s->SetResolution(r);s->Update();return wrap_poly(detach(s->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_pd_spline(NumericMatrix x,int n,bool closed){if(x.ncol()!=3||x.nrow()<2||n<2)stop("Invalid spline arguments.");auto p=vtkSmartPointer<vtkPoints>::New();for(int i=0;i<x.nrow();++i)p->InsertNextPoint(x(i,0),x(i,1),x(i,2));auto s=vtkSmartPointer<vtkParametricSpline>::New();s->SetPoints(p);s->SetClosed(closed);auto f=vtkSmartPointer<vtkParametricFunctionSource>::New();f->SetParametricFunction(s);f->SetUResolution(n-1);f->Update();return wrap_poly(detach(f->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_pd_sphere(NumericVector c,double radius,int tr,int pr){if(c.size()!=3||radius<=0||tr<3||pr<3)stop("Invalid sphere arguments.");auto s=vtkSmartPointer<vtkSphereSource>::New();s->SetCenter(c[0],c[1],c[2]);s->SetRadius(radius);s->SetThetaResolution(tr);s->SetPhiResolution(pr);s->Update();return wrap_poly(detach(s->GetOutput()));}
// [[Rcpp::export]]
SEXP cpp_pd_cylinder(NumericVector c,double radius,double height,int resolution,bool cap,NumericVector direction){if(c.size()!=3||direction.size()!=3||radius<=0||height<=0||resolution<3)stop("Invalid cylinder arguments.");double d[3]={direction[0],direction[1],direction[2]};if(vtkMath::Normalize(d)==0)stop("Direction must be nonzero.");auto s=vtkSmartPointer<vtkCylinderSource>::New();s->SetRadius(radius);s->SetHeight(height);s->SetResolution(resolution);s->SetCapping(cap);s->Update();double y[3]={0,1,0},axis[3];vtkMath::Cross(y,d,axis);double dot=std::max(-1.0,std::min(1.0,vtkMath::Dot(y,d)));auto t=vtkSmartPointer<vtkTransform>::New();t->PostMultiply();if(vtkMath::Norm(axis)>1e-12){vtkMath::Normalize(axis);t->RotateWXYZ(std::acos(dot)*180/vtkMath::Pi(),axis);}else if(dot<0)t->RotateWXYZ(180,1,0,0);t->Translate(c[0],c[1],c[2]);auto f=vtkSmartPointer<vtkTransformPolyDataFilter>::New();f->SetInputConnection(s->GetOutputPort());f->SetTransform(t);f->Update();return wrap_poly(detach(f->GetOutput()));}

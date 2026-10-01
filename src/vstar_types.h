#ifndef VSTAR_TYPES_H
#define VSTAR_TYPES_H
#include <Rcpp.h>
#include <vtkSmartPointer.h>
#include <vtkImageData.h>
#include <vtkPolyData.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkProp.h>
#include <vtkObject.h>
#include <vector>
class VstarImageData { public: vtkSmartPointer<vtkImageData> data; explicit VstarImageData(vtkSmartPointer<vtkImageData> x):data(x){} };
class VstarPolyData { public: vtkSmartPointer<vtkPolyData> data; explicit VstarPolyData(vtkSmartPointer<vtkPolyData> x):data(x){} };
class VstarPlotter { public: vtkSmartPointer<vtkRenderer> renderer; vtkSmartPointer<vtkRenderWindow> window; vtkSmartPointer<vtkRenderWindowInteractor> interactor; std::vector<vtkSmartPointer<vtkProp>> props; std::vector<vtkSmartPointer<vtkObject>> resources; bool closed=false; VstarPlotter(); void close(); };
using ImageXPtr=Rcpp::XPtr<VstarImageData>; using PolyXPtr=Rcpp::XPtr<VstarPolyData>; using PlotXPtr=Rcpp::XPtr<VstarPlotter>;
inline ImageXPtr checked_image(SEXP x){if(TYPEOF(x)!=EXTPTRSXP||!Rf_inherits(x,"vstar_image_ptr"))Rcpp::stop("Invalid ImageData external pointer.");ImageXPtr p(x);if(!p.get()||!p->data)Rcpp::stop("ImageData pointer is null.");return p;}
inline PolyXPtr checked_poly(SEXP x){if(TYPEOF(x)!=EXTPTRSXP||!Rf_inherits(x,"vstar_poly_ptr"))Rcpp::stop("Invalid PolyData external pointer.");PolyXPtr p(x);if(!p.get()||!p->data)Rcpp::stop("PolyData pointer is null.");return p;}
inline PlotXPtr checked_plotter(SEXP x,bool allow_closed=false){if(TYPEOF(x)!=EXTPTRSXP||!Rf_inherits(x,"vstar_plotter_ptr"))Rcpp::stop("Invalid Plotter external pointer.");PlotXPtr p(x);if(!p.get())Rcpp::stop("Plotter pointer is null.");if(p->closed&&!allow_closed)Rcpp::stop("Plotter is closed.");return p;}
inline SEXP wrap_image(vtkSmartPointer<vtkImageData>x){ImageXPtr p(new VstarImageData(x),true);p.attr("class")=Rcpp::CharacterVector::create("vstar_image_ptr","externalptr");return p;}
inline SEXP wrap_poly(vtkSmartPointer<vtkPolyData>x){PolyXPtr p(new VstarPolyData(x),true);p.attr("class")=Rcpp::CharacterVector::create("vstar_poly_ptr","externalptr");return p;}
inline SEXP wrap_plotter(VstarPlotter*x){PlotXPtr p(x,true);p.attr("class")=Rcpp::CharacterVector::create("vstar_plotter_ptr","externalptr");return p;}
#endif

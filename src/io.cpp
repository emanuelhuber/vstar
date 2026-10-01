#include "vstar_types.h"
#include <vtkXMLImageDataReader.h>
#include <vtkXMLImageDataWriter.h>
#include <vtkXMLPolyDataReader.h>
#include <vtkXMLPolyDataWriter.h>
using namespace Rcpp;
// [[Rcpp::export]]
SEXP cpp_read_image_data(std::string f){auto r=vtkSmartPointer<vtkXMLImageDataReader>::New();r->SetFileName(f.c_str());r->Update();auto x=vtkSmartPointer<vtkImageData>::New();x->ShallowCopy(r->GetOutput());if(x->GetNumberOfPoints()<1)stop("No image points were read.");return wrap_image(x);}
// [[Rcpp::export]]
SEXP cpp_read_poly_data(std::string f){auto r=vtkSmartPointer<vtkXMLPolyDataReader>::New();r->SetFileName(f.c_str());r->Update();auto x=vtkSmartPointer<vtkPolyData>::New();x->ShallowCopy(r->GetOutput());return wrap_poly(x);}

// void cpp_write_image_data(SEXP p,std::string f){auto w=vtkSmartPointer<vtkXMLImageDataWriter>::New();w->SetFileName(f.c_str());w->SetInputData(checked_image(p)->data);if(w->Write()!=1)stop("Failed to write VTI file.");}
// [[Rcpp::export]]
void cpp_write_image_data(SEXP ptr, std::string filename) {
  auto image = checked_image(ptr);
  
  auto writer = vtkSmartPointer<vtkXMLImageDataWriter>::New();
  
  writer->SetFileName(filename.c_str());
  writer->SetInputData(image->data);
  
  // Produce portable, well-formed XML without appended binary payload.
  writer->SetDataModeToAscii();
  
  if (writer->Write() != 1) {
    Rcpp::stop("Failed to write VTI file.");
  }
}

// void cpp_write_poly_data(SEXP p,std::string f){auto w=vtkSmartPointer<vtkXMLPolyDataWriter>::New();w->SetFileName(f.c_str());w->SetInputData(checked_poly(p)->data);if(w->Write()!=1)stop("Failed to write VTP file.");}
// [[Rcpp::export]]
void cpp_write_poly_data(SEXP ptr, std::string filename) {
  auto poly_data = checked_poly(ptr);
  
  auto writer = vtkSmartPointer<vtkXMLPolyDataWriter>::New();
  
  writer->SetFileName(filename.c_str());
  writer->SetInputData(poly_data->data);
  
  writer->SetDataModeToAscii();
  
  if (writer->Write() != 1) {
    Rcpp::stop("Failed to write VTP file.");
  }
}
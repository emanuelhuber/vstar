#include "vstar_types.h"
#include <vtkDoubleArray.h>
#include <vtkPointData.h>
#include <vtkPoints.h>
#include <vtkCellArray.h>
using namespace Rcpp;
// [[Rcpp::export]]
SEXP cpp_create_image_data(NumericVector v,IntegerVector d,NumericVector s,NumericVector o){if(d.size()!=3||s.size()!=3||o.size()!=3)stop("Invalid image metadata.");vtkIdType n=(vtkIdType)d[0]*d[1]*d[2];if(n<=0||n!=v.size())stop("Image dimensions and scalar count disagree.");auto x=vtkSmartPointer<vtkImageData>::New();x->SetDimensions(d[0],d[1],d[2]);x->SetSpacing(s[0],s[1],s[2]);x->SetOrigin(o[0],o[1],o[2]);auto a=vtkSmartPointer<vtkDoubleArray>::New();a->SetName("values");a->SetNumberOfComponents(1);a->SetNumberOfTuples(n);for(vtkIdType i=0;i<n;++i)a->SetValue(i,v[i]);x->GetPointData()->SetScalars(a);return wrap_image(x);}
static void add_cells(vtkCellArray*c,Nullable<List> input,vtkIdType np,int minimum){if(input.isNull())return;List z(input);for(R_xlen_t i=0;i<z.size();++i){IntegerVector q=z[i];if(q.size()<minimum)stop("Connectivity cell has too few vertices.");std::vector<vtkIdType> ids(q.size());for(R_xlen_t j=0;j<q.size();++j){if(q[j]<1||q[j]>np)stop("Connectivity index is outside vertex range.");ids[j]=q[j]-1;}c->InsertNextCell(ids.size(),ids.data());}}
// [[Rcpp::export]]
SEXP cpp_create_poly_data(NumericMatrix v,Nullable<List> f=R_NilValue,Nullable<List> l=R_NilValue){if(v.ncol()!=3||v.nrow()<1)stop("Vertices must be n by 3.");auto p=vtkSmartPointer<vtkPoints>::New();for(int i=0;i<v.nrow();++i)p->InsertNextPoint(v(i,0),v(i,1),v(i,2));auto pc=vtkSmartPointer<vtkCellArray>::New();auto lc=vtkSmartPointer<vtkCellArray>::New();add_cells(pc,f,v.nrow(),3);add_cells(lc,l,v.nrow(),2);auto x=vtkSmartPointer<vtkPolyData>::New();x->SetPoints(p);x->SetPolys(pc);x->SetLines(lc);return wrap_poly(x);}

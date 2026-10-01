#include "vstar_types.h"
#include <vtkCellArray.h>
#include <vtkTriangleFilter.h>
using namespace Rcpp;static vtkSmartPointer<vtkPolyData> tri(vtkPolyData*x){auto f=vtkSmartPointer<vtkTriangleFilter>::New();f->SetInputData(x);f->PassLinesOff();f->PassVertsOff();f->Update();auto y=vtkSmartPointer<vtkPolyData>::New();y->ShallowCopy(f->GetOutput());return y;}static IntegerMatrix tm(vtkPolyData*x){auto c=x->GetPolys();IntegerMatrix z(3,c->GetNumberOfCells());vtkIdType n,k=0;const vtkIdType*ids;c->InitTraversal();while(c->GetNextCell(n,ids)){if(n!=3)stop("Non-triangular polygon encountered.");for(int j=0;j<3;++j)z(j,k)=ids[j]+1;++k;}return z;}
// [[Rcpp::export]]
NumericMatrix cpp_poly_points(SEXP p){auto x=checked_poly(p)->data;NumericMatrix z(x->GetNumberOfPoints(),3);double q[3];for(vtkIdType i=0;i<x->GetNumberOfPoints();++i){x->GetPoint(i,q);for(int j=0;j<3;++j)z(i,j)=q[j];}colnames(z)=CharacterVector::create("x","y","z");return z;}
// [[Rcpp::export]]
List cpp_poly_faces(SEXP p){auto c=checked_poly(p)->data->GetPolys();List z(c->GetNumberOfCells());vtkIdType n,k=0;const vtkIdType*ids;c->InitTraversal();while(c->GetNextCell(n,ids)){IntegerVector q(n);for(vtkIdType j=0;j<n;++j)q[j]=ids[j]+1;z[k++]=q;}return z;}
// [[Rcpp::export]]
IntegerMatrix cpp_poly_triangles(SEXP p){return tm(tri(checked_poly(p)->data));}
// [[Rcpp::export]]
List cpp_poly_as_mesh3d(SEXP p,bool triangulate){vtkSmartPointer<vtkPolyData>x=checked_poly(p)->data;if(triangulate)x=tri(x);NumericMatrix vb(4,x->GetNumberOfPoints());double q[3];for(vtkIdType i=0;i<x->GetNumberOfPoints();++i){x->GetPoint(i,q);vb(0,i)=q[0];vb(1,i)=q[1];vb(2,i)=q[2];vb(3,i)=1;}return List::create(_["vb"]=vb,_["it"]=tm(x),_["primitivetype"]="triangle");}

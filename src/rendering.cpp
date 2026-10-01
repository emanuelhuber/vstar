#include "vstar_types.h"
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkProperty.h>
#include <vtkInteractorStyleTrackballCamera.h>
#include <vtkLookupTable.h>
#include <vtkScalarBarActor.h>
#include <vtkSmartVolumeMapper.h>
#include <vtkVolume.h>
#include <vtkVolumeProperty.h>
#include <vtkColorTransferFunction.h>
#include <vtkPiecewiseFunction.h>
#include <vtkWindowToImageFilter.h>
#include <vtkPNGWriter.h>
#include <vtkPointData.h>
#include <algorithm>
using namespace Rcpp;
VstarPlotter::VstarPlotter(){renderer=vtkSmartPointer<vtkRenderer>::New();window=vtkSmartPointer<vtkRenderWindow>::New();interactor=vtkSmartPointer<vtkRenderWindowInteractor>::New();auto style=vtkSmartPointer<vtkInteractorStyleTrackballCamera>::New();window->AddRenderer(renderer);interactor->SetRenderWindow(window);interactor->SetInteractorStyle(style);resources.push_back(style);}
void VstarPlotter::close(){if(closed)return;if(interactor)interactor->TerminateApp();if(renderer)renderer->RemoveAllViewProps();props.clear();resources.clear();if(window)window->Finalize();interactor=nullptr;renderer=nullptr;window=nullptr;closed=true;}
static void rgb(std::string n,double t,double&r,double&g,double&b){t=std::max(0.,std::min(1.,t));if(n=="grayscale"){r=g=b=t;return;}struct C{double p,r,g,b;};static C vir[]={{0,.267,.005,.329},{.25,.230,.322,.546},{.5,.128,.567,.551},{.75,.369,.789,.383},{1,.993,.906,.144}};static C pla[]={{0,.050,.030,.528},{.25,.494,.012,.658},{.5,.798,.280,.470},{.75,.973,.586,.252},{1,.940,.975,.131}};static C mag[]={{0,.001,0,.014},{.25,.316,.071,.485},{.5,.716,.215,.475},{.75,.987,.536,.382},{1,.987,.991,.749}};static C inf[]={{0,.001,0,.014},{.25,.342,.062,.429},{.5,.735,.216,.330},{.75,.978,.557,.035},{1,.988,.998,.645}};C*a=vir;if(n=="plasma")a=pla;else if(n=="magma")a=mag;else if(n=="inferno")a=inf;int i=std::min(3,(int)(t*4));double u=(t-a[i].p)/(a[i+1].p-a[i].p);r=a[i].r+u*(a[i+1].r-a[i].r);g=a[i].g+u*(a[i+1].g-a[i].g);b=a[i].b+u*(a[i+1].b-a[i].b);}
static vtkSmartPointer<vtkLookupTable> make_lut(std::string n,NumericVector range){auto l=vtkSmartPointer<vtkLookupTable>::New();l->SetNumberOfTableValues(256);l->SetRange(range[0],range[1]);for(int i=0;i<256;++i){double r,g,b;rgb(n,i/255.,r,g,b);l->SetTableValue(i,r,g,b,1);}l->Build();return l;}
static vtkSmartPointer<vtkColorTransferFunction> make_ctf(std::string n,NumericVector range){auto c=vtkSmartPointer<vtkColorTransferFunction>::New();for(int i=0;i<9;++i){double t=i/8.,r,g,b;rgb(n,t,r,g,b);c->AddRGBPoint(range[0]+t*(range[1]-range[0]),r,g,b);}return c;}
// [[Rcpp::export]]
SEXP cpp_plotter_create(NumericVector bg,IntegerVector size,std::string title){if(bg.size()!=3||size.size()!=2||size[0]<1||size[1]<1)stop("Invalid plotter configuration.");auto p=new VstarPlotter();p->renderer->SetBackground(bg[0],bg[1],bg[2]);p->window->SetSize(size[0],size[1]);p->window->SetWindowName(title.c_str());return wrap_plotter(p);}
// [[Rcpp::export]]
int cpp_plotter_add_mesh(SEXP pp,SEXP pdp,NumericVector color,double opacity,std::string rep,bool scalars,std::string cmap,NumericVector range,bool bar){auto p=checked_plotter(pp);auto pd=checked_poly(pdp);auto mapper=vtkSmartPointer<vtkPolyDataMapper>::New();mapper->SetInputData(pd->data);if(scalars){auto arr=pd->data->GetPointData()->GetScalars();if(!arr)stop("PolyData has no active point scalars.");auto lut=make_lut(cmap,range);mapper->SetLookupTable(lut);mapper->SetScalarRange(range[0],range[1]);mapper->SetScalarModeToUsePointData();mapper->ScalarVisibilityOn();p->resources.push_back(lut);if(bar){auto sb=vtkSmartPointer<vtkScalarBarActor>::New();sb->SetLookupTable(lut);sb->SetTitle(arr->GetName()?arr->GetName():"Scalars");p->renderer->AddActor2D(sb);p->props.push_back(sb);}}else mapper->ScalarVisibilityOff();auto actor=vtkSmartPointer<vtkActor>::New();actor->SetMapper(mapper);actor->GetProperty()->SetColor(color[0],color[1],color[2]);actor->GetProperty()->SetOpacity(opacity);if(rep=="wireframe")actor->GetProperty()->SetRepresentationToWireframe();else if(rep=="points")actor->GetProperty()->SetRepresentationToPoints();else actor->GetProperty()->SetRepresentationToSurface();p->renderer->AddActor(actor);p->props.push_back(actor);p->resources.push_back(mapper);return p->props.size();}
// [[Rcpp::export]]
int cpp_plotter_add_volume(SEXP pp,SEXP ip,std::string cmap,NumericMatrix opacity,NumericVector range,bool shade){auto p=checked_plotter(pp);auto im=checked_image(ip);if(!im->data->GetPointData()->GetScalars())stop("ImageData has no active scalars.");auto mapper=vtkSmartPointer<vtkSmartVolumeMapper>::New();mapper->SetInputData(im->data);auto color=make_ctf(cmap,range);auto alpha=vtkSmartPointer<vtkPiecewiseFunction>::New();for(int i=0;i<opacity.nrow();++i)alpha->AddPoint(opacity(i,0),opacity(i,1));auto prop=vtkSmartPointer<vtkVolumeProperty>::New();prop->SetColor(color);prop->SetScalarOpacity(alpha);prop->SetInterpolationTypeToLinear();prop->SetShade(shade);auto volume=vtkSmartPointer<vtkVolume>::New();volume->SetMapper(mapper);volume->SetProperty(prop);p->renderer->AddVolume(volume);p->props.push_back(volume);p->resources.push_back(mapper);p->resources.push_back(color);p->resources.push_back(alpha);p->resources.push_back(prop);return p->props.size();}
// [[Rcpp::export]]
void cpp_plotter_set_background(SEXP p,NumericVector c){checked_plotter(p)->renderer->SetBackground(c[0],c[1],c[2]);}
// [[Rcpp::export]]
void cpp_plotter_reset_camera(SEXP p){checked_plotter(p)->renderer->ResetCamera();}
// [[Rcpp::export]]
void cpp_plotter_clear(SEXP p){auto x=checked_plotter(p);x->renderer->RemoveAllViewProps();x->props.clear();x->resources.clear();}
// [[Rcpp::export]]
void cpp_plotter_render(SEXP p){checked_plotter(p)->window->Render();}
// [[Rcpp::export]]
void cpp_plotter_show(SEXP p){auto x=checked_plotter(p);x->window->Render();x->interactor->Initialize();x->interactor->Start();}
// [[Rcpp::export]]
void cpp_plotter_screenshot(SEXP p,std::string file,int scale,bool alpha){auto x=checked_plotter(p);x->window->Render();auto f=vtkSmartPointer<vtkWindowToImageFilter>::New();f->SetInput(x->window);f->SetScale(scale);if(alpha)f->SetInputBufferTypeToRGBA();else f->SetInputBufferTypeToRGB();f->ReadFrontBufferOff();f->Update();auto w=vtkSmartPointer<vtkPNGWriter>::New();w->SetFileName(file.c_str());w->SetInputConnection(f->GetOutputPort());w->Write();}
// [[Rcpp::export]]
void cpp_plotter_close(SEXP p){checked_plotter(p,true)->close();}

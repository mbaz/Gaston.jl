## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

# Structs to define a figure

## Coordinates
Coord = Union{Range{T},Array{T}} where T <: Real

# storage for financial coordinates
struct FinancialCoords
    valid::Bool
    open::Coord
    low::Coord
    high::Coord
    close::Coord
end
FinancialCoords() = FinancialCoords(false,Real[],Real[],Real[],Real[])
function FinancialCoords(o::Vector,l::Vector,h::Vector,c::Vector)
    return FinancialCoords(true,o,l,h,c)
end

# storage for error coordinates
struct ErrorCoords
    valid::Bool
    ylow::Coord
    yhigh::Coord
end
ErrorCoords() = ErrorCoords(false,Real[],Real[])
ErrorCoords(l::Vector) = ErrorCoords(true,l,Real[])
ErrorCoords(l::Vector,h::Vector) = ErrorCoords(true,l,h)

## Curves
# Curve configuration
struct CurveConf
    legend::AbstractString          # legend text
    plotstyle::AbstractString
    color::AbstractString           # one of gnuplot's builtin colors --
                                    # run 'show colornames' inside gnuplot
    marker::AbstractString          # point type
    linewidth::Real
    linestyle::AbstractString
    pointsize::Real
end
# Convenience constructor
CurveConf(;
          legend    = gaston_config.legend,
          plotstyle = gaston_config.plotstyle,
          color     = gaston_config.color,
          marker    = gaston_config.marker,
          linewidth = gaston_config.linewidth,
          linestyle = gaston_config.linestyle,
          pointsize = gaston_config.pointsize
         ) = CurveConf(legend,plotstyle,color,marker,linewidth,linestyle,pointsize)

# A curve is a set of coordinates and a configuration
mutable struct Curve
    x::Coord
    y::Coord
    Z::Coord
    F::FinancialCoords
    E::ErrorCoords
    conf::CurveConf
end
# Construct an empty curve
Curve() = Curve(Real[],Real[],Real[],FinancialCoords(),ErrorCoords(),CurveConf())
# Convenience constructors
Curve(y) = Curve(1:length(y),y,Real[],
                 FinancialCoords(),ErrorCoords(),CurveConf())
Curve(y,c::CurveConf) = Curve(1:length(y),y,Real[],
                              FinancialCoords(),ErrorCoords(),c)
Curve(x,y) = Curve(x,y,Real[],FinancialCoords(),ErrorCoords(),CurveConf())
Curve(x,y,c::CurveConf) = Curve(x,y,Real[],FinancialCoords(),ErrorCoords(),c)
Curve(x,y,fc::FinancialCoords,ec::ErrorCoords,c::CurveConf) =
    Curve(x,y,Real[],fc,ec,c)
Curve(x,y,Z) = Curve(x,y,Z,FinancialCoords(),ErrorCoords(),CurveConf())
Curve(x,y,Z,c::CurveConf) = Curve(x,y,Z,FinancialCoords(),ErrorCoords(),c)

## Axes
# Storage for axes configuration
mutable struct AxesConf
    title::AbstractString      # plot title
    xlabel::AbstractString     # xlabel
    ylabel::AbstractString     # ylabel
    zlabel::AbstractString     # zlabel for 3-d plots
    fill::AbstractString       # fill style
    grid::AbstractString       # grid on/off
    box::AbstractString        # legend box (used with 'set key')
    axis::AbstractString       # normal, semilog{x,y}, loglog
    xrange::AbstractString     # xrange
    yrange::AbstractString     # yrange
    zrange::AbstractString     # zrange
    palette::AbstractString    # palette
end
# Constructor with default values (stored in gaston_config)
AxesConf(;
      title   = gaston_config.title,
      xlabel  = gaston_config.xlabel,
      ylabel  = gaston_config.ylabel,
      zlabel  = gaston_config.zlabel,
      fill    = gaston_config.fill,
      grid    = gaston_config.grid,
      box     = gaston_config.box,
      axis    = gaston_config.axis,
      xrange  =  gaston_config.xrange,
      yrange  =  gaston_config.yrange,
      zrange  =  gaston_config.zrange,
      palette = gaston_config.palette
      ) = AxesConf(title,xlabel,ylabel,zlabel,fill,grid,
                   box,axis,xrange,yrange,zrange,palette)

# At the top level, a figure is a handle, an axes configuration, and a
# set of curves.
mutable struct Figure
    handle                       # each figure has a unique handle
    conf::AxesConf               # figure configuration
    curves::Vector{Curve}        # a vector of curves
    isempty::Bool                # a flag to indicate if figure is empty
    svgdata
end
# Construct an empty figure with given handle
Figure(handle) = Figure(handle,AxesConf(),Curve[],true,"")

# We need a global variable to keep track of gnuplot's state
mutable struct GnuplotState
    running::Bool                # true when gnuplot is already running
    current                      # current figure -- "pointer" to figs
    fid                          # pipe streams id
    gp_stdout::AbstractString    # store gnuplot's stdout
    gp_stderr::AbstractString    # store gnuplot's stderr
    gp_lasterror::AbstractString # store gnuplot's last error output
    gp_error::Bool               # true if last command resulted in gp error
    figs::Array{Figure}          # storage for all figures
    isjupyter::Bool              # true if running inside a jupyter notebook
end

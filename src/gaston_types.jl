## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

# Structs to define a figure

## Coordinates
Coord = Union{AbstractRange{T},Array{T}} where T <: Real

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
    legend::String
    plotstyle::String
    linecolor::String       # run 'show colornames' inside gnuplot
    pointtype::String
    linewidth::String
    linestyle::String
    pointsize::String
end
# Convenience constructor
CurveConf(;
          legend    = "",
          plotstyle = gaston_config.plotstyle,
          linecolor = gaston_config.linecolor,
          pointtype = gaston_config.pointtype,
          linewidth = gaston_config.linewidth,
          linestyle = gaston_config.linestyle,
          pointsize = gaston_config.pointsize
         ) = CurveConf(legend,plotstyle,linecolor,pointtype,linewidth,linestyle,pointsize)

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
    title::String
    xlabel::String
    ylabel::String
    zlabel::String
    linewidth::String
    fill::String
    grid::String
    keyoptions::String
    axis::String
    xrange::String
    yrange::String
    zrange::String
    xzeroaxis::String
    yzeroaxis::String
    zzeroaxis::String
    font::String
    size::String
    background::String
    palette::String
    termopts::String
    # parameters for printing
    print_flag::Bool
    print_term::String
    print_font::String
    print_size::String
    print_linewidth::String
    print_outputfile::String
end
# Constructor with default values (stored in gaston_config)
AxesConf(;
      title            = "",
      xlabel           = "",
      ylabel           = "",
      zlabel           = "",
      linewidth        = gaston_config.linewidth,
      fill             = gaston_config.fill,
      grid             = gaston_config.grid,
      keyoptions       = gaston_config.keyoptions,
      axis             = gaston_config.axis,
      xrange           = gaston_config.xrange,
      yrange           = gaston_config.yrange,
      zrange           = gaston_config.zrange,
      xzeroaxis        = gaston_config.xzeroaxis,
      yzeroaxis        = gaston_config.yzeroaxis,
      zzeroaxis        = gaston_config.zzeroaxis,
      font             = gaston_config.font,
      size             = gaston_config.size,
      background       = gaston_config.background,
      palette          = gaston_config.palette,
      termopts         = gaston_config.termopts,
      print_flag       = false,
      print_term       = gaston_config.print_term,
      print_font       = gaston_config.print_font,
      print_size       = gaston_config.print_size,
      print_linewidth  = gaston_config.print_linewidth,
      print_outputfile = gaston_config.print_outputfile
      ) = AxesConf(title,xlabel,ylabel,zlabel,linewidth,fill,grid,keyoptions,
                   axis,xrange,yrange,zrange,xzeroaxis,yzeroaxis,zzeroaxis,
                   font,size,background,palette,termopts,print_flag,print_term,
                   print_font,print_size,print_linewidth,print_outputfile)

# At the top level, a figure is a handle, an axes configuration, and a
# set of curves.
mutable struct Figure
    handle                       # each figure has a unique handle
    conf::AxesConf               # figure configuration
    curves::Vector{Curve}        # a vector of curves
    isempty::Bool                # a flag to indicate if figure is empty
    svg::String          # SVG data returned by gnuplot (used in IJulia)
    gpcom::String        # a gnuplot command to run before plotting
end
# Construct an empty figure with given handle
Figure(handle) = Figure(handle,AxesConf(),Curve[],true,"","")

# We need a global variable to keep track of gnuplot's state
mutable struct GnuplotState
    current                      # current figure -- "pointer" to figs
    process                      # the gnuplot process
    gp_stdout::String            # last data read from gnuplot's stdout
    gp_stderr::String            # last data read from  gnuplot's stderr
    gp_lasterror::String         # gnuplot's last error output
    gp_error::Bool               # true if last command resulted in gp error
    figs::Array{Figure}          # storage for all figures
end

GnuplotState() = GnuplotState(nothing,nothing,"","","",false,Figure[])

## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

# Structs to define a figure

## Term configuration
mutable struct TermConf
    font::String
    size::String
    linewidth::String
    background::String
end
TermConf() = TermConf("","","","")

mutable struct PrintConf
    print_term::String
    print_font::String
    print_size::String
    print_linewidth::String
    print_background::String
    print_outputfile::String
end
PrintConf() = PrintConf("","","","","","")

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
Base.@kwdef struct CurveConf
    legend::String    = ""
    plotstyle::String = config[:curve][:plotstyle]
    linecolor::String = config[:curve][:linecolor]
    linewidth::String = "1"
    linestyle::String = config[:curve][:linestyle]
    pointtype::String = config[:curve][:pointtype]
    pointsize::String = config[:curve][:pointsize]
    fillstyle::String = ""
    fillcolor::String = config[:curve][:pointsize]
end

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

# Storage for axes configuration
Base.@kwdef mutable struct AxesConf
    title::String      = ""
    xlabel::String     = ""
    ylabel::String     = ""
    zlabel::String     = ""
    fillstyle::String  = config[:axes][:fillstyle]
    grid::String       = config[:axes][:grid]
    keyoptions::String = config[:axes][:keyoptions]
    axis::String       = config[:axes][:axis]
    xrange::String     = config[:axes][:xrange]
    yrange::String     = config[:axes][:yrange]
    zrange::String     = config[:axes][:zrange]
    xzeroaxis::String  = config[:axes][:xzeroaxis]
    yzeroaxis::String  = config[:axes][:yzeroaxis]
    zzeroaxis::String  = config[:axes][:zzeroaxis]
    palette::String    = config[:axes][:palette]
end

# At the top level, a figure is a handle, an axes configuration, and a
# set of curves.
mutable struct Figure
    handle                       # each figure has a unique handle
    term::TermConf               # term options
    print::PrintConf             # print optinos
    axes::AxesConf               # figure configuration
    curves::Union{Nothing,Vector{Curve}} # a vector of curves
    svg::String          # SVG data returned by gnuplot (used in IJulia)
    gpcom::String        # a gnuplot command to run before plotting
end
# Construct an empty figure with given handle
Figure(handle) = Figure(handle,TermConf(),PrintConf(),AxesConf(),nothing,"","")

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

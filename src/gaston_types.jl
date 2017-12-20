## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# types and constructors

# We need a global variable to keep track of gnuplot's state
mutable struct GnuplotState
    running::Bool                # true when gnuplot is already running
    current                      # current figure -- "pointer" to figs
    fid                          # pipe streams id
	gp_stdout::AbstractString    # store gnuplot's stdout
	gp_stderr::AbstractString    # store gnuplot's stderr
	gp_lasterror::AbstractString # store gnuplot's last error output
	gp_error::Bool               # true if last command resulted in gp error
    figs::Array                  # storage for all figures
end

# Structs to define a figure

## Coordinates
Coord = Union{UnitRange,Range,Array}

# storage for financial coordinates
struct FinancialCoords
	valid::Bool
    open::Coord
    low::Coord
    high::Coord
    close::Coord
end
FinancialCoords() = FinancialCoords(false,[],[],[],[])
function FinancialCoords(o::Vector,l::Vector,h::Vector,c::Vector)
	return FinancialCoords(true,o,l,h,c)
end

# storage for error coordinates
struct ErrorCoords
	valid::Bool
	ylow::Coord
	yhigh::Coord
end
ErrorCoords() = ErrorCoords(false,[],[])
ErrorCoords(l::Vector,h::Vector) = ErrorCoords(true,l,h)

## Curves
# Curve configuration
type CurveConf
    legend::AbstractString          # legend text
    plotstyle::AbstractString
    color::AbstractString           # one of gnuplot's builtin colors --
                                    # run 'show colornames' inside gnuplot
    marker::AbstractString          # point type
    linewidth::Real
    pointsize::Real
end
# Constructor with default values (stored in gaston_config)
CurveConf() = CurveConf(
    gaston_config.legend,
    gaston_config.plotstyle,
    gaston_config.color,
    gaston_config.marker,
    gaston_config.linewidth,
    gaston_config.pointsize)

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
Curve() = Curve([],[],[],FinancialCoords(),ErrorCoords(),CurveConf())
# Other convenience constructors
Curve(y) = Curve(1:length(y),y,[],FinancialCoords(),ErrorCoords(),CurveConf())
Curve(y,c::CurveConf) = Curve(1:length(y),y,[],FinancialCoords(),ErrorCoords(),c)
Curve(x,y) = Curve(x,y,[],FinancialCoords(),ErrorCoords(),CurveConf())
Curve(x,y,c::CurveConf) = Curve(x,y,[],FinancialCoords(),ErrorCoords(),c)
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
end
# Constructor with default values (stored in gaston_config)
AxesConf() = AxesConf(
    gaston_config.title,
    gaston_config.xlabel,
    gaston_config.ylabel,
    gaston_config.zlabel,
    gaston_config.fill,
    gaston_config.grid,
    gaston_config.box,
    gaston_config.axis,
    gaston_config.xrange,
    gaston_config.yrange,
    gaston_config.zrange)

# At the top level, a figure is a handle, an axes configuration, and a
# set of curves.
mutable struct Figure
    handle                       # each figure has a unique handle
    conf::AxesConf               # figure configuration
    curves::Vector{Curve}        # a vector of curves
    isempty::Bool                # a flag to indicate if figure is empty
end
# Construct an empty figure with given handle
Figure(handle) = Figure(handle,AxesConf(),Curve[Curve()],true)

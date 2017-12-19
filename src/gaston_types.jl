## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# types and constructors

# We need a global variable to keep track of gnuplot's state
mutable struct GnuplotState
    running::Bool                # true when gnuplot is already running
    current::Int                 # current figure
    fid                          # pipe streams id
	gp_stdout::AbstractString    # store gnuplot's stdout
	gp_stderr::AbstractString    # store gnuplot's stderr
	gp_lasterror::AbstractString # store gnuplot's last error output
	gp_error::Bool               # true if last command resulted in gp error
    figs::Array                  # storage for all figures
end

# Structs to configure a plot
# Two types of configuration are needed: one to configure a single curve, and
# another to configure a set of curves (the 'axes').
type CurveConf
    legend::AbstractString          # legend text
    plotstyle::AbstractString
    color::AbstractString           # one of gnuplot's builtin colors --
                            # run 'show colornames' inside gnuplot
    marker::AbstractString          # point type
    linewidth::Real
    pointsize::Real

end
CurveConf() = CurveConf(
    gaston_config.legend,
    gaston_config.plotstyle,
    gaston_config.color,
    gaston_config.marker,
    gaston_config.linewidth,
    gaston_config.pointsize)

type AxesConf
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

type Financial
    open::Vector
    low::Vector
    high::Vector
    close::Vector
end
Financial() = Financial(Any[],Any[],Any[],Any[])

# coordinates and configuration for a single curve
type CurveData
    x::Vector          # abscissa
    y::Vector          # ordinate
    Z::Array           # 3-d plots and images
    ylow::Vector       # error data
    yhigh::Vector      # error data
    finance::Financial # financial data
    conf::CurveConf    # curve configuration
end
CurveData() = CurveData(Any[],Any[],Any[],Any[],Any[],Financial(),CurveConf())
CurveData(x,y,Z,conf::CurveConf) = CurveData(x,y,Z,Any[],Any[],Financial(),conf)

# curves and configuration for a single figure
type Figure
    handle::Int                  # each figure has a unique handle
    curves::Vector{CurveData}    # a vector of curves (x,y,conf)
    conf::AxesConf               # figure configuration
    isempty::Bool                # a flag to indicate if figure is empty
end
Figure(handle) = Figure(handle,CurveData[CurveData()],AxesConf(),true)

# coordinate type
Coord = Union{UnitRange,Range,Matrix,Vector}

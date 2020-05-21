## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

## Coordinates
const Coord = Union{AbstractRange{T},AbstractArray{T}} where T <: Real
const ComplexCoord = AbstractArray{T} where T <: Complex
Coord() = Float64[] # return an empty coordinate

## Curves

# A curve is a set of coordinates and a plot string.
Base.@kwdef mutable struct Curve
    x::Coord     = Coord()
    y::Coord     = Coord()
    z::Coord     = Coord()
    supp::Coord  = Coord()
    conf::String = ""
end

# At the top level, a figure is a handle, an axes configuration, and a
# vector of curves.
Base.@kwdef mutable struct Figure
    handle::Int                     # each figure has a unique handle
    datafile         = tempname()   # file to store plot data
    dims::Int        = 2            # 2-D or 3-D plot
    axesconf::String = ""           # axes configuration
    curves::Vector{Curve} = Curve[] # a vector of curves
end
# Construct an empty figure with given handle
Figure(handle) = Figure(handle=handle)

# We need a global variable to keep track of gnuplot's state
mutable struct GnuplotState
    current                      # current figure -- "pointer" to figs
    process                      # the gnuplot process
    gp_stdout::String            # last data read from gnuplot's stdout
    gp_stderr::String            # last data read from  gnuplot's stderr
    gp_lasterror::String         # gnuplot's last error output
    gp_error::Bool               # true if last command resulted in gp error
    figs::Vector{Figure}         # storage for all figures
end

GnuplotState() = GnuplotState(nothing,nothing,"","","",false,Figure[])

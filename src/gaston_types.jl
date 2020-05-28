## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

## Axis configuration
mutable struct Axis
    axisconf::Dict{Symbol, Any}
end

Axis(pairs::Pair...) = Axis(Dict(pairs))
Axis(;args...) = Axis(args)
keys(a::Axis) = keys(a.axisconf)
getindex(a::Axis, args... ; kwargs...) = getindex(a.axisconf, args... ; kwargs...)
merge(a::Axis, b::Axis) = Axis(merge(a.axisconf, b.axisconf))

## Real coordinates
const NCoord = Union{AbstractRange{T}, AbstractArray{T}} where T # actual coordinates
const Coord = Union{NCoord, Nothing}  # nullable coordinates

## Complex coordinates
const ComplexCoord = AbstractArray{T} where T <: Complex

## Curves

# A curve is a set of coordinates and a plot string.
struct Curve{X, Y, Z, S}
    x::X
    y::Y
    z::Z
    supp::S
    conf::String
end

## Plots
# A plot has a datafile, dims, a configuration, and a set of curves.
Base.@kwdef mutable struct Plot
    datafile::String = tempname()   # file to store plot data
    dims::Int        = 2            # 2-D or 3-D plot
    axisconf::String = ""           # axes configuration
    curves::Vector{Curve} = Curve[] # a vector of curves
end
getindex(p::Plot, args... ; kwargs...) = getindex(p.curves, args... ; kwargs...)
isempty(p::Plot) = isempty(p.curves)

# A subplot can be a Plot, or can be nothing.
const SubPlot = Union{Plot, Nothing}
const SubPlots = Vector{SubPlot}

# A layout is a tuple of integers.
const Layout = Tuple{Int, Int}

## Figure
# At the top level, a figure is a handle, a layout and a set of Axes.
Base.@kwdef mutable struct Figure
    handle::Int                   # each figure has a unique handle
    layout::Layout     = (0,0)    # multiplot layout
    subplots::SubPlots = [Plot()] # a figure contains a number of plots
end
Figure(handle::Int) = Figure(handle=handle)

getindex(f::Figure, args... ; kwargs...) = getindex(f.subplots, args... ; kwargs...)

isempty(f::Figure; subplot = 1) = isempty(f[subplot])

length(f::Figure) = length(f.subplots)

function push!(f::Figure, c::Curve ; subplot = 1)
    if isempty(f, subplot=subplot)
        f[subplot].curves = [c]
    else
        push!(f[subplot].curves, c)
    end
end

function push!(f::Figure, sp::SubPlot)
    if isempty(f)
        f.subplots = [sp]
    else
        push!(f.subplots, sp)
    end
end

# Types needed for multiplot
const FigArray = Union{Matrix{Figure}, Matrix{Union{Figure, Nothing}}}

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

## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# All types and constructors are defined here.

# Structs to define a figure

## Term configuration
Base.@kwdef mutable struct TermConf
    font::String = config[:term][:font]
    size::String = config[:term][:size]
    background::String = config[:term][:background]
end

Base.@kwdef mutable struct PrintConf
    term::String       = ""
    termopts::String   = ""
    font::String       = ""
    size::String       = ""
    linewidth::String  = ""
    background::String = ""
    output::String     = ""
end

## Coordinates
const Coord = Union{AbstractRange{T},AbstractArray{T}} where T <: Real
const ComplexCoord = AbstractArray{T} where T <: Complex
Coord() = Float64[] # return an empty coordinate

# storage for financial coordinates
struct FinancialCoords
    open::Coord
    low::Coord
    high::Coord
    close::Coord
end
const FCuN = Union{FinancialCoords, Nothing}
FinancialCoords() = nothing

# storage for error coordinates
struct ErrorCoords
    ylow::Coord
    yhigh::Coord
end
const ECuN = Union{ErrorCoords, Nothing}
ErrorCoords() = nothing
ErrorCoords(l::Coord) = ErrorCoords(l,Float64[])

## Curves
# Curve configuration
Base.@kwdef mutable struct CurveConf
    legend::String    = ""
    plotstyle::String = config[:curve][:plotstyle]
    linecolor::String = config[:curve][:linecolor]
    linewidth::String = config[:curve][:linewidth]
    linestyle::String = config[:curve][:linestyle]
    linetype::String  = config[:curve][:linetype]
    pointtype::String = config[:curve][:pointtype]
    pointsize::String = config[:curve][:pointsize]
    fillstyle::String = config[:curve][:fillstyle]
    fillcolor::String = config[:curve][:pointsize]
end

# A curve is a set of coordinates and a configuration
Base.@kwdef mutable struct Curve
    x::Coord = Coord()
    y::Coord = Coord()
    z::Coord = Coord()
    F::FCuN = FinancialCoords()
    E::ECuN = ErrorCoords()
    conf::CurveConf = CurveConf()
end

# Storage for axes configuration
Base.@kwdef mutable struct AxesConf
    title::String      = config[:axes][:title]
    xlabel::String     = config[:axes][:xlabel]
    ylabel::String     = config[:axes][:ylabel]
    zlabel::String     = config[:axes][:zlabel]
    fillstyle::String  = config[:axes][:fillstyle]
    grid::String       = config[:axes][:grid]
    boxwidth::String   = config[:axes][:boxwidth]
    keyoptions::String = config[:axes][:keyoptions]
    axis::String       = config[:axes][:axis]
    xtics::String      = config[:axes][:xtics]
    ytics::String      = config[:axes][:ytics]
    ztics::String      = config[:axes][:ztics]
    xrange::String     = config[:axes][:xrange]
    yrange::String     = config[:axes][:yrange]
    zrange::String     = config[:axes][:zrange]
    xzeroaxis::String  = config[:axes][:xzeroaxis]
    yzeroaxis::String  = config[:axes][:yzeroaxis]
    zzeroaxis::String  = config[:axes][:zzeroaxis]
    view::String       = config[:axes][:view]
    palette::String    = config[:axes][:palette]
    linetypes::String  = config[:axes][:linetypes]
end

# At the top level, a figure is a handle, an axes configuration, and a
# set of curves.
const Handle = Union{Int,Nothing}  # handle type

Base.@kwdef mutable struct Figure
    handle::Handle                  # each figure has a unique handle
    datafile = tempname()           # file to store plot data
    term::TermConf   = TermConf()   # term options
    print::PrintConf = PrintConf()  # print optinos
    axes::AxesConf   = AxesConf()   # figure configuration
    curves::Union{Nothing,Vector{Curve}} = nothing # a vector of curves
    svg::String    = ""      # SVG data returned by gnuplot (used in IJulia)
    gpcom::String  = ""      # a gnuplot command to run before plotting
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
    figs::Vector{Figure}          # storage for all figures
end

GnuplotState() = GnuplotState(nothing,nothing,"","","",false,Figure[])

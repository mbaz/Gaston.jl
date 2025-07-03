## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

module Gaston

# Basic commands
export @Q_str#, @gpkw
export @plot, @plot!, @splot, @splot!
export plot, plot!, splot, splot!
export figure, closefigure, closeall

# Types
export Figure

# 2-D styled plots
export scatter,  stem,  bar,  barerror, histogram, imagesc
export scatter!, stem!, bar!, barerror!

# 3-D styled plots
export surf,  scatter3,  wireframe,  wiresurf, surfcontour, contour, heatmap
export surf!, scatter3!, wireframe!, wiresurf!

# Saving and animations
export save, animate

# New methods are added to these functions
import Base: show, showable, getindex, isempty, push!, setindex!, length

# Methods for recipes
using GastonRecipes
import GastonRecipes: PlotRecipe, AxisRecipe, FigureRecipe, AbstractFigure, DataBlock,
                      convert_args, convert_args3,
                      @gpkw, expand, prockey, procopts
export @gpkw

# Methods from other packages
#using MacroTools: postwalk, @capture

using Base: keys

using StatsBase: fit, Histogram, normalize

using DelimitedFiles: writedlm

using ColorSchemes: colorschemes, get, resample, ColorScheme, RGB, RGBA

using PrecompileTools

import Preferences
import Gnuplot_jll

const GASTON_VERSION = v"2.0.0"

# URL for web-hosted javascript files, for svg and canvas interactivity
const JSDIR = "'https://cdn.jsdelivr.net/gh/mbaz/gnuplot-js@1.0/'"

# load files
include("gaston_options.jl")
include("gaston_figures.jl")
include("gaston_aux.jl")
include("gaston_plot.jl")
include("gaston_builtinthemes.jl")
include("gaston_recipes.jl")
include("gaston_llplot.jl")

# Figure storage
struct FigureStore
    figs::Vector{Figure}
end

getindex(fs::FigureStore, args...) = getindex(fs.figs, args...)
length(fs::FigureStore) = length(fs.figs)

# State
Base.@kwdef mutable struct State
    figures   = FigureStore(Figure[])   # figure storage
    enabled   = false      # is gnuplot installed on this system?
    activefig = nothing    # handle of active figure
end
state = State()

getindex(s::State, args...) = getindex(s.figures, args...)
length(s::State) = length(s.figures)

activefig() = state.activefig

# Configuration
# embedhtml::Bool controls whether a figure is embedded in html when displayed in a notebook
# output::Symbol
#   :external -> display figures in separate gnuplot windows
#   :null ->  do not display anything
#   :echo -> display plot as text back to terminal (for notebooks, sixel and text)
# term::String -> terminal to use
# exec::Cmd -> gnuplot executable
Base.@kwdef mutable struct Config
    embedhtml :: Bool   = false
    output    :: Symbol = :external
    term      :: String = ""
    altterm   :: String = "gif animate loop 0"
    alttoggle :: Bool   = false
    exec      :: Union{Nothing,Cmd} = gnuplot_path()
end
config = Config()

# Determine if running in a notebook environment
function isnotebook()
    # Comment the following two lines, and uncomment the two below, to run JET tests
    if (isdefined(Main, :IJulia) && Main.IJulia.inited) ||
       (isdefined(Main, :Juno) && Main.Juno.isactive()) ||
#    if isdefined(Main, :IJulia) ||
#       isdefined(Main, :Juno) ||
       isdefined(Main, :VSCodeServer) ||
       isdefined(Main, :PlutoRunner)
       return true
    end
    return false
end

# initialize gnuplot
function __init__()
    global config, state

    if "JULIA_GNUPLOT_EXE" in keys(ENV)
        config.exec = ENV["JULIA_GNUPLOT_EXE"]
    end

    try
        success(`$(config.exec) --version`)
        state.enabled = true
    catch
        @warn "Gnuplot is not available on this system. Gaston will be unable to produce any plots."
    end

    # This configuration depends on run-time state
    config.output = isnotebook() ? :echo : :external
    config.term = isnotebook() ? "pngcairo" : ""

   return nothing
end

@compile_workload begin
    if state.enabled
        config.output = :null
        f = Figure()
        y = 1.1:0.5:10.6
        plot(y)
        plot!(y)
        plot(f[2], y)
        @plot({grid}, y, {w = "l", lc = Q"red"})
        f1 = (x,y) -> sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
        splot(f, (-5,5), f1)
        save(f, term = "png", filename = "test.png")
        rm("test.png")
        closeall()
        gp_quit(f)
    end
end

end

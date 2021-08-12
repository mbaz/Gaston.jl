## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

__precompile__(true)
module Gaston

export closefigure, closeall, figure,
       plot, plot!, scatter, scatter!, stem, bar, histogram, imagesc,
       surf, surf!, contour, scatter3, scatter3!, heatmap,
       Axes, save, set

import Base: display, show, isempty, push!, getindex, keys, merge,
             length, showable

using Random
using DelimitedFiles
using ColorSchemes

const GASTON_VERSION = v"1.0.4"

# load files
include("gaston_types.jl")
include("gaston_config.jl")
include("gaston_figures.jl")
include("gaston_aux.jl")
include("gaston_plot.jl")
include("gaston_recipes.jl")
include("gaston_llplot.jl")
include("gaston_save.jl")


# initialize internal state
gnuplot_state = GnuplotState()

mutable struct Pipes
    gstdin :: Pipe
    gstdout :: Pipe
    gstderr :: Pipe
    Pipes() = new()
end

const P = Pipes()
config = default_config()

function showable(mime::MIME"text/plain", f::Figure)
    if config[:term] in term_text
        return true
    end
    return false
end

function showable(mime::MIME"image/png", f::Figure)
    if config[:showable] == "" || occursin("png", config[:showable])
        return true
    end
    return false
end

function showable(mime::MIME"image/svg+xml", f::Figure)
    if config[:showable] == "" || occursin("svg", config[:showable])
        return true
    end
    return false
end

# initialize gnuplot
function __init__()
    global P, gnuplot_state
    try
        success(`gnuplot --version`)
        gnuplot_state.gnuplot_available = true
        gstdin = Pipe()
        gstdout = Pipe()
        gstderr = Pipe()
        gproc = run(pipeline(`gnuplot`,
                             stdin = gstdin, stdout = gstdout, stderr = gstderr),
                    wait = false)
        process_running(gproc) || error("There was a problem starting up gnuplot.")
        close(gstdout.in)
        close(gstderr.in)
        close(gstdin.out)
        Base.start_reading(gstderr.out)
        P.gstdin = gstdin
        P.gstdout = gstdout
        P.gstderr = gstderr
    catch
        @warn "Gnuplot is not available on this system. Gaston will be unable to produce any plots."
    end

    return nothing
end

end

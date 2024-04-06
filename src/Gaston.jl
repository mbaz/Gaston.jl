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
using PrecompileTools

const GASTON_VERSION = v"1.1.1"
GNUPLOT_VERSION = v"0"

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

function gp_start()
    global P
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
end

# initialize gnuplot
function __init__()
    global gnuplot_state
    ccall(:jl_generating_output, Cint, ()) == 1 && return

    gnuplot_state.gnuplot_available = false

    try
        code = success(`gnuplot --version`)
        if code
            gnuplot_state.gnuplot_available = true
            gp_start()
        else
            @warn ("There was a problem starting gnuplot. Gaston will be unable to produce any plots.")
        end
    catch
        @warn "Gnuplot is not available on this system. Gaston will be unable to produce any plots."
    end

    return nothing
end

@compile_workload begin
    gnuplot_state.gnuplot_available = false
    set(mode = "null")
    y = 1.1:0.5:10.6
    plot(y)
    plot!(y)
    f1 = (x,y) -> sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
    surf(0:0.1:1, 0:0.1:1, f1)
    closeall()
    gnuplot_send("exit gnuplot\n")
    set(reset = true)
end

end

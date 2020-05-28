## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

__precompile__(true)
module Gaston

export closefigure, closeall, figure,
       plot, plot!, scatter, scatter!, stem, bar, histogram, imagesc,
       surf, surf!, contour, scatter3, scatter3!, heatmap,
       Axis, save, set

import Base: display, show, isempty, push!, getindex, keys, merge, length

using Random
using DelimitedFiles
using ColorSchemes

const VERSION = v"1.0.0"

## Handle Unix/Windows differences
#
# Define gnuplot's end-of-plot delimiter. It is different in Windows
# than in Unix, thanks to different end-of-line conventions.
gmarker_start = "GastonBegin\n"
gmarker_done = "GastonDone\n"
if Sys.iswindows()
    gmarker_start = "GastonBegin\r\n"
    gmarker_done = "GastonDone\r\n"
end

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

# initialize gnuplot
function __init__()
    global P
    try
        success(`gnuplot --version`)
    catch
        error("Gaston cannot be loaded: gnuplot is not available on this system.")
    end
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

    global config = default_config()

    return nothing
end

end

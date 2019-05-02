## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

__precompile__(true)
module Gaston

export closefigure, closeall, figure,
       plot, plot!, histogram, imagesc, surf,
       printfigure, set

import Base.show

using Random
using DelimitedFiles

# before doing anything else, verify gnuplot is present on this system

# load files
include("gaston_types.jl")
include("gaston_aux.jl")
include("gaston_llplot.jl")
include("gaston_hilvl.jl")
include("gaston_config.jl")

# determine if running in an IJulia notebook
isjupyter = false
if isdefined(Main, :IJulia) && Main.IJulia.inited
    isjupyter = true
end

# initialize internal state
gnuplot_state = GnuplotState()

# initialize default configuration
gaston_config = GastonConfig()

mutable struct Pipes
    gstdin :: Pipe
    gstdout :: Pipe
    gstderr :: Pipe
    Pipes() = new()
end

const P = Pipes()

# initialize gnuplot
function __init__()
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
    P.gstdin = gstdin
    P.gstdout = gstdout
    P.gstderr = gstderr
    return nothing
end

# load initialization file
#include("gaston_init.jl")

end

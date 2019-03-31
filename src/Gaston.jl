## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

__precompile__(false)
module Gaston

export closefigure, closeall, figure,
       plot, plot!, histogram, imagesc, surf,
       printfigure, set

import Base.show

using Random
using DelimitedFiles

# before doing anything else, verify gnuplot is present on this system
try
  success(`gnuplot --version`)
catch
  error("Gaston cannot be loaded: gnuplot is not available on this system.")
end

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

# when gnuplot_state goes out of scope, exit gnuplot
finalizer(gnuplot_exit, gnuplot_state)

# initialize default configuration
gaston_config = GastonConfig()

# load initialization file
include("gaston_init.jl")

end

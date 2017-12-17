## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

module Gaston

export closefigure, closeall, clearfigure, figure, plot, histogram, imagesc,
surf, printfigure, gaston_demo, set, gnuplot_send, addconf, addcoords,
adderror, addfinancial, CurveConf, AxesConf, llplot, meshgrid, gnuplot_exit

import Base.show

# before doing anything else, verify gnuplot is present on this system
if !success(`gnuplot --version`)
    error("Gaston cannot be loaded: gnuplot is not available on this system.")
end

# load files
include("gaston_types.jl")
include("gaston_aux.jl")
include("gaston_lowlvl.jl")
include("gaston_midlvl.jl")
include("gaston_hilvl.jl")
include("gaston_config.jl")
include("gaston_demo.jl")

# set up global variables
# global variable that stores gnuplot's state
gnuplot_state = GnuplotState(false,0,0,"","","",false,Any[])

# when gnuplot_state goes out of scope, close the pipe
finalizer(gnuplot_state,gnuplot_exit)

# global variable that stores Gaston's configuration
gaston_config = GastonConfig()

gnuplot_init()

end

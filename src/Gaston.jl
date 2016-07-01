## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

module Gaston

export closefigure, closeall, clearfigure, figure, plot, histogram, imagesc,
surf, printfigure, gaston_demo, set_terminal, set_filename, set_default_legend,
set_default_plotstyle, set_default_color, set_default_marker,
set_default_linewidth, set_default_pointsize, set_default_title,
set_default_xlabel, set_default_ylabel, set_default_zlabel, set_default_fill,
set_default_grid, set_default_box, set_default_axis, set_default_xrange,
set_default_yrange, set_default_zrange, set_print_color, set_print_fontface,
set_print_fontsize, set_print_fontscale, set_print_linewidth, set_print_size,
gnuplot_send, addconf, addcoords, adderror, addfinancial, CurveConf, AxesConf,
llplot, meshgrid, gnuplot_exit

import Base.writemime

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
gnuplot_state = GnuplotState(false,0,0,mktempdir(),"","","",false,Any[])

# when gnuplot_state goes out of scope, close the pipe
finalizer(gnuplot_state,gnuplot_exit)

# global variable that stores Gaston's configuration
gaston_config = GastonConfig()

end

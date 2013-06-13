## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

module Gaston

export closefigure, closeall, clearfigure, figure, plot, histogram, imagesc,
    surf, printfigure, gaston_demo, gaston_tests, set_terminal, set_filename,
    set_default_legend, set_default_plotstyle, set_default_color,
    set_default_marker, set_default_linewidth, set_default_pointsize,
    set_default_title, set_default_xlabel, set_default_ylabel,
    set_default_zlabel, set_default_box, set_default_axis, set_default_xrange,
    set_default_yrange, set_default_zrange, set_print_color, set_print_fontface,
    set_print_fontsize, set_print_fontscale, set_print_linewidth, set_print_size,
    gnuplot_send

# before doing anything else, verify gnuplot is present on this system
if !success(`gnuplot --version`)
    error("Gaston cannot be loaded: gnuplot is not available on this system.")
end
if readchomp(`gnuplot --version`)[1:11] != "gnuplot 4.6"
    println("Warning: Gaston has only been tested on gnuplot version 4.6")
end

# load files
include("gaston_types.jl")
include("gaston_aux.jl")
include("gaston_lowlvl.jl")
include("gaston_midlvl.jl")
include("gaston_hilvl.jl")
include("gaston_config.jl")
include("gaston_demo.jl")
include("gaston_test.jl")

# set up global variables
# global variable that stores gnuplot's state
gnuplot_state = None
try
    # linux
    gnuplot_state = GnuplotState(false,0,0,string("/tmp/gaston-",ENV["USER"],
    "-",randstring(5),"/"),[])
catch
    # windows
    gnuplot_state = GnuplotState(false,0,0,string(replace(ENV["TMP"],"\\","/"),
    "/gaston-",ENV["USERNAME"],"-",randstring(5)),[])
end

# when gnuplot_state goes out of scope, close the pipe
finalizer(gnuplot_state,gnuplot_exit)

# global variable that stores Gaston's configuration
gaston_config = GastonConfig()

end

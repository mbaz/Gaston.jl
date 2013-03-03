## Copyright (c) 2012 Miguel Bazdresch
##
## Permission is hereby granted, free of charge, to any person obtaining a
## copy of this software and associated documentation files (the "Software"),
## to deal in the Software without restriction, including without limitation
## the rights to use, copy, modify, merge, publish, distribute, sublicense,
## and/or sell copies of the Software, and to permit persons to whom the
## Software is furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
## DEALINGS IN THE SOFTWARE.

module Gaston

export closefigure, closeall, clearfigure, figure, plot, histogram, imagesc,
    surf, printfigure, gaston_demo, gaston_tests

# before doing anything else, verify gnuplot is present on this system
if !success(`which gnuplot`)
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
gnuplot_state = GnuplotState(false,0,0,string("/tmp/gaston-",ENV["USER"],
"-",randstring(5),"/"),[])
# when gnuplot_state goes out of scope, close the pipe
finalizer(gnuplot_state,gnuplot_exit)

# global variable that stores Gaston's configuration
gaston_config = GastonConfig()

end

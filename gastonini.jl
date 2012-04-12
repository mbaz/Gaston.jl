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

# We need a global variable to keep track of gnuplot's state
type GnuplotState
    running::Bool               # true when gnuplot is already running
    current::Int                # current figure
    fid                         # pipe stream id
    tmpdir::ASCIIString         # where to store data files

    function GnuplotState(running::Bool,current::Int,fid,tmpdir::ASCIIString)
        # Check to see if tmpdir exists, and create it if not
        try
            f = open(tmpdir)
            close(f)
        catch
            system(strcat("mkdir ",tmpdir))
        end
        new(running,current,fid,tmpdir)
    end
end

# return a random string (for filenames)
function randstring(len::Int)
    const cset = char([0x30:0x39,0x41:0x5a,0x61:0x7a])
    const strset = convert(ASCIIString,strcat(cset...))
    index = int(ceil(strlen(strset)*rand(len)))
    s = strset[index]
    return s
end

# global variable that stores gnuplot's state
gnuplot_state = GnuplotState(false,0,0,strcat("/tmp/gaston-",getenv("USER"),"-",randstring(5),"/"))

# Structs to configure a plot
# Two types of configuration are needed: one to configure a single curve, and
# another to configure a set of curves (the 'axes').
type CurveConf
    legend::ASCIIString     # legend text
    plotstyle::ASCIIString  # one of lines, linespoints, points, impulses,
                            # errorbars, errorlines, pm3d, boxes
    color::ASCIIString      # one of gnuplot's builtin colors
                            # run 'show colornames' inside gnuplot
    marker::ASCIIString     # +, x, *, esquare, fsquare, ecircle, fcircle,
                            # etrianup, ftrianup, etriandn, ftriandn,
                            # edmd, fdmd
    linewidth               # a number
    pointsize               # a number
end
CurveConf() = CurveConf("","lines","","",1,0.5)

# dereference CurveConf, by adding a method to copy()
function copy(conf::CurveConf)
    new = CurveConf()
    new.legend = conf.legend
    new.plotstyle = conf.plotstyle
    new.color = conf.color
    new.marker = conf.marker
    new.linewidth = conf.linewidth
    new.pointsize = conf.pointsize
    return new
end

type Axes_conf
    title::ASCIIString      # plot title
    xlabel::ASCIIString     # xlabel
    ylabel::ASCIIString     # ylabel
    zlabel::ASCIIString     # zlabel for 3-d plots
    box::ASCIIString        # legend box (used with 'set key')
    axis::ASCIIString       # normal, semilog{x,y}, loglog
end
Axes_conf() = Axes_conf("Untitled","x","y","z","inside vertical right top","")

# dereference Axes_conf
function copy(conf::Axes_conf)
    new = Axes_conf()
    new.title = conf.title
    new.xlabel = conf.xlabel
    new.ylabel = conf.ylabel
    new.zlabel = conf.zlabel
    new.box = conf.box
    new.axis = conf.axis
    return new
end

# coordinates and configuration for a single curve
type Curve_data
    x
    y
    Z          # for 3-D plots. Element i,j is z-value for x[j], y[i]
    ylow
    yhigh
    conf::CurveConf
end
Curve_data() = Curve_data([],[],[],[],[],CurveConf())
Curve_data(x,y,Z,conf::CurveConf) = Curve_data(x,y,Z,[],[],conf)

# curves and configuration for a single figure
type Figure
    handle::Int                  # each figure has a unique handle
    curves::Vector{Curve_data}   # a vector of curves (x,y,conf)
    conf::Axes_conf              # figure configuration
end
Figure(handle) = Figure(handle,[Curve_data()],Axes_conf())

# curves and configuration for all figures
figs = Vector{Figure}

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
    tmpdir::String              # where to store data files

    function GnuplotState(running::Bool,current::Int,fid,tmpdir::String)
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
    const strset = convert(String,strcat(cset...))
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
    legend::String          # legend text
    plotstyle::String
    color::String           # one of gnuplot's builtin colors --
                            # run 'show colornames' inside gnuplot
    marker::String          # point type
    linewidth::Real
    pointsize::Real

    function CurveConf(leg,pstyle,col,mark,lw,ps)
        # check valid values of plotstyle
        validps=["lines", "linespoints", "points", "impulses", "errorbars",
        "errorlines", "pm3d", "boxes"]
        assert(contains(validps,pstyle),"Invalid plotstyle specified")

        # TODO: figure out how to check valid color names -- gnuplot supports
        #  112 different color names.

        # check valid values of marker
        validmks = ["", "+", "x", "*", "esquare", "fsquare", "ecircle",
        "fcircle", "etrianup", "ftrianup", "etriandn", "ftriandn", "edmd",
        "fdmd"]
        assert(contains(validmks,mark), "Invalid mark name specified")

        new(leg,pstyle,col,mark,lw,ps)
    end
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

type AxesConf
    title::String      # plot title
    xlabel::String     # xlabel
    ylabel::String     # ylabel
    zlabel::String     # zlabel for 3-d plots
    box::String        # legend box (used with 'set key')
    axis::String       # normal, semilog{x,y}, loglog
end
AxesConf() = AxesConf("Untitled","x","y","z","inside vertical right top","")

# dereference AxesConf
function copy(conf::AxesConf)
    new = AxesConf()
    new.title = conf.title
    new.xlabel = conf.xlabel
    new.ylabel = conf.ylabel
    new.zlabel = conf.zlabel
    new.box = conf.box
    new.axis = conf.axis
    return new
end

# coordinates and configuration for a single curve
type CurveData
    x::Vector          # abscissa
    y::Vector          # ordinate
    Z::Array           # 3-d plots and images
    ylow::Vector       # error data
    yhigh::Vector      # error data
    conf::CurveConf    # curve configuration
end
CurveData() = CurveData([],[],[],[],[],CurveConf())
CurveData(x,y,Z,conf::CurveConf) = CurveData(x,y,Z,[],[],conf)

# curves and configuration for a single figure
type Figure
    handle::Int                  # each figure has a unique handle
    curves::Vector{CurveData}   # a vector of curves (x,y,conf)
    conf::AxesConf               # figure configuration
end
Figure(handle) = Figure(handle,[CurveData()],AxesConf())

# curves and configuration for all figures
figs = []

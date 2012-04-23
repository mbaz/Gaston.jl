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

## This file contains "high-level" plotting functions, similar to Octave's.

# 2-d plots
function plot(args...)
    # if args[1] is an integer, it's the function handle.
    if isa(args[1], Int)
        h = args[1]
        args = args[2:end]   # argument parsing starts with 1 (eases debug)
    else
        h = gnuplot_state.current
    end
    if h == 0
        h = figure()     # new figure
    else
        closefigure(h)
        figure(h)    # overwrite specific figure
    end
    # parse arguments
    state = "SINI"
    la = length(args)
    while(true)
        if state == "SINI"
            i = 1
            cc = CurveConf()
            ac = AxesConf()
            state = "S1"
        elseif state == "S1"
            if i > la
                state = "SERROR"
                continue
            end
            y = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                addcoords(y,cc)
                state = "SEND"
                continue
            end
            if isa(args[i], String)
                x = 1:length(y)
                state = "S4"
            else
                x = y
                y = args[i]
                i = i+1
                state = "S3"
            end
        elseif state == "S3"
            if i > la
                addcoords(x,y,cc)
                state = "SEND"
                continue
            end
            if isa(args[i], String)
                state = "S4"
            else
                addcoords(x,y,cc)
                cc = CurveConf()
                y = args[i]
                i = i+1
                state = "S2"
            end
        elseif state == "S4"
            if i+1 > la
                state = "SERROR"
                continue
            end
            ai = args[i]; ai1 = args[i+1]
            if ai == "legend"
                cc.legend = ai1
            elseif ai == "plotstyle"
                assert(contains(["lines", "linespoints", "points",
                    "impulses","boxes"],ai1),"Invalid plot style")
                cc.plotstyle = ai1
            elseif ai == "color"
                cc.color = ai1
            elseif ai == "marker"
                cc.marker = ai1
            elseif ai == "linewidth"
                cc.linewidth = ai1
            elseif ai == "pointsize"
                cc.pointsize = ai1
            elseif ai == "title"
                ac.title = ai1
            elseif ai == "xlabel"
                ac.xlabel = ai1
            elseif ai == "ylabel"
                ac.ylabel = ai1
            elseif ai == "box"
                ac.box = ai1
            elseif ai == "axis"
                ac.axis = ai1
            else
                error("Invalid property specified")
            end
            i = i+2
            state = "S3"
        elseif state == "SEND"
            addconf(ac)
            llplot()
            break
        elseif state == "SERROR"
            error("Invalid arguments")
        else
            error("Unforseen situation, bailing out")
        end
    end
    return h
end

function histogram(args...)
    # if args[1] is an integer, it's the function handle.
    if isa(args[1], Int)
        h = args[1]
        args = args[2:end]   # argument parsing starts with 1 (eases debug)
    else
        h = gnuplot_state.current
    end
    if h == 0
        h = figure()     # new figure
    else
        closefigure(h)
        figure(h)    # overwrite specific figure
    end
    # parse arguments
    state = "SINI"
    la = length(args)
    while(true)
        if state == "SINI"
            i = 1
            bins::Int = 10
            norm::Int = 0
            cc = CurveConf()
            cc.plotstyle = "boxes"
            ac = AxesConf()
            state = "S1"
        elseif state == "S1"
            if i > la
                state = "SERROR"
                continue
            end
            y = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                # validate bins and norm
                if bins <= 0 || norm < 0
                    state = "SERROR"
                    continue
                end
                (x,y) = histdata(y,bins)
                if norm != 0
                    delta = x[2] - x[1]
                    y = norm*y/(delta*sum(y))
                end
                addcoords(x,y,cc)
                state = "SEND"
                continue
            end
            state = "S3"
        elseif state == "S3"
            if i+1 > la
                state = "SERROR"
                continue
            end
            ai = args[i]; ai1 = args[i+1]
            if ai == "legend"
                cc.legend = ai1
            elseif ai == "color"
                cc.color = ai1
            elseif ai == "linewidth"
                cc.linewidth = ai1
            elseif ai == "bins"
                bins = ai1
            elseif ai == "norm"
                norm = ai1
            elseif ai == "title"
                ac.title = ai1
            elseif ai == "xlabel"
                ac.xlabel = ai1
            elseif ai == "ylabel"
                ac.ylabel = ai1
            elseif ai == "box"
                ac.box = ai1
            else
                error("Invalid property specified")
            end
            i = i+2
            state = "S2"
        elseif state == "SEND"
            addconf(ac)
            llplot()
            break
        elseif state == "SERROR"
            error("Invalid arguments")
        else
            error("Unforseen situation, bailing out")
        end
    end
    return h
end

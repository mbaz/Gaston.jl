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

load("gastonini.jl")
load("gastonaux.jl")

# Close a figure, or current figure.
# Returns the handle of the figure that was closed.
function closefigure(x...)
    global gnuplot_state
    global figs
    # create vector of handles
    handles = []
    if gnuplot_state.current != 0
        for i in figs
            handles = [handles, i.handle]
        end
    end
    if isempty(x)
        # close current figure
        h = gnuplot_state.current
    else
        h = x[1]
    end
    if contains(handles,h)
        if gnuplot_state.running
            gnuplot_send(strcat("set term wxt ", string(h), " close"))
        end
        # delete all data related to this figure
        _figs = []
        for i in figs
            if i.handle != h
                _figs = [_figs, i]
            end
        end
        figs = _figs
        # update state
        if isempty(figs)
            # we just closed the last figure
            gnuplot_state.current = 0
        else
            # select the most-recently created figure
            gnuplot_state.current = figs[end].handle
        end
    else
        println("No such figure exists");
        h = 0
    end
    return h
end

# close all figures
function closeall()
    try
        for i in figs
            closefigure()
        end
    catch
    end
end

# Select or create a figure. When called with no arguments, create a new
# figure. Figure handles must be integers.
# Returns the current figure handle.
function figure(x...)
    global gnuplot_state
    global figs
    # see if we need to set up gnuplot
    if gnuplot_state.running == false
        gnuplot_init();
    end
    # create vector of handles
    handles = []
    if gnuplot_state.current != 0
        for i in figs
            handles = [handles, i.handle]
        end
    end
    # determine handle and update
    if gnuplot_state.current == 0
        # this is the first figure
        h = x[1]
        figs = [Figure(h)]
        gnuplot_state.current = h
        gnuplot_send(strcat("set term wxt ", string(h)))
    else
        if isempty(x)
            # create a new figure, using lowest numbered handle available
            for i = 1:max(handles)+1
                if !contains(handles,i)
                    h = i
                    break
                end
            end
        else
            h = x[1];
        end
        gnuplot_state.current = h
        gnuplot_send(strcat("set term wxt ", string(h)))
        if !contains(handles,h)
            # this is a new figure
            figs = [figs, Figure(h)]
        else
            # figure already exists, replot
            plot()
        end
    end
    return h
end

# Return index to figure with handle 'c'. If no such figure exists, returns 0.
function findfigure(c)
    i = 0
    for j = 1:length(figs)
        if figs[j].handle == c
            i = j
            break
        end
    end
    return i
end

# append x,y,z coordinates and configuration to current figure
function addcoords(x,y,Z,conf::Curve_conf)
    global figs
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end
    # copy conf (dereference)
    conf = copy(conf)
    # append data to figure
    c = findfigure(gnuplot_state.current)
    if isempty(figs[c].curves[1].x)
        # figure() creates a structure with one empty curve; we want to
        # overwrite it with the first actual curve
        figs[c].curves[1] = Curve_data(x,y,Z,conf)
    else
        figs[c].curves = [figs[c].curves, Curve_data(x,y,Z,conf)]
    end
end
addcoords(y) = addcoords(1:length(y),y,[],Curve_conf())
addcoords(y,c::Curve_conf) = addcoords(1:length(y),y,[],c)
addcoords(x,y) = addcoords(x,y,[],Curve_conf())
addcoords(x,y,Z) = addcoords(x,y,Z,Curve_conf())
addcoords(x,y,c::Curve_conf) = addcoords(x,y,[],c)
# X, Y data in matrix columns
function addcoords(X::Matrix,Y::Matrix,conf::Curve_conf)
    for i = 1:size(X,2)
        addcoords(X[:,i],Y[:,i],[],conf)
    end
end
function addcoords(X::Matrix,conf::Curve_conf)
    y = 1:size(X,1)
    Y = zeros(size(X))
    for i = 1:size(X,2)
        Y[:,i] = y
    end
    addcoords(X,Y,conf)
end
addcoords(X::Matrix, Y::Matrix) = addcoords(X,Y,Curve_conf())
addcoords(X::Matrix) = addcoords(X,Curve_conf())

# append error data to current set of coordinates
function adderror(yl,yh)
    global figs
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end
    # set fields in current curve
    c = findfigure(gnuplot_state.current)
    figs[c].curves[end].ylow = yl
    figs[c].curves[end].yhigh = yh
end
adderror(ydelta) = adderror(ydelta,[])

# add axes configuration to current figure
function addconf(conf::Axes_conf)
    global figs
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end
    conf = copy(conf)
    # select current plot
    c = findfigure(gnuplot_state.current)
    figs[c].conf = conf
end

# 'plot' is our workhorse plotting function
function plot()
    # select current plot
    c = findfigure(gnuplot_state.current)
    if c == 0
        println("No current figure")
        return
    end
    config = figs[c].conf
    gnuplot_send(strcat("set term wxt ",string(c)))
    gnuplot_send("set autoscale")
    # legend box
    if config.box != ""
        gnuplot_send(strcat("set key ",config.box))
    end
    # plot title
    if config.title != ""
        gnuplot_send(strcat("set title '",config.title,"' "))
    end
    # xlabel
    if config.xlabel != ""
        gnuplot_send(strcat("set xlabel '",config.xlabel,"' "))
    end
    # ylabel
    if config.ylabel != ""
        gnuplot_send(strcat("set ylabel '",config.ylabel,"' "))
    end
    # zlabel
    if config.zlabel != ""
        gnuplot_send(strcat("set zlabel '",config.zlabel,"' "))
    end
    # axis log scale
    if config.axis != "" || config.axis != "normal"
        if config.axis == "semilogx"
            gnuplot_send("set logscale x")
        end
        if config.axis == "semilogy"
            gnuplot_send("set logscale y")
        end
        if config.axis == "loglog"
            gnuplot_send("set logscale xy")
        end
    end
    # datafile filename
    filename = strcat(string(gnuplot_state.tmpdir),"figure",string(c),".dat")
    # send coordinates, checking each special case
    # first check whether we are doing 2-d, 3-d or image plots
    # 2-d plot: x is not empty, Z is empty
    if isempty(figs[c].curves[1].Z) && !isempty(figs[c].curves[1].x)
        # create data file
        f = open(filename,"w")
        for i in figs[c].curves
            tmp = i.conf.plotstyle
            if tmp == "errorbars" || tmp == "errorlines"
                if isempty(i.yhigh)
                    # ydelta (single error coordinate)
                    dlmwrite(f,[i.x i.y i.ylow],' ')
                else
                    # ylow, yhigh (double error coordinate)
                    dlmwrite(f,[i.x i.y i.ylow i.yhigh],' ')
                end
            else
                dlmwrite(f,[i.x i.y],' ')
            end
            write(f,"\n\n")
        end
        close(f)
        # send command to gnuplot
        gnuplot_send(linestr(figs[c].curves, "plot", filename,""))
    # 3-d plot: x is not empty, Z is not empty
    elseif !isempty(figs[c].curves[1].Z) && !isempty(figs[c].curves[1].x)
        # create data file
        f = open(filename,"w")
        for i in figs[c].curves
            # nonuniform matrix -- see gnuplot 4.6 manual, p. 169
            write(f,"0 ")
            dlmwrite(f,[i.x]',' ');
            for y = 1:length(i.y)
                dlmwrite(f,[i.y[y] i.Z[:,y]'],' ')
            end
            write(f,"\n\n")
        end
        close(f)
        # send command to gnuplot
        gnuplot_send(linestr(figs[c].curves, "splot",filename,"nonuniform matrix"))
    # image plot: plotstyle is "image" or "rgbimage"
    elseif figs[c].curves[1].conf.plotstyle == "image" || figs[c].curves[1].conf.plotstyle == "rgbimage"
        # create data file
        f = open(filename,"w")
        # assume there is only one image per figure
        if figs[c].curves[1].conf.plotstyle == "image"
            # output matrix
            dlmwrite(f,figs[c].curves[1].Z,' ')
            close(f)
            # send command to gnuplot
            gnuplot_send("set yrange [*:*] reverse")  # flip y axis
            gnuplot_send(linestr(figs[c].curves,"plot",filename,"matrix"))
        end
        if figs[c].curves[1].conf.plotstyle == "rgbimage"
            # output matrix
            Z = figs[c].curves[1].Z
            y = 1.0:size(Z,2)
            for i = 1:size(Z,1)
                c1 = i*ones(length(y))
                r = slicedim(Z,3,1)[i,:]
                g = slicedim(Z,3,2)[i,:]
                b = slicedim(Z,3,3)[i,:]
                dlmwrite(f,hcat(c1,y,r',g',b'),' ')
            end
            close(f)
            # send command to gnuplot
            gnuplot_send("set yrange [*:*] reverse")  # flip y axis
            gnuplot_send(linestr(figs[c].curves,"plot",filename,""))
        end
    end
    gnuplot_send("reset")
end

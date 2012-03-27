# Plotting with gnuplot in Julia
# Miguel Bazdresch
# Warning: extremely preliminary version: no warranties!

load("inifile.jl")
load("auxfile.jl")

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
        h = 1
        figs = [Figure(h)]
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
        if !contains(handles,h)
            # this is a new figure
            figs = [figs, Figure(h)]
        end
    end
    gnuplot_state.current = h
end

# add a curve to current figure
function addcurve(x,y,conf::Curve_conf)
    global figs
    # copy conf (dereference)
    conf = copy_curve_conf(conf)
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end
    # append curve to figure
    c = gnuplot_state.current
    if isempty(figs[c].curves[1].x)
        # figure() creates a structure with one empty curve; we want to
        # overwrite it with the first actual curve
        figs[c].curves[1] = Curve_data(x,y,conf)
    else
        figs[c].curves = [figs[c].curves, Curve_data(x,y,conf)]
    end
end
addcurve(y) = addcurve(1:length(y),y,Curve_conf())
addcurve(y,c::Curve_conf) = addcurve(1:length(y),y,c)
addcurve(x,y) = addcurve(x,y,Curve_conf())

# add axes configuration to current figure
function addconf(conf::Axes_conf)
    global figs
    conf = copy_axes_conf(conf)
    # see if we need to set up gnuplot
    if gnuplot_state.running == false
        gnuplot_init();
    end
    # select current plot
    c = gnuplot_state.current
    figs[c].conf = conf
end

# 'plot' is our workhorse plotting function
function plot()
    # see if we need to set up gnuplot
    if gnuplot_state.running == false
        gnuplot_init();
    end
    # select current plot
    c = gnuplot_state.current
    config = figs[c].conf
    gnuplot_send(strcat("set term wxt ",string(c)))
    gnuplot_send("set autoscale")
    # legend box
    gnuplot_send("unset key")
    if config.box != ""
        gnuplot_send(strcat("set key ",config.box))
    end
    # plot title
    gnuplot_send("unset title")
    if config.title != ""
        gnuplot_send(strcat("set title '",config.title,"' "))
    end
    # xlabel
    gnuplot_send("unset xlabel")
    if config.xlabel != ""
        gnuplot_send(strcat("set xlabel '",config.xlabel,"' "))
    end
    # ylabel
    gnuplot_send("unset ylabel")
    if config.ylabel != ""
        gnuplot_send(strcat("set ylabel '",config.ylabel,"' "))
    end
    # axis log scale
    gnuplot_send("unset logscale")
    if config.axis != "" || config.axis != "normal"
        if config.axis == "semilogx"
            gnuplot_send("set logscale x")
        end
        if config.axis == "semilogy"
            gnuplot_send("set logscale y")
            println("yo")
        end
        if config.axis == "loglog"
            gnuplot_send("set logscale xy")
        end
    end
    # coordinates
    gnuplot_send(linestr(figs[c].curves))
    for i in figs[c].curves
        for j = 1:length(i.x)
            gnuplot_send(strcat(string(i.x[j])," ",string(i.y[j])))
        end
        gnuplot_send("e")
    end
end

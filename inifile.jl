# Plotting with gnuplot in Julia
# Miguel Bazdresch
# Warning: extremely preliminary version: no warranties!

# We need a global variable to keep track of gnuplot's state
type Gnuplot_state
    running::Bool               # true when gnuplot is already running
    current::Int                # current figure
    fid                         # pipe stream id
end

gnuplot_state = Gnuplot_state(false,0,0)

# Structs to configure a plot
# Two types of configuration are needed: one to configure a single curve, and
# another to configure a set of curves (the 'axes').
type Curve_conf
    legend::ASCIIString     # legend text
    plotstyle::ASCIIString  # one of lines, linespoints, points, impulses,
                            # errorbars or errorlines
    color::ASCIIString      # one of gnuplot's builtin colors
                            # run 'show colornames' inside gnuplot
    marker::ASCIIString     # +, x, *, esquare, fsquare, ecircle, fcircle,
                            # etrianup, ftrianup, etriandn, ftriandn,
                            # edmd, fdmd
    linewidth               # a number
    pointsize               # a number
end
Curve_conf() = Curve_conf("","lines","","",1,0.5)

# dereference Curve_conf
function copy_curve_conf(conf::Curve_conf)
    new = Curve_conf()
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
    box::ASCIIString        # legend box (used with 'set key')
    axis::ASCIIString       # normal, semilog{x,y}, loglog
end
Axes_conf() = Axes_conf("Untitled","x","y","inside vertical right top","")

# dereference Axes_conf
function copy_axes_conf(conf::Axes_conf)
    new = Axes_conf()
    new.title = conf.title
    new.xlabel = conf.xlabel
    new.ylabel = conf.ylabel
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
    conf::Curve_conf
end
Curve_data() = Curve_data([],[],[],[],[],Curve_conf())
Curve_data(x,y,Z,conf::Curve_conf) = Curve_data(x,y,Z,[],[],conf)

# curves and configuration for a single figure
type Figure
    handle::Int                  # each figure has a unique handle
    curves::Vector{Curve_data}   # a vector of curves (x,y,conf)
    conf::Axes_conf              # figure configuration
end
Figure(handle) = Figure(handle,[Curve_data()],Axes_conf())

# curves and configuration for all figures
figs = Vector{Figure}

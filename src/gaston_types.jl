## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# types and constructors

# We need a global variable to keep track of gnuplot's state
type GnuplotState
    running::Bool               # true when gnuplot is already running
    current::Int                # current figure
    fid                         # pipe stream id
    tmpdir::String              # where to store data files
    figs::Array                 # storage for all figures

    function GnuplotState(running::Bool,current::Int,fid,tmpdir::String,
        figs::Array)
        # Check to see if tmpdir exists, and create it if not
        # TODO: there has to be a simpler way to do this
        try
            f = open(tmpdir)
            close(f)
        catch
            run(`mkdir $tmpdir`)
        end
        new(running,current,fid,tmpdir,figs)
    end
end

# Structure to keep Gaston's configuration
type GastonConfig
    # default CurveConf values
    legend::String
    plotstyle::String
    color::String
    marker::String
    linewidth::Real
    pointsize::Real
    # default AxesConf values
    title::String
    xlabel::String
    ylabel::String
    zlabel::String
    box::String
    axis::String
    # default grid type
    grid::String
    # default terminal type
    terminal::String
    # for terminals that support filenames
    outputfile::String
    # for printing to file
    print_color::String
    print_fontface::String
    print_fontsize::Real
    print_fontscale::Real
    print_linewidth::Real
    print_size::String
end
GastonConfig() = GastonConfig(
    # CurveConf
    "","lines","","",1,0.5,
    # AxesConf
    "Untitled","x","y","z","inside vertical right top","",
    # grid
    "off",
    # terminal
    "wxt",
    # output file name
    "",
    # print parameters
    "color", "Sans", 12, 0.5, 1, "5in,3in"
    )

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

end
CurveConf() = CurveConf(
    gaston_config.legend,
    gaston_config.plotstyle,
    gaston_config.color,
    gaston_config.marker,
    gaston_config.linewidth,
    gaston_config.pointsize)

type AxesConf
    title::String      # plot title
    xlabel::String     # xlabel
    ylabel::String     # ylabel
    zlabel::String     # zlabel for 3-d plots
    box::String        # legend box (used with 'set key')
    axis::String       # normal, semilog{x,y}, loglog
end
AxesConf() = AxesConf(
    gaston_config.title,
    gaston_config.xlabel,
    gaston_config.ylabel,
    gaston_config.zlabel,
    gaston_config.box,
    gaston_config.axis)

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
    curves::Vector{CurveData}    # a vector of curves (x,y,conf)
    conf::AxesConf               # figure configuration
    isempty::Bool                # a flag to indicate if figure is empty
end
Figure(handle) = Figure(handle,[CurveData()],AxesConf(),true)

# coordinate type
Coord = Union(Range1,Range,Matrix,Vector)

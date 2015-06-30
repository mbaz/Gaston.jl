## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# types and constructors

if VERSION < v"0.3-"
    typealias UnitRange{T} Range1{T}
end

# We need a global variable to keep track of gnuplot's state
type GnuplotState
    running::Bool               # true when gnuplot is already running
    current::Int                # current figure
    fid                         # pipe streams id
    tmpdir::String              # where to store data files
    figs::Array                 # storage for all figures

    function GnuplotState(running::Bool,current::Int,fid,tmpdir::String,
        figs::Array)
        # Check to see if tmpdir exists, and create it if not
        # TODO: there has to be a simpler way to do this
        mkd = true
        try
            readdir(tmpdir)
            mkd = false
        catch
        end
        if mkd
            # Linux
            try
                mkdir(tmpdir)
                mkd = false
            catch
            end
        end
        if mkd
            # Windows
            # TODO: there has to be a simpler way to do this
            ttdir = ""
            for x in split(tmpdir,'/')
                if x != ""
                    try
                        mkdir(string(ttdir,x))
                    catch
                    end
                    ttdir = string(ttdir, x, '\\')
                end
            end
            mkd = false
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
    xrange::String
    yrange::String
    zrange::String
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
function GastonConfig()
	# Determine if current display supports PNG, and set defaults
	# accordingly. This allows IJulia support.

	if displayable("image/png")
		GastonConfig(
    	# CurveConf
	    "","lines","","",1,0.5,
    	# AxesConf
	    "Untitled","x","y","z","inside vertical right top","","[*:*]","[*:*]","[*:*]",
    	# terminal
	    "png",
    	# output file name
	    "$(gnuplot_state.tmpdir)gaston-ijulia.png",
	    # print parameters
	    "color", "Sans", 10, 1, 1, "640,480"
    	)
	else
		GastonConfig(
    	# CurveConf
	    "","lines","","",1,0.5,
    	# AxesConf
	    "Untitled","x","y","z","inside vertical right top","","[*:*]","[*:*]","[*:*]",
    	# terminal
	    "wxt",
    	# output file name
	    "",
	    # print parameters
	    "color", "Sans", 12, 0.5, 1, "640,480"
	    )
	end
end

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
    xrange::String     # xrange
    yrange::String     # yrange
    zrange::String     # zrange
end
AxesConf() = AxesConf(
    gaston_config.title,
    gaston_config.xlabel,
    gaston_config.ylabel,
    gaston_config.zlabel,
    gaston_config.box,
    gaston_config.axis,
    gaston_config.xrange,
    gaston_config.yrange,
    gaston_config.zrange)

type Financial
    open::Vector
    low::Vector
    high::Vector
    close::Vector
end
Financial() = Financial(Any[],Any[],Any[],Any[])

# coordinates and configuration for a single curve
type CurveData
    x::Vector          # abscissa
    y::Vector          # ordinate
    Z::Array           # 3-d plots and images
    ylow::Vector       # error data
    yhigh::Vector      # error data
    finance::Financial # financial data
    conf::CurveConf    # curve configuration
end
CurveData() = CurveData(Any[],Any[],Any[],Any[],Any[],Financial(),CurveConf())
CurveData(x,y,Z,conf::CurveConf) = CurveData(x,y,Z,Any[],Any[],Financial(),conf)

# curves and configuration for a single figure
type Figure
    handle::Int                  # each figure has a unique handle
    curves::Vector{CurveData}    # a vector of curves (x,y,conf)
    conf::AxesConf               # figure configuration
    isempty::Bool                # a flag to indicate if figure is empty
end
Figure(handle) = Figure(handle,CurveData[CurveData()],AxesConf(),true)

# coordinate type
Coord = Union(UnitRange,Range,Matrix,Vector)

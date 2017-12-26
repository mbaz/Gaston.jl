## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Structure to keep Gaston's configuration
mutable struct GastonConfig
    # default CurveConf values
    legend::AbstractString
    plotstyle::AbstractString
    color::AbstractString
    marker::AbstractString
    linewidth::Real
    pointsize::Real
    # default AxesConf values
    title::AbstractString
    xlabel::AbstractString
    ylabel::AbstractString
    zlabel::AbstractString
    fill::AbstractString
    grid::AbstractString
    box::AbstractString
    axis::AbstractString
    xrange::AbstractString
    yrange::AbstractString
    zrange::AbstractString
    # default terminal type
    terminal::AbstractString
    # for terminals that support filenames
    outputfile::AbstractString
    # for printing to file
    print_color::AbstractString
    print_fontface::AbstractString
    print_fontsize::Real
    print_fontscale::Real
    print_linewidth::Real
    print_size::AbstractString
end
function GastonConfig()
	gc = GastonConfig(
		# CurveConf
		"","lines","","",1,0.5,
		# AxesConf
		"Untitled","x","y","z","empty","off","inside vertical right top","",
		"[*:*]","[*:*]","[*:*]",
		# terminal
		"wxt",
		# output file name
		"",
		# print parameters
		"color", "Sans", 12, 0.5, 1, "640,480"
	)
	# Determine if current display supports PNG; this allows IJulia support.
	if displayable("image/png")
		gc.outputfile = "$(tempdir())/gaston-ijulia.png"
		gc.terminal = "png"
		gc.print_fontsize = 20
	end
	return gc
end

# Set any of Gaston's configuration variables
# This function assumes that gaston_config exists
function set(;legend         = gaston_config.legend,
			 plotstyle       = gaston_config.plotstyle,
			 color           = gaston_config.color,
			 marker          = gaston_config.marker,
			 linewidth       = gaston_config.linewidth,
			 pointsize       = gaston_config.pointsize,
			 title           = gaston_config.title,
			 xlabel          = gaston_config.xlabel,
			 ylabel          = gaston_config.ylabel,
			 zlabel          = gaston_config.zlabel,
			 fill            = gaston_config.fill,
			 grid            = gaston_config.grid,
			 box             = gaston_config.box,
			 axis            = gaston_config.axis,
			 xrange          = gaston_config.xrange,
			 yrange          = gaston_config.yrange,
			 zrange          = gaston_config.zrange,
			 terminal        = gaston_config.terminal,
			 outputfile      = gaston_config.outputfile,
			 print_color     = gaston_config.print_color,
			 print_fontface  = gaston_config.print_fontface,
			 print_fontscale = gaston_config.print_fontscale,
			 print_linewidth = gaston_config.print_linewidth,
			 print_size      = gaston_config.print_size)
	# Validate paramaters
	isa(legend, String) || error("Legend must be a string.")
	plotstyle ∈ supported_plotstyles || error("Plotstyle $(plotstyle) not supported.")
	isa(color, String) || error("Color must be a string.")
    marker ∈ supported_markers || error("Marker $(marker) not supported.")
	(isa(linewidth, Real) && linewidth > 0) || error("Invalid linewdith.")
	(isa(pointsize, Real) && pointsize > 0) || error("Invalid pointsize.")
	isa(title, String) || error("Title must be a string.")
	isa(xlabel, String) || error("xlabel must be a string.")
	isa(ylabel, String) || error("ylabel must be a string.")
	isa(zlabel, String) || error("zlabel must be a string.")
	fill ∈ supported_fillstyles || error("Fill style $(fill) not supported.")
	grid ∈ supported_grids || error("Grid style $(grid) not supported.")
	isa(box, String) || error("Box must be a string.")
    axis ∈ supported_axis || error("Axis $(axis) not supported.")
    validate_range(xrange) || error("Range $(xrange) not supported.")
    validate_range(yrange) || error("Range $(yrange) not supported.")
    validate_range(zrange) || error("Range $(zrange) not supported.")
    terminal ∈ supported_terminals || error("Terminal type $(terminal) not supported.")
	isa(outputfile, String) || error("Outputfile must be a string.")
	isa(print_color, String) || error("print_color must be a string.")
	isa(print_fontface, String) || error("print_fontface must be a string.")
	isa(print_fontscale, Real) || error("Invalid print_fontscale.")
	isa(print_linewidth, Real) || error("Invalid print_linewidth.")
	isa(print_size, String) || error("print_size must be a string.")

	gaston_config.legend            = legend
	gaston_config.plotstyle         = plotstyle
	gaston_config.color             = color
	gaston_config.marker            = marker
	gaston_config.linewidth         = linewidth
	gaston_config.pointsize         = pointsize
	gaston_config.title             = title
	gaston_config.xlabel            = xlabel
	gaston_config.ylabel            = ylabel
	gaston_config.zlabel            = zlabel
	gaston_config.fill              = fill
	gaston_config.grid              = grid
	gaston_config.box               = box
	gaston_config.axis              = axis
	gaston_config.xrange            = xrange
	gaston_config.yrange            = yrange
	gaston_config.zrange            = zrange
	gaston_config.terminal          = terminal
	gaston_config.outputfile        = outputfile
	gaston_config.print_color       = print_color
	gaston_config.print_fontface    = print_fontface
	gaston_config.print_fontscale   = print_fontscale
	gaston_config.print_linewidth   = print_linewidth
	gaston_config.print_size        = print_size
	return nothing
end

# Validate that a given range follows gnuplot's syntax.
function validate_range(s::AbstractString)
    # floating point, starting with a dot
    f1 = "[-+]?\\.\\d+([eE][-+]?\\d+)?"
    # floating point, starting with a digit
    f2 = "[-+]?\\d+(\\.\\d*)?([eE][-+]?\\d+)?"
    # floating point
    f = "($f1|$f2)"
    # autoscale directive (i.e. `*` surrounded by
    # optional bounds lb < * < ub)
    as = "(($f\\s*<\\s*)?\\*(\\s*<\\s*$f)?)"
    # full range item: a floating point, or an
    # autoscale directive, or nothing
    it = "(\\s*($as|$f)?\\s*)"

    # empty range
    er = "\\[\\s*\\]"
    # full range: two colon-separated items
    fr = "\\[$it:$it\\]"

    # range regex
    rx = Regex("^\\s*($er|$fr)\\s*\$")

    if isempty(s) || ismatch(rx, s)
        return true
    end
    return false
end

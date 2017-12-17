## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

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
	# The following parameters are validated
    if validate_2d_plotstyle(plotstyle) ||
    	validate_3d_plotstyle(plotstyle) ||
    	validate_image_plotstyle(plotstyle)
        gaston_config.plotstyle = plotstyle
    else
		error("Plotstyle $(plotstyle) not supported.")
    end
    if validate_marker(marker)
        gaston_config.marker = marker
    else
		error("Marker $(marker) not supported.")
    end
	if validate_fillstyle(fill)
		gaston_config.fill = fill
	else
		error("Fill style $(fill) not supported.")
	end
	if validate_grid(grid)
		gaston_config.grid = grid
	else
		error("Grid style $(grid) not supported.")
	end
    if validate_axis(axis)
        gaston_config.marker = axis
    else
		error("Axis $(axis) not supported.")
    end
    if validate_range(xrange)
        gaston_config.xrange = xrange
    else
		error("Range $(xrange) not supported.")
    end
    if validate_range(yrange)
        gaston_config.yrange = yrange
    else
		error("Range $(yrange) not supported.")
    end
    if validate_range(zrange)
        gaston_config.zrange = zrange
    else
		error("Range $(zrange) not supported.")
    end
    if validate_terminal(terminal)
        gaston_config.terminal = terminal
    else
		error("Terminal type $(terminal) not supported.")
    end
    # The folowwing parameters are not validated
	gaston_config.color             = color
	gaston_config.legend            = legend
	gaston_config.linewidth         = linewidth
	gaston_config.pointsize         = pointsize
	gaston_config.title             = title
	gaston_config.xlabel            = xlabel
	gaston_config.ylabel            = ylabel
	gaston_config.zlabel            = zlabel
	gaston_config.fill              = fill
	gaston_config.grid              = grid
	gaston_config.box               = box
	gaston_config.outputfile        = outputfile
	gaston_config.print_color       = print_color
	gaston_config.print_fontface    = print_fontface
	gaston_config.print_fontscale   = print_fontscale
	gaston_config.print_linewidth   = print_linewidth
	gaston_config.print_size        = print_size
	return nothing
end

# Configuration validation functions.
# These functions validate that configuration parameters are valid and
# supported. They return true iff the argument validates.

# Validate terminal type.
function validate_terminal(s::AbstractString)
    supp_terms = ["qt", "wxt", "x11", "svg", "gif", "png", "pdf", "aqua", "eps"]
    if !is_apple() && s == "aqua"
        return false
    end
    s ∈ supp_terms && return true
    return false
end

# Identify terminal by type: file or screen
function is_term_screen(s::AbstractString)
    screenterms = ["qt", "wxt", "x11", "aqua"]
    s ∈ screenterms && return true
    return false
end

function is_term_file(s::AbstractString)
    screenterms = ["svg", "gif", "png", "pdf", "eps"]
    s ∈ screenterms && return true
    return false
end

# Valid plotstyles supported by gnuplot's plot
function validate_2d_plotstyle(s::AbstractString)
    plotstyles = ["lines", "linespoints", "points", "impulses", "boxes",
        "errorlines", "errorbars", "dots", "steps", "fsteps", "fillsteps",
        "financebars"]
    s ∈ plotstyles && return true
    return false
end

# Valid plotstyles supported by gnuplot's splot
function validate_3d_plotstyle(s::AbstractString)
    plotstyles = ["lines", "linespoints", "points", "impulses", "pm3d",
            "image", "rgbimage", "dots"]
    s ∈ plotstyles && return true
    return false
end

# Valid axis types
function validate_axis(s::AbstractString)
    axis = ["", "normal", "semilogx", "semilogy", "loglog"]
    s ∈ axis && return true
    return false
end

# Valid markers supported by Gaston
function validate_marker(s::AbstractString)
    markers = ["", "+", "x", "*", "esquare", "fsquare", "ecircle", "fcircle",
    "etrianup", "ftrianup", "etriandn", "ftriandn", "edmd", "fdmd"]
    s ∈ markers && return true
    return false
end

# Validate fill style
function validate_fillstyle(s::AbstractString)
	fillstyles = ["","empty","solid","pattern"]
	s ∈ fillstyles && return true
	return false
end

# Validate grid styles
function validate_grid(s::AbstractString)
	grids = ["", "on", "off"]
	s ∈ grids && return true
	return false
end

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

## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains configuration-related functions and types

# Structure to keep Gaston's configuration
mutable struct GastonConfig
    # default CurveConf values
    legend::String
    plotstyle::String
    color::String
    marker::String
    linewidth::Real
    linestyle::String
    pointsize::Real
    # default AxesConf values
    title::String
    xlabel::String
    ylabel::String
    zlabel::String
    fill::String
    grid::String
    box::String
    axis::String
    xrange::String
    yrange::String
    zrange::String
    palette::String
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
    print_size::String     # user-configured print size
    print_size_in::String  # some terminals specify size in inches
    print_size_pix::String # ... and some in pixels
    # prefix for temp data files
    tmpprefix::String
end

function GastonConfig()
    gc = GastonConfig(
	# CurveConf
	"","lines","blue","",1,"",0.5,
	# AxesConf
	"","","","","empty","off","inside vertical right top","",
	"[*:*]","[*:*]","[*:*]","",
	# terminal
	"qt",
	# output file name
	"",
    # print parameters
    "color", "Sans", 12, 0.5, 1, "", "5in,3in", "800,600",
    # tmp file prefix
    randstring(8)
    )
    # set terminal if running inside a Jupyter notebook
    if isjupyter
        gc.terminal = "ijulia"
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
             linestyle       = gaston_config.linestyle,
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
             palette         = gaston_config.palette,
             terminal        = gaston_config.terminal,
             outputfile      = gaston_config.outputfile,
             print_color     = gaston_config.print_color,
             print_fontface  = gaston_config.print_fontface,
             print_fontscale = gaston_config.print_fontscale,
             print_linewidth = gaston_config.print_linewidth,
             print_size      = gaston_config.print_size,
             print_size_in   = gaston_config.print_size_in,
             print_size_pix  = gaston_config.print_size_pix)
    # Validate paramaters
    @assert valid_label(legend) "Legend must be a string."
    @assert valid_plotstyle(plotstyle) "Plotstyle $(plotstyle) not supported."
    @assert valid_label(color) "Color must be a string."
    @assert valid_marker(marker) "Marker $(marker) not supported."
    @assert valid_number(linewidth) "Invalid linewdith."
    @assert valid_number(pointsize) "Invalid pointsize."
    @assert valid_label(title) "Title must be a string."
    @assert valid_label(xlabel) "xlabel must be a string."
    @assert valid_label(ylabel) "ylabel must be a string."
    @assert valid_label(zlabel) "zlabel must be a string."
    @assert valid_fill(fill) "Fill style $(fill) not supported."
    @assert valid_grid(grid) "Grid style $(grid) not supported."
    @assert valid_label(box) "box must be a string."
    @assert valid_axis(axis) "Axis $(axis) not supported."
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert valid_range(zrange) "Range $(yrange) not supported."
    @assert valid_label(palette) "Invalid palette."
    @assert valid_terminal(terminal) "Terminal type $(terminal) not supported."
    @assert valid_label(outputfile) "Outputfile must be a string."
    @assert valid_label(print_color) "print_color must be a string."
    @assert valid_label(print_fontface) "print_fontface must be a string."
    @assert valid_number(print_fontscale) "Invalid value of print_fontscale"
    @assert valid_number(print_linewidth) "Invalid value of print_linewidth"
    @assert valid_label(print_size) "print_size must be a string."
    @assert valid_label(print_size_in) "print_size_in must be a string."
    @assert valid_label(print_size_pix) "print_size_pix must be a string."
    @assert valid_linestyle(linestyle) string("Line style pattern accepts: ",
            "space, dash, underscore and dot")

    gaston_config.legend            = legend
    gaston_config.plotstyle         = plotstyle
    gaston_config.color             = color
    gaston_config.marker            = marker
    gaston_config.linewidth         = linewidth
    gaston_config.linestyle         = linestyle
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
    gaston_config.palette           = palette
    gaston_config.outputfile        = outputfile
    gaston_config.print_color       = print_color
    gaston_config.print_fontface    = print_fontface
    gaston_config.print_fontscale   = print_fontscale
    gaston_config.print_linewidth   = print_linewidth
    gaston_config.print_size        = print_size
    gaston_config.print_size_in     = print_size_in
    gaston_config.print_size_pix    = print_size_pix
    # don't change terminal inside jupyter
    if terminal != "ijulia" && isjupyter
        @warn("Terminal cannot be changed in a Jupyter notebook.")
        gaston_config.terminal = "ijulia"
    else
        gaston_config.terminal = terminal
    end
    return nothing
end

### Encode terminal capabilities
# supports multiple windows
const term_window = ["qt", "wxt", "x11", "aqua"]
# outputs text
const term_text = ["dumb", "null", "sixelgd", "ijulia"]
# outputs to a file
const term_file = ["svg", "gif", "png", "pdf", "eps"]
# size and units
const term_sup_size = ["qt", "wxt", "x11", "sixel", "svg", "gif", "png",
                        "pdf", "eps", "dumb"]
const term_size_in = ["pdf", "eps"]
const term_size_pix = ["qt", "wxt", "x11", "sixelgd", "ijulia",
                        "svg", "gif", "png"]
# font
const term_sup_font = ["qt", "wxt", "x11", "aqua", "sixel", "svg", "gif",
                       "png", "pdf", "eps"]
# font scaling
const term_sup_fontscale = ["wxt", "sixel", "gif", "png", "pdf", "eps"]
# linewidth
const term_sup_lw = ["qt", "wxt", "x11", "aqua", "sixel", "svg", "gif",
                     "png", "pdf", "eps"]

# List of valid configuration values
const supported_terminals = ["qt", "wxt", "x11", "aqua", "dumb", "null",
                             "sixelgd", "ijulia", "svg", "gif", "png", "pdf",
                             "eps"]
const supported_2Dplotstyles = ["lines", "linespoints", "points",
        "impulses", "boxes", "errorlines", "errorbars", "dots", "steps",
        "fsteps", "fillsteps", "financebars"]
const supported_3Dplotstyles = ["lines", "linespoints", "points",
        "impulses", "pm3d", "image", "rgbimage", "dots"]
const supported_plotstyles = vcat(supported_2Dplotstyles, supported_3Dplotstyles)
const supported_axis = ["", "normal", "semilogx", "semilogy", "loglog"]
const supported_markers = ["", "+", "x", "*", "esquare", "fsquare",
        "ecircle", "fcircle", "etrianup", "ftrianup", "etriandn",
        "ftriandn", "edmd", "fdmd"]
const supported_fillstyles = ["","empty","solid","pattern"]
const supported_grids = ["", "on", "off"]

#
# Validation functions
#

valid_terminal(s) = s ∈ supported_terminals
valid_plotstyle(s) = s ∈ supported_plotstyles
valid_2Dplotstyle(s) = s ∈ supported_2Dplotstyles
valid_3Dplotstyle(s) = s ∈ supported_3Dplotstyles
valid_marker(s) = s ∈ supported_markers
valid_number(s) = isa(s, Real) && s > 0
valid_label(s) = isa(s, String)
valid_fill(s) = s ∈ supported_fillstyles
valid_grid(s) = s ∈ supported_grids
valid_axis(s) = s ∈ supported_axis

function valid_linestyle(s)
    s == "" && return true # allow empty string
    c = collect(s)
    # make sure only allowed characters are passed
    issubset(c, Set([' ', '-', '_', '.'])) || return false
    # but do not allow spaces only
    unique(c) != [' ']
end

# Validate that a given range follows gnuplot's syntax.
function valid_range(s::AbstractString)
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

    if isempty(s) || occursin(rx, s)
        return true
    end

    return false
end

# Validate coordinates
function valid_coords(x,y;err=ErrorCoords(),fin=FinancialCoords())
    length(x) != length(y) && return false
    (err.valid && length(x) != length(err.ylow)) && return false
    (err.valid && !isempty(err.yhigh) && length(x) !=
        length(err.yhigh)) && return false
    (fin.valid && length(x) != length(fin.open)) && return false
    (fin.valid && length(x) != length(fin.low)) && return false
    (fin.valid && length(x) != length(fin.high)) && return false
    (fin.valid && length(x) != length(fin.close)) && return false
    return true
end

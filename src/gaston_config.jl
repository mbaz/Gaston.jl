## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains configuration-related functions and types

# Structure to keep Gaston's configuration
mutable struct GastonConfig
    # default CurveConf values
    plotstyle::String
    linecolor::String
    linewidth::String
    linestyle::String
    pointtype::String
    pointsize::String
    # default AxesConf values
    fill::String
    grid::String
    keyoptions::String
    axis::String
    xrange::String
    yrange::String
    zrange::String
    xzeroaxis::String
    yzeroaxis::String
    zzeroaxis::String
    palette::String
    # default terminal type and options
    terminal::String
    font::String
    size::String
    background::String
    termopts::String
    # for printing to file
    print_term::String
    print_font::String
    print_size::String
    print_linewidth::String
    print_outputfile::String
    # prefix for temp data files
    tmpprefix::String
end

function GastonConfig()
    term = "qt"
    isjupyter && (term = "ijulia")
    gc = GastonConfig(
        # CurveConf
        "","","","","","",
        # AxesConf
        "","","","","","","","","","","",
        # terminal
        term, "", "", "", "",
        # print parameters
        "pdf", "", "", "", "",
        # tmp file prefix
        randstring(8)
    )
    return gc
end

# Set any of Gaston's configuration variables
# This function assumes that gaston_config exists
function set(;plotstyle       = gaston_config.plotstyle,
             linecolor        = gaston_config.linecolor,
             linewidth        = gaston_config.linewidth,
             linestyle        = gaston_config.linestyle,
             pointtype        = gaston_config.pointtype,
             pointsize        = gaston_config.pointsize,
             fill             = gaston_config.fill,
             grid             = gaston_config.grid,
             keyoptions       = gaston_config.keyoptions,
             axis             = gaston_config.axis,
             xrange           = gaston_config.xrange,
             yrange           = gaston_config.yrange,
             zrange           = gaston_config.zrange,
             xzeroaxis        = gaston_config.xzeroaxis,
             yzeroaxis        = gaston_config.yzeroaxis,
             zzeroaxis        = gaston_config.zzeroaxis,
             palette          = gaston_config.palette,
             terminal         = gaston_config.terminal,
             font             = gaston_config.font,
             size             = gaston_config.size,
             background       = gaston_config.background,
             termopts         = gaston_config.termopts,
             print_term       = gaston_config.print_term,
             print_font       = gaston_config.print_font,
             print_size       = gaston_config.print_size,
             print_linewidth  = gaston_config.print_linewidth,
             print_outputfile = gaston_config.print_outputfile,
             reset            = false
            )
    # Validate paramaters
    @assert valid_plotstyle(plotstyle) "Plotstyle $(plotstyle) not supported."
    @assert valid_linestyle(linestyle) string("Line style pattern accepts: ",
            "space, dash, underscore and dot.")
    @assert valid_pointtype(pointtype) "Marker $(pointtype) not supported."
    @assert valid_axis(axis) "Axis $(axis) not supported."
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert valid_range(zrange) "Range $(yrange) not supported."
    @assert valid_terminal(terminal) "Terminal type $(terminal) not supported."

    if reset
        gaston_config.plotstyle        = ""
        gaston_config.linecolor        = ""
        gaston_config.linewidth        = ""
        gaston_config.linestyle        = ""
        gaston_config.pointtype        = ""
        gaston_config.pointsize        = ""
        gaston_config.fill             = ""
        gaston_config.grid             = ""
        gaston_config.keyoptions       = ""
        gaston_config.axis             = ""
        gaston_config.xrange           = ""
        gaston_config.yrange           = ""
        gaston_config.zrange           = ""
        gaston_config.xzeroaxis        = ""
        gaston_config.yzeroaxis        = ""
        gaston_config.zzeroaxis        = ""
        gaston_config.palette          = ""
        gaston_config.terminal         = "qt"
        isjupyter && (gaston_config.terminal = "ijulia")
        gaston_config.font             = ""
        gaston_config.size             = ""
        gaston_config.background       = ""
        gaston_config.termopts         = ""
        gaston_config.print_term       = "pdf"
        gaston_config.print_font       = ""
        gaston_config.print_size       = ""
        gaston_config.print_linewidth  = ""
        gaston_config.print_outputfile = ""
    else
        gaston_config.plotstyle         = plotstyle
        gaston_config.linecolor         = linecolor
        gaston_config.linewidth         = linewidth
        gaston_config.linestyle         = linestyle
        gaston_config.pointtype         = pointtype
        gaston_config.pointsize         = pointsize
        gaston_config.fill              = fill
        gaston_config.grid              = grid
        gaston_config.keyoptions        = keyoptions
        gaston_config.axis              = axis
        gaston_config.xrange            = xrange
        gaston_config.yrange            = yrange
        gaston_config.zrange            = zrange
        gaston_config.xzeroaxis         = xzeroaxis
        gaston_config.yzeroaxis         = yzeroaxis
        gaston_config.zzeroaxis         = zzeroaxis
        gaston_config.palette           = palette
        gaston_config.terminal          = terminal
        isjupyter && (gaston_config.terminal = "ijulia")
        gaston_config.font              = font
        gaston_config.size              = size
        gaston_config.background        = background
        gaston_config.termopts          = termopts
        gaston_config.print_term        = print_term
        gaston_config.print_font        = print_font
        gaston_config.print_size        = print_size
        gaston_config.print_linewidth   = print_linewidth
        gaston_config.print_outputfile  = print_outputfile
    end

    return nothing
end

### Encode terminal capabilities
# supports multiple windows
const term_window = ["qt", "wxt", "x11", "aqua"]
# outputs text
const term_text = ["dumb", "null", "sixelgd", "ijulia"]
# outputs to a file
const term_file = ["svg", "gif", "png", "pdf", "eps", "pngcairo", "pdfcairo",
                   "epscairo"]
# supports size
const term_sup_size = ["qt", "wxt", "x11", "sixelgd", "svg", "gif", "png",
                        "pdf", "eps", "dumb", "pngcairo", "pdfcairo", "epscairo"]
# supports font
const term_sup_font = ["qt", "wxt", "x11", "aqua", "sixelgd", "svg", "gif",
                       "png", "pdf", "eps", "pngcairo", "pdfcairo", "epscairo"]
# supports linewidth
const term_sup_lw = ["qt", "wxt", "x11", "aqua", "sixelgd", "svg", "gif",
                     "png", "pdf", "eps", "pngcairo", "pdfcairo", "epscairo"]
# supports background color
const term_sup_bkgnd = ["sixelgd", "svg", "wxt", "gif", "pdf", "eps", "png",
                        "pdfcairo", "pngcairo", "epscairo"]

# List of valid configuration values
const supported_terminals = ["", "qt", "wxt", "x11", "aqua", "dumb", "null",
                             "sixelgd", "ijulia", "svg", "gif", "png", "pdf",
                             "eps"]
const supported_2Dplotstyles = ["", "lines", "linespoints", "points",
                                "impulses", "boxes", "errorlines", "errorbars",
                                "dots", "steps", "fsteps", "fillsteps",
                                "financebars"]
const supported_3Dplotstyles = ["", "lines", "linespoints", "points",
                                "impulses", "pm3d", "image", "rgbimage", "dots"]
const supported_plotstyles = vcat(supported_2Dplotstyles, supported_3Dplotstyles)
const supported_axis = ["", "normal", "semilogx", "semilogy", "semilogz",
                        "loglog"]
const supported_pointtypes = ["", "+", "x", "*", "esquare", "fsquare",
                          "ecircle", "fcircle", "etrianup", "ftrianup",
                          "etriandn", "ftriandn", "edmd", "fdmd"]
# List of plotstyles that support points
const ps_sup_points = ["linespoints", "points", "dots"]

#
# Validation functions
#

valid_terminal(s) = s ∈ supported_terminals
valid_plotstyle(s) = s ∈ supported_plotstyles
valid_2Dplotstyle(s) = s ∈ supported_2Dplotstyles
valid_3Dplotstyle(s) = s ∈ supported_3Dplotstyles
valid_pointtype(s) = s ∈ supported_pointtypes
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
function valid_range(s::String)
    s == "" && return true # allow empty strings
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

    if occursin(rx, s)
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

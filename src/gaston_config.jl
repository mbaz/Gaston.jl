## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains configuration-related functions and types

# default term file string
const tmpprefix = randstring(8)

# Default font, size and background for each supported terminal
const TerminalDefaults = Dict("wxt" => Dict(:font       => "Sans,10",
                                            :size       => "640,384",
                                            :background => "white"),
                              "qt" => Dict(:font       => "Sans,9",
                                           :size       => "640,480",
                                           :background => ""),
                              "x11" => Dict(:font       => "",
                                            :size       => "640,480",
                                            :background => ""),
                              "aqua" => Dict(:font       => "Times-Roman,14",
                                             :size       => "846,594",
                                             :background => ""),
                              "dumb" => Dict(:font       => "",
                                             :size       => "79,24",
                                             :background => ""),
                              "sixelgd" => Dict(:font       => "Sans,12",
                                                :size       => "640,480",
                                                :background => "white"),
                              "svg" => Dict(:font       => "Arial,12",
                                            :size       => "640,384",
                                            :background => "white"),
                              "gif" => Dict(:font       => "Sans,12",
                                            :size       => "640,480",
                                            :background => "white"),
                              "pngcairo" => Dict(:font       => "Sans,12",
                                                 :size       => "640,480",
                                                 :background => "white"),
                              "pdfcairo" => Dict(:font       => "Sans,12",
                                                 :size       => "5,3",
                                                 :background => "white"),
                              "epscairo" => Dict(:font       => "Sans,12",
                                                 :size       => "5,3",
                                                 :background => "white")
)

# Dicts to store user-specified configuration
default_term_config() = Dict(:terminal => IsJupyter ? "svg" : "qt",
                             :termvar => IsJupyter ? "ijulia" : "",
                             :font => "",
                             :size => "",
                             :glinewidth => "",
                             :background => "",
                             :termopts => "")
default_axes_config() = Dict(:axis => "",
                             :xrange => "",
                             :yrange => "",
                             :zrange => "",
                             :fill => "",
                             :grid => "",
                             :xzeroaxis => "",
                             :yzeroaxis => "",
                             :zzeroaxis => "",
                             :keyoptions => "",
                             :palette => "")
default_curve_config() = Dict(:plotstyle => "",
                              :linecolor => "",
                              :linewidth => "",
                              :linestyle => "",
                              :pointtype => "",
                              :pointsize => "")
default_print_config() = Dict(:print_term => "pdfcairo",
                              :print_font => "",
                              :print_size => "",
                              :print_linewidth => "",
                              :print_background => "",
                              :print_outputfile => "")

# Set any of Gaston's configuration variables
function set(;reset = false, terminal=usr_term_cnf[:terminal], kw...)
    global usr_term_cnf
    global usr_axes_cnf
    global usr_curve_cnf
    global usr_print_cnf

    if reset
        usr_term_cnf = default_term_config()
        usr_axes_cnf = default_axes_config()
        usr_curve_cnf = default_curve_config()
        usr_print_cnf = default_print_config()
        return nothing
    end

    termvar = ""
    if terminal == "ijulia"
        terminal = "svg"
        termvar = "ijulia"
    elseif terminal == "null"
        terminal = "dumb"
        termvar = "null"
    elseif terminal == "pdf"
        terminal = "pdfcairo"
    elseif terminal == "png"
        terminal = "pngcairo"
    elseif terminal == "eps"
        terminal = "epscairo"
    end
    valid_terminal(terminal)
    usr_term_cnf[:terminal] = terminal
    usr_term_cnf[:termvar] = termvar

    for k in keys(kw)
        k == :plotstyle && valid_plotstyle(kw[k])
        k == :linestyle && valid_linestyle(kw[k])
        k == :pointtype && valid_pointtype(kw[k])
        k == :axis && valid_axis(kw[k])
        k == :xrange && valid_range(kw[k])
        k == :yrange && valid_range(kw[k])
        k == :zrange && valid_range(kw[k])
        flag = true
        haskey(usr_term_cnf, k) && (flag=false;usr_term_cnf[k] = kw[k])
        haskey(usr_axes_cnf, k) && (flag=false;usr_axes_cnf[k] = kw[k])
        haskey(usr_curve_cnf, k) && (flag=false;usr_curve_cnf[k] = kw[k])
        haskey(usr_print_cnf, k) && (flag=false;usr_print_cnf[k] = kw[k])
        flag && throw(MethodError(set, "invalid setting"))
    end

    return nothing
end

### Encode terminal capabilities
# supports multiple windows
const term_window = ["qt", "wxt", "x11", "aqua"]
# outputs text
const term_text = ["dumb", "sixelgd"]
# outputs to a file
const term_file = ["svg", "gif", "pngcairo", "pdfcairo", "epscairo"]
# supports size
const term_sup_size = ["qt", "wxt", "x11", "sixelgd", "svg", "gif",
                       "dumb", "pngcairo", "pdfcairo", "epscairo"]
# supports font
const term_sup_font = ["qt", "wxt", "x11", "aqua", "sixelgd", "svg",
                       "gif","pngcairo", "pdfcairo", "epscairo"]
# supports linewidth
const term_sup_lw = ["qt", "wxt", "x11", "aqua", "sixelgd", "svg",
                     "gif", "pngcairo", "pdfcairo", "epscairo"]
# supports background color
const term_sup_bkgnd = ["sixelgd", "svg", "wxt", "gif", "pdfcairo", "pngcairo", "epscairo"]

# List of valid configuration values
const supported_terminals = ["", "qt", "wxt", "x11", "aqua", "dumb", "sixelgd",
                             "svg", "gif", "pngcairo", "pdfcairo", "epscairo"]
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
const ps_sup_points = ["linespoints", "points"]

#
# Validation functions
#

function valid_file_term(s)
    s ∈ term_file && return true
    throw(DomainError(s,"supported terminals are: $term_file"))
end

function valid_terminal(s)
    s ∈ supported_terminals && return true
    throw(DomainError(s,"supported terminals are: $supported_terminals"))
end
function valid_plotstyle(s)
    s ∈ supported_plotstyles && return true
    throw(DomainError(s,"supported plotstyles are: $supported_plotstyles"))
end
function valid_2Dplotstyle(s)
    s ∈ supported_2Dplotstyles && return true
    throw(DomainError(s,"supported 2-D plotstyles are: $supported_2Dplotstyles"))
end
function valid_3Dplotstyle(s)
    s ∈ supported_3Dplotstyles && return true
    throw(DomainError(s,"supported 3-D plotstyles are: $supported_3Dplotstyles"))
end
function valid_pointtype(s)
    s ∈ supported_pointtypes && return true
    throw(DomainError(s,"supported point types are: $supported_pointtypes"))
end
function valid_axis(s)
    s ∈ supported_axis && return true
    throw(DomainError(s,"supported axis types are: $supported_axis"))
end

function valid_linestyle(s)
    invalid = false
    s == "" && return true # allow empty string
    c = collect(s)
    # make sure only allowed characters are passed
    issubset(c, Set([' ', '-', '_', '.'])) || (invalid = true)
    # but do not allow spaces only
    unique(c) != [' '] || (invalid = true)
    invalid && throw(DomainError(s,"line style pattern accepts: space, dash, underscore and dot"))
    return true
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

    throw(DomainError(s,"range must have have the form of [x:y]"))
end

# Validate coordinates
function valid_coords(x,y;err=ErrorCoords(),fin=FinancialCoords())
    invalid = false
    length(x) != length(y) && (invalid = true)
    (err.valid && length(x) != length(err.ylow)) && (invalid = true)
    (err.valid && !isempty(err.yhigh) && length(x) !=
        length(err.yhigh)) && (invalid = true)
    (fin.valid && length(x) != length(fin.open)) && (invalid = true)
    (fin.valid && length(x) != length(fin.low)) && (invalid = true)
    (fin.valid && length(x) != length(fin.high)) && (invalid = true)
    (fin.valid && length(x) != length(fin.close)) && (invalid = true)

    invalid && throw(DimensionMismatch("input vectors must have the same nu mber of elements."))

    return true
end

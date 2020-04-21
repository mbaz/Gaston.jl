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
                                                 :background => "white"),
                              "epslatex" => Dict(:font       => "Sans,12",
                                                 :size       => "5,3",
                                                 :background => "white"),
                              "cairolatex" => Dict(:font       => "Sans,12",
                                                 :size         => "5,3",
                                                 :background   => "white"))

# Dicts to store user-specified configuration
default_config() = Dict(:mode => IsJupyterOrJuno ? "ijulia" : "normal",
                        :timeouts => Dict(:stdout_timeout => Sys.isunix() ? 6 : 20,
                                          :stderr_timeout => Sys.isunix() ? 6 : 20),
                        :debug => false,
                        :term => Dict(:terminal => IsJupyterOrJuno ? "svg" : "qt",
                                      :font => "",
                                      :size => "",
                                      :background => "",
                                      :termopts => ""),
                        :axes => Dict(:title => "",
                                      :xlabel => "",
                                      :ylabel => "",
                                      :zlabel => "",
                                      :axis => "",
                                      :xrange => "",
                                      :yrange => "",
                                      :zrange => "",
                                      :fillstyle => "",
                                      :grid => "",
                                      :boxwidth => "",
                                      :xtics => "",
                                      :ytics => "",
                                      :ztics => "",
                                      :xzeroaxis => "",
                                      :yzeroaxis => "",
                                      :zzeroaxis => "",
                                      :keyoptions => "",
                                      :palette => "",
                                      :view => "",
                                      :onlyimpulses => false),
                        :curve => Dict(:plotstyle => "",
                                       :linecolor => "",
                                       :linewidth => "",
                                       :linestyle => "",
                                       :pointtype => "",
                                       :pointsize => "",
                                       :fillcolor => "",
                                       :fillstyle => ""))
# Set any of Gaston's configuration variables
function set(;reset = false, terminal=config[:term][:terminal],
             mode = config[:mode], kw...)
    global config

    if reset
        config = default_config()
        return nothing
    end

    t = terminal
    mode == "ijulia" && (t = "svg")
    mode == "null" && (t = "dumb")
    if mode == "normal"
        terminal == "pdf" && (t = "pdfcairo")
        terminal == "pnf" && (t = "pnfcairo")
        terminal == "eps" && (t = "epscairo")
    end
    valid_terminal(t)
    config[:term][:terminal] = t
    config[:mode] = mode

    for k in keys(kw)
        if k == :debug
            kw[k] isa Bool && (config[:debug] = kw[k]; continue)
            throw(DomainError("argument to debug must be Bool"))
        end
        if k == :stdout_timeout || k == :stderr_timeout
            kw[k] isa Real && kw[k] > 0 && (config[:timeouts][k] = kw[k]; continue)
            throw(DomainError("timeout argument must be a positive number"))
        end
        k == :plotstyle && valid_plotstyle(kw[k])
        k == :linestyle && valid_linestyle(kw[k])
        k == :pointtype && valid_pointtype(kw[k])
        k == :axis && valid_axis(kw[k])
        k == :xrange && valid_range(kw[k])
        k == :yrange && valid_range(kw[k])
        k == :zrange && valid_range(kw[k])
        flag = true
        for i in [:term, :axes, :curve]
            c = config[i]
            haskey(c, k) && (flag=false; c[k] = string(kw[k]))
        end
        flag && throw(ArgumentError("$k is an invalid setting"))
    end

    return nothing
end

### Encode terminal capabilities
# supports multiple windows
const term_window = ["qt", "wxt", "x11", "aqua"]
# outputs text
const term_text = ["dumb", "sixelgd"]
# outputs to a file
const term_file = ["svg", "gif", "pngcairo", "pdfcairo", "epscairo",
                   "epslatex", "cairolatex", "dumb"]
# supports size
const term_sup_size = ["qt", "wxt", "x11", "sixelgd", "svg", "gif",
                       "dumb", "pngcairo", "pdfcairo", "epscairo",
                       "epslatex", "cairolatex"]
# supports font
const term_sup_font = ["qt", "wxt", "x11", "aqua", "sixelgd", "svg",
                       "gif","pngcairo", "pdfcairo", "epscairo",
                       "epslatex", "cairolatex"]
# supports background color
const term_sup_bkgnd = ["sixelgd", "svg", "wxt", "gif", "pdfcairo",
                        "pngcairo", "epscairo", "epslatex", "cairolatex"]
# supports linewidth
const term_sup_lw = ["qt", "wxt", "x11", "gif", "pdfcairo", "pngcairo",
                     "epscairo", "epslatex", "aqua", "sixelgd", "svg"]

# List of valid configuration values
const supported_terminals = ["", "qt", "wxt", "x11", "aqua", "dumb", "sixelgd",
                             "svg", "gif", "pngcairo", "pdfcairo", "epscairo",
                             "epslatex", "cairolatex"]
const supported_2Dplotstyles = ["", "lines", "linespoints", "points",
                                "impulses", "boxes", "errorlines", "errorbars",
                                "dots", "steps", "fsteps", "fillsteps",
                                "financebars"]
const supported_3Dplotstyles = ["", "lines", "linespoints", "points", "labels",
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
    isempty(s) && return true
    length(s) == 1 && return true
    s ∈ supported_pointtypes && return true
    throw(DomainError(s,"supported point types are: $supported_pointtypes or single-character strings"))
end
function valid_numeric(s)
    isempty(s) && return true
    ss = tryparse(Float64,s)
    (ss != nothing && ss >= 0) && return true
    throw(DomainError(s,"not a valid numeric argument"))
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
    if err != nothing
        length(x) != length(err.ylow) && (invalid = true)
        (!isempty(err.yhigh) && length(x) != length(err.yhigh)) && (invalid = true)
    end
    if fin != nothing
        lx = length(x)
        lx != length(fin.open) && (invalid = true)
        lx != length(fin.low) && (invalid = true)
        lx != length(fin.high) && (invalid = true)
        lx != length(fin.close) && (invalid = true)
    end

    invalid && throw(DimensionMismatch("input vectors must have the same number of elements."))

    return true

end

# Define argument synonyms
const synonyms = Dict(:title => [:title],
                      :xlabel => [:xlabel, :xl, :xlab],
                      :ylabel => [:ylabel, :yl, :ylab],
                      :zlabel => [:zlabel, :zl, :zlab],
                      :fillstyle => [:fillstyle, :fs],
                      :grid => [:grid],
                      :boxwidth => [:boxwidth, :bw],
                      :keyoptions => [:keyoptions, :ko],
                      :axis => [:axis],
                      :xtics => [:xtics, :xt],
                      :ytics => [:ytics, :yt],
                      :ztics => [:ztics, :zt],
                      :xrange => [:xrange, :xr],
                      :yrange => [:yrange, :yr],
                      :zrange => [:zrange, :zr],
                      :xzeroaxis => [:xzeroaxis, :xza],
                      :yzeroaxis => [:yzeroaxis, :yza],
                      :zzeroaxis => [:zzeroaxis, :zza],
                      :palette => [:palette],
                      :legend => [:legend, :leg],
                      :plotstyle => [:plotstyle, :ps],
                      :linecolor => [:linecolor, :lc],
                      :linewidth => [:linewidth, :lw],
                      :linestyle => [:linestyle, :ls],
                      :pointtype => [:pointtype, :pt, :marker, :mk],
                      :pointsize => [:pointsize, :ps, :markersize, :ms],
                      :fillcolor => [:fillcolor, :fc],
                      :view => [:view],
                      :font => [:font],
                      :size => [:size],
                      :background => [:background, :bg]
                     )

const syn_list = union(values(synonyms)...)

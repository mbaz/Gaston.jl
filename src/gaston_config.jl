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
default_config() = Dict(:mode => "normal",
                        :timeouts => Dict(:stdout_timeout => Sys.isunix() ? 6 : 20),
                        :debug => false,
                        :term => Dict(:terminal => "qt",
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
                                      :linetypes => "",
                                      :palette => "",
                                      :view => "",
                                      :onlyimpulses => false),
                        :curve => Dict(:plotstyle => "",
                                       :linecolor => "",
                                       :linewidth => "",
                                       :linestyle => "",
                                       :linetype  => "",
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
    if mode == "normal"
        terminal == "pdf" && (t = "pdfcairo")
        terminal == "pnf" && (t = "pnfcairo")
        terminal == "eps" && (t = "epscairo")
    end
    config[:term][:terminal] = t
    config[:mode] = mode

    for k in keys(kw)
        if k == :debug
            kw[k] isa Bool && (config[:debug] = kw[k]; continue)
            throw(DomainError("argument to debug must be Bool"))
        end
        if k == :stdout_timeout
            kw[k] isa Real && kw[k] > 0 && (config[:timeouts][k] = kw[k]; continue)
            throw(DomainError("timeout argument must be a positive number"))
        end
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

# Validate coordinates
# TODO: generalize to more plotstyles
function valid_coords(x,y,z;err=ErrorCoords(),fin=FinancialCoords())
    invalid = false
    if isempty(z)
        length(x) != length(y) && (invalid = true)
    end

    invalid && throw(DimensionMismatch("input vectors must have the same number of elements."))

    return true

end

# Define pointtype synonyms
const pointtypes = Dict("+" => 1,
                        "x" => 2,
                        "*" => 3,
                        "esquare" => 4,
                        "fsquare" => 5,
                        "ecircle" => 6,
                        "fcircle" => 7,
                        "etrianup" => 8,
                        "ftrianup" => 9,
                        "etriandn" => 10,
                        "ftriandn" => 11,
                        "edmd" => 12)

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
                      :linetype => [:linetype, :lt],
                      :pointtype => [:pointtype, :pt, :marker, :mk],
                      :pointsize => [:pointsize, :pz, :markersize, :ms],
                      :fillcolor => [:fillcolor, :fc],
                      :view => [:view],
                      :font => [:font],
                      :size => [:size],
                      :background => [:background, :bg],
                      :linetypes => [:linetypes]
                     )

const syn_list = union(values(synonyms)...)

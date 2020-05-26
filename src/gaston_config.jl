## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains configuration-related functions and types

# Dicts to store user-specified configuration
default_config() = Dict(:mode     => "normal",
                        :timeout  => Sys.isunix() ? 10 : 20,
                        :debug    => false,
                        :term     => "qt",
                        :termopts => "",
                        :preamble => "")

# Set any of Gaston's configuration variables
function set(;reset::Bool = false,
              term        = config[:term],
              termopts    = config[:termopts],
              mode        = config[:mode],
              debug::Bool = config[:debug],
              timeout     = config[:timeout],
              preamble    = config[:preamble]
            )
    global config

    if reset
        config = default_config()
        return nothing
    end

    config[:term] = term
    config[:termopts] = termopts
    config[:mode] = mode
    config[:timeout] = timeout
    config[:preamble] = preamble
    debug isa Bool && (config[:debug] = debug)

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

# Validate coordinates
# TODO: validate all possible cases
function valid_coords(x,y,z,supp)
    invalid = false
    if isempty(z)
        length(x) != length(y) && (invalid = true)
    end

    invalid && throw(DimensionMismatch("input vectors must have the same number of elements."))

    return true

end

# Define pointtype synonyms
function pointtypes(pt)
    pt == "dot" && return 0
    pt == "+" && return 1
    pt == "x" && return 2
    pt == "*" && return 3
    pt == "esquare" && return 4
    pt == "fsquare" && return 5
    pt == "ecircle" && return 6
    pt == "fcircle" && return 7
    pt == "etrianup" && return 8
    pt == "ftrianup" && return 9
    pt == "etriandn" && return 10
    pt == "ftriandn" && return 11
    pt == "edmd" && return 12
    pt == "fdmd" && return 13
    return "'$pt'"
end

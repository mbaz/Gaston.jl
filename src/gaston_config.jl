## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains configuration-related functions and types

# Dicts to store user-specified configuration
const default_config() = Dict(:mode      => "normal",
                              :timeout   => Sys.isunix() ? 10 : 20,
                              :debug     => false,
                              :term      => Sys.iswindows() ? "windows" : "qt",
                              :termopts  => "",
                              :preamble  => "",
                              :saveopts  => "",
                              :showable  => "png")

# Set any of Gaston's configuration variables
function set(;reset::Bool = false,
              term        = config[:term],
              termopts    = config[:termopts],
              mode        = config[:mode],
              debug::Bool = config[:debug],
              timeout     = config[:timeout],
              preamble    = config[:preamble],
              saveopts    = config[:saveopts],
              showable    = config[:showable]
            )
    global config

    if reset
        config = default_config()
        return nothing
    end

    config[:mode] = mode
    config[:timeout] = timeout
    debug isa Bool && (config[:debug] = debug)
    config[:term] = term
    config[:termopts] = termopts
    config[:preamble] = preamble
    config[:saveopts] = saveopts
    config[:showable] = showable

    return nothing
end

### Encode terminal capabilities
# supports multiple windows
const term_window = ["qt", "wxt", "x11", "aqua", "windows"]
# outputs text
const term_text = ["dumb", "sixelgd"]

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

## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

function set_terminal(term::String)
    global gaston_config

    if validate_terminal(term)
        gaston_config.terminal = term
    else
        error(string("Terminal type ", term, " not supported."))
    end
    return term
end

# For terminals that support file output, set the file name
function set_filename(s::String)
    global gaston_config

    gaston_config.outputfile = s
end

# Set default values for CurveConf and AxesConf. Return set value upon
# success, error out otherwise.
function set_default_legend(s::String)
    global gaston_config

    gaston_config.legend = s
end

function set_default_plotstyle(s::String)
    global gaston_config

    if validate_2d_plotstyle(s) || validate_3d_plotstyle(s) ||
        validate_image_plotstyle(s)
        gaston_config.plotstyle = s
    else
        error(string("Plotstyle ", s, " not supported."))
    end
end

function set_default_color(s::String)
    global gaston_config

    # We can't validate colors yet
    gaston_config.color = s
end

function set_default_marker(s::String)
    global gaston_config

    if validate_marker(s)
        gaston_config.marker = s
    else
        error(string("Marker ", s, " not supported."))
    end
end

function set_default_linewidth(i::Real)
    global gaston_config

    gaston_config.linewidth = i
end

function set_default_pointsize(i::Real)
    global gaston_config

    gaston_config.pointsize = i
end

function set_default_title(s::String)
    global gaston_config

    gaston_config.title = s
end

function set_default_xlabel(s::String)
    global gaston_config

    gaston_config.xlabel = s
end

function set_default_ylabel(s::String)
    global gaston_config

    gaston_config.ylabel = s
end

function set_default_zlabel(s::String)
    global gaston_config

    gaston_config.zlabel = s
end

function set_default_box(s::String)
    global gaston_config

    # We can't validate box yet
    gaston_config.box = s
end

function set_default_axis(s::String)
    global gaston_config

    if validate_axis(s)
        gaston_config.marker = s
    else
        error(string("Axis ", s, " not supported."))
    end
end

# functions to set print parameters
function set_print_color(s::String)
    global gaston_config

    gaston_config.print_color = b
end

function set_print_fontface(s::String)
    global gaston_config

    gaston_config.print_fontface = s
end

function set_print_fontsize(s::Real)
    global gaston_config

    gaston_config.print_fontsize = s
end

function set_print_fontscale(r::Real)
    global gaston_config

    gaston_config.print_fontscale = r
end

function set_print_linewidth(r::Real)
    global gaston_config

    gaston_config.print_linewidth = r
end

function set_print_size(s::String)
    global gaston_config

    gaston_config.print_size = s
end

## Copyright (c) 2012 Miguel Bazdresch
##
## Permission is hereby granted, free of charge, to any person obtaining a
## copy of this software and associated documentation files (the "Software"),
## to deal in the Software without restriction, including without limitation
## the rights to use, copy, modify, merge, publish, distribute, sublicense,
## and/or sell copies of the Software, and to permit persons to whom the
## Software is furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
## DEALINGS IN THE SOFTWARE.

# setter functions for write access to gaston_config

# Set terminal type.
# Returns new terminal name upon success, errors out otherwise.
function set_terminal(term::String)
    global gaston_config

    if validate_terminal(term)
        gaston_config.terminal = term
    else
        error(strcat("Terminal type ", term, " not supported."))
    end
    return term
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
        error(strcat("Plotstyle ", s, " not supported."))
    end
end

## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

function gnuplot_init()
    global gnuplot_state
    f = C_NULL
    try
        # Linux
        f = ccall(:popen, Ptr{Int}, (Ptr{Uint8},Ptr{Uint8}), "gnuplot" ,"w")
    catch
        # Windows
        f = ccall(:_popen, Ptr{Int}, (Ptr{Uint8},Ptr{Uint8}), "gnuplot" ,"w")
    end
    if f == C_NULL
        error("There was a problem starting up gnuplot.")
    end
    gnuplot_state.running = true
    gnuplot_state.fid = f
end

# close gnuplot pipe
function gnuplot_exit(x...)
    global gnuplot_state
    if gnuplot_state.running
        # close pipe
        err = 1
        try
            # Linux
            err = ccall(:pclose, Int, (Ptr{Int},), gnuplot_state.fid)
        catch
            # Windows
            err = ccall(:_pclose, Int, (Ptr{Int},), gnuplot_state.fid)
        end
        # err should be zero
        if err != 0
            println("Gnuplot may not have closed correctly.");
        end
    end
    # reset gnuplot_state
    gnuplot_state.running = false
    gnuplot_state.current = 0
    gnuplot_state.fid = 0
    gnuplot_state.figs = []
    return 0
end

# Return index to figure with handle 'c'. If no such figure exists, returns 0.
function findfigure(c)
    global gnuplot_state
    i = 0
    for j = 1:length(gnuplot_state.figs)
        if gnuplot_state.figs[j].handle == c
            i = j
            break
        end
    end
    return i
end

# convert marker string description to gnuplot's expected number
function pointtype(x::String)
    if x == "+"
        return 1
    elseif x == "x"
        return 2
    elseif x == "*"
        return 3
    elseif x == "esquare"
        return 4
    elseif x == "fsquare"
        return 5
    elseif x == "ecircle"
        return 6
    elseif x == "fcircle"
        return 7
    elseif x == "etrianup"
        return 8
    elseif x == "ftrianup"
        return 9
    elseif x == "etriandn"
        return 10
    elseif x == "ftriandn"
        return 11
    elseif x == "edmd"
        return 12
    elseif x == "fdmd"
        return 13
    end
    return 1
end

# return configuration string for a single plot
function linestr_single(conf::CurveConf)
    s = ""
    if conf.legend != ""
        s = string(s, " title '", conf.legend, "' ")
    else
        s = string(s, "notitle ")
    end
    s = string(s, " with ", conf.plotstyle, " ")
    if conf.color != ""
        s = string(s, "linecolor rgb '", conf.color, "' ")
    end
    s = string(s, "lw ", string(conf.linewidth), " ")
    # some plotstyles don't allow point specifiers
    cp = conf.plotstyle
    if cp != "lines" && cp != "impulses" && cp != "pm3d" && cp != "image" &&
        cp != "rgbimage" && cp != "boxes" && cp != "dots"
        if conf.marker != ""
            s = string(s, "pt ", string(pointtype(conf.marker)), " ")
        end
        s = string(s, "ps ", string(conf.pointsize), " ")
    end
    return s
end

# build a string with plot commands according to configuration
function linestr(curves::Vector{CurveData}, cmd::String, file::String)
    # We have to insert "," between plot commands. One easy way to do this
    # is create the first plot command, then the rest
    # We also need to keep track of the current index (starts at zero)
    index = 0
    s = string(cmd, " '", file, "' ", " i 0 ", linestr_single(curves[1].conf))
    if length(curves) > 1
        for i in curves[2:end]
            index += 1
            s = string(s, ", '", file, "' ", " i ", string(index)," ",
                linestr_single(i.conf))
        end
    end
    return s
end

# create a Z-coordinate matrix from x, y coordinates and a function
function meshgrid(x,y,f)
    Z = zeros(length(x),length(y))
    for k = 1:length(x)
        Z[k,:] = [ f(i,j) for i=x[k], j=y ]
    end
    return Z
end

# create x,y coordinates for a histogram, from a sample vector, using a number
# of bins
function histdata(s,bins)
    # When adding an element s to a bin, we use an iequality m < s <= M.
    # In order to account for elements s==m, we need to special-case
    # the computation for the first bin
    ms = minimum(s)
    Ms = maximum(s)
    bins = max(bins, 1)
    if Ms == ms
        # compute a "natural" scale
        g = (10.0^floor(log10(abs(ms)+eps()))) / 2
        ms, Ms = ms - g, ms + g
    end
    delta = (Ms-ms)/bins
    if VERSION < v"0.3-"
        x = Range(float(ms), delta, bins+1) # like ms:delta:Ms but less error-prone
    else
        x = ms:delta:Ms
    end
    y = zeros(bins)

    # this is special-cased because we want to include the minimum in the
    # first bin
    y[1] = sum(ms .<= s .<= x[2])
    for i in 2:length(x)-2
        y[i] = sum(x[i] .< s .<= x[i+1])
    end
    # this is special-cased because there is no guarantee that x[end] == Ms
    # (because of how ranges work)
    if length(y) > 1 y[end] = sum(x[end-1] .< s .<= Ms) end

    if bins != 1
        # We want the left bin to start at ms and the right bin to end at Ms
        if VERSION < v"0.3-"
            x = Range(ms+delta/2, delta, bins)
        else
            x = (ms+delta/2):delta:Ms
        end
    else
        # add two empty bins on the sides to provide a scale to gnuplot
        if VERSION < v"0.3-"
            x = Range(ms-delta/2, delta, 3)
        else
            x = (ms-delta/2):delta:(ms+delta/2)
        end
        y = [0.0, y[1], 0.0]
    end

    return x,y
end

# dereference CurveConf, by adding a method to copy()
function copy(conf::CurveConf)
    new = CurveConf()
    new.legend = conf.legend
    new.plotstyle = conf.plotstyle
    new.color = conf.color
    new.marker = conf.marker
    new.linewidth = conf.linewidth
    new.pointsize = conf.pointsize
    return new
end

# dereference AxesConf
function copy(conf::AxesConf)
    new = AxesConf()
    new.title = conf.title
    new.xlabel = conf.xlabel
    new.ylabel = conf.ylabel
    new.zlabel = conf.zlabel
    new.box = conf.box
    new.axis = conf.axis
    new.xrange = conf.xrange
    new.yrange = conf.yrange
    new.zrange = conf.zrange
    return new
end

# Build a "set term" string appropriate for the terminal type
function termstring(term::String)
    global gnuplot_state
    global gaston_config

    gc = gaston_config

    if is_term_screen(term)
        ts = "set term $term $(gnuplot_state.current)"
    else
        if term == "pdf"
            s = "set term pdfcairo $(gc.print_color) "
            s = "$s font \"$(gc.print_fontface),$(gc.print_fontsize)\" "
            s = "$s fontscale $(gc.print_fontscale) "
            s = "$s linewidth $(gc.print_linewidth) "
            s = "$s size $(gc.print_size)"
        elseif term == "eps"
            s = "set term epscairo $(gc.print_color) "
            s = "$s font \"$(gc.print_fontface),$(gc.print_fontsize)\" "
            s = "$s fontscale $(gc.print_fontscale) "
            s = "$s linewidth $(gc.print_linewidth) "
            s = "$s size $(gc.print_size)"
        elseif term == "png"
            s = "set term pngcairo $(gc.print_color) "
            s = "$s font \"$(gc.print_fontface),$(gc.print_fontsize)\" "
            s = "$s fontscale $(gc.print_fontscale) "
            s = "$s linewidth $(gc.print_linewidth) "
            s = "$s size $(gc.print_size)"
        elseif term == "gif"
            s = "set term gif "
            s = "$s font $(gc.print_fontface) $(gc.print_fontsize) "
            s = "$s fontscale $(gc.print_fontscale) "
            s = "$s linewidth $(gc.print_linewidth) "
            s = "$s size $(gc.print_size)"
        elseif term == "svg"
            s = "set term svg "
            s = "$s font \"$(gc.print_fontface),$(gc.print_fontsize)\" "
            s = "$s linewidth $(gc.print_linewidth) "
            s = "$s size $(gc.print_size)"
        end
        ts = "$s \nset output \"$(gc.outputfile)\""
    end
    return ts
end

# send gnuplot the current figure's configuration
function gnuplot_send_fig_config(config)
    # legend box
    if config.box != ""
        gnuplot_send(string("set key ",config.box))
    end
    # plot title
    if config.title != ""
        gnuplot_send(string("set title '",config.title,"' "))
    end
    # xlabel
    if config.xlabel != ""
        gnuplot_send(string("set xlabel '",config.xlabel,"' "))
    end
    # ylabel
    if config.ylabel != ""
        gnuplot_send(string("set ylabel '",config.ylabel,"' "))
    end
    # zlabel
    if config.zlabel != ""
        gnuplot_send(string("set zlabel '",config.zlabel,"' "))
    end
    # axis log scale
    if config.axis != "" || config.axis != "normal"
        if config.axis == "semilogx"
            gnuplot_send("set logscale x")
        end
        if config.axis == "semilogy"
            gnuplot_send("set logscale y")
        end
        if config.axis == "loglog"
            gnuplot_send("set logscale xy")
        end
    end
    # ranges
    gnuplot_send("set autoscale")
    if config.xrange != ""
        gnuplot_send(string("set xrange ",config.xrange))
    end
    if config.yrange != ""
        gnuplot_send(string("set yrange ",config.yrange))
    end
    if config.zrange != ""
        gnuplot_send(string("set zrange ",config.zrange))
    end
end

# Validation functions.
# These functions validate that configuration parameters are valid and
# supported. They return true iff the argument validates.

# Validate terminal type.
function validate_terminal(s::String)
    supp_terms = ["wxt", "x11", "svg", "gif", "png", "pdf", "aqua", "eps"]
    if s == "aqua" && OS_NAME != :Darwin
        return false
    end
    if in(s, supp_terms)
        return true
    end
    return false
end

# Identify terminal by type: file or screen
function is_term_screen(s::String)
    screenterms = ["wxt", "x11", "aqua"]
    if in(s, screenterms)
        return true
    end
    return false
end

function is_term_file(s::String)
    screenterms = ["svg", "gif", "png", "pdf", "eps"]
    if in(s, screenterms)
        return true
    end
    return false
end

# Valid plotstyles supported by gnuplot's plot
function validate_2d_plotstyle(s::String)
    valid = ["lines", "linespoints", "points", "impulses", "boxes",
        "errorlines", "errorbars", "dots"]
    if in(s, valid)
        return true
    end
    return false
end

# Valid plotstyles supported by gnuplot's splot
function validate_3d_plotstyle(s::String)
    valid = ["lines", "linespoints", "points", "impulses", "pm3d",
            "image", "rgbimage", "dots"]
    if in(s, valid)
        return true
    end
    return false
end

# Valid axis types
function validate_axis(s::String)
    valid = ["", "normal", "semilogx", "semilogy", "loglog"]
    if in(s, valid)
        return true
    end
    return false
end

# Valid markers supported by Gaston
function validate_marker(s::String)
    valid = ["", "+", "x", "*", "esquare", "fsquare", "ecircle", "fcircle",
    "etrianup", "ftrianup", "etriandn", "ftriandn", "edmd", "fdmd"]
    if in(s, valid)
        return true
    end
    return false
end

function validate_range(s::String)

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

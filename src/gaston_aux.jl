## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

# close gnuplot pipes
function gnuplot_exit(x...)
    for p in [gstdin, gstdout, gstderr]
        close(p)
    end
end

# Return index to figure with handle `c`. If no such figure exists, returns 0.
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

# remove a figure's data without closing it
function clearfigure(h::Int)
    global gnuplot_state

    f = findfigure(h)
    if f != 0
        gnuplot_state.figs[f] = Figure(h)
    end
end

# Return the next available handle (smallest non-used positive integer)
function nexthandle()
    isempty(gnuplot_state.figs) && return 1
    handles = [f.handle for f in gnuplot_state.figs]
    mh = maximum(handles)
    for i = 1:mh+1
        !in(i,handles) && return i
    end
end

# Push configuration, axes or curves to a figure. The handle is assumed valid.
function push_figure!(handle,args...)
    index = findfigure(handle)
    for c in args
        if isa(c,AxesConf)
            gnuplot_state.figs[index].conf = c
        elseif isa(c, Curve)
            if gnuplot_state.figs[index].isempty
                gnuplot_state.figs[index].curves = [c]
            else
                push!(gnuplot_state.figs[index].curves,c)
            end
            gnuplot_state.figs[index].isempty = false
        elseif isa(c, AbstractString)
            gnuplot_state.figs[index].gpcom = c
        end
    end
end

# convert marker string description to gnuplot's expected number
function pointtype(x::AbstractString)
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
function hist(s,bins)
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
    x = ms:delta:Ms
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
        x = (ms+delta/2):delta:Ms
    else
        # add two empty bins on the sides to provide a scale to gnuplot
        x = (ms-delta/2):delta:(ms+delta/2)
        y = [0.0, y[1], 0.0]
    end
    return x,y
end

function Base.show(io::IO, ::MIME"text/plain", x::Figure)
    if !isjupyter
        llplot()
        if gaston_config.terminal == "dumb" || gaston_config.terminal == "sixelgd"
            write(io, x.svg)
        end
        return nothing
    end
end

function Base.show(io::IO, ::MIME"image/svg+xml", x::Figure)
    llplot()
    write(io,x.svg)
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
    if conf.linestyle != ""
        s = string(s, "dt '", string(conf.linestyle), "' ")
    end
    # some plotstyles don't allow point specifiers
    cp = conf.plotstyle
    if cp != "lines" && cp != "impulses" && cp != "pm3d" && cp != "image" &&
        cp != "rgbimage" && cp != "boxes" && cp != "dots" && cp != "steps" &&
        cp != "fsteps" && cp != "fillsteps" && cp != "financebars"
        if conf.marker != ""
            s = string(s, "pt ", string(pointtype(conf.marker)), " ")
        end
        s = string(s, "ps ", string(conf.pointsize), " ")
    end
    return s
end

# build a string with plot commands according to configuration
function linestr(curves::Vector{Curve}, cmd::AbstractString, file::AbstractString)
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

# Build a "set term" string appropriate for the terminal type
function termstring()
    global gnuplot_state
    global gaston_config

    gc = gaston_config
    term = gaston_config.terminal
    termname = term
    term == "null" && (termname = "dumb")
    term == "ijulia" && (termname = "svg")
    term == "pdf" && (termname = "pdfcairo")
    term == "eps" && (termname = "epscairo")

    ts = "set term $termname "

    if term ∈ term_window
        ts = ts*string(gnuplot_state.current)*" "
    end

    if term ∈ term_sup_font
        ts = ts*" font \"$(gc.print_fontface),$(gc.print_fontsize)\" "
    end

    if term ∈ term_sup_fontscale
        ts = ts*" fontscale $(gc.print_fontscale) "
    end

    if term ∈ term_sup_lw
        ts = ts*" linewidth $(gc.print_linewidth) "
    end

    if term ∈ term_sup_size
        if gc.print_size == ""  # use appropriate default size
            term ∈ term_size_in && (size = gc.print_size_in)
            term ∈ term_size_pix && (size = gc.print_size_pix)
        else
            size = gc.print_size  # use user-provided size
        end
        ts = ts*" size $size "
    end

    if term ∈ term_file
        # verify that user has set an output file
        gc.outputfile == "" && error("Plotting to file, but no file name given. Use `set(outputfile=\"filename\")` to configure the output file name.")
        ts = ts*"\nset output \"$(gc.outputfile)\" "
    end

    return ts
end

# send gnuplot the current figure's configuration
function gnuplot_send_fig_config(config)
    # fill style
    if config.fill != ""
        gnuplot_send(string("set style fill ",config.fill))
    end
    # grid
    if config.grid != ""
        if config.grid == "on"
            gnuplot_send(string("set grid"))
        else
            gnuplot_send(string("unset grid"))
        end
    end
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

    if config.palette != ""
        gnuplot_send(string("set palette ",config.palette))
    end
end

# write commands to gnuplot's pipe
function gnuplot_send(s::AbstractString)
    w = write(gstdin, string(s,"\n"))
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(gstdin)
end

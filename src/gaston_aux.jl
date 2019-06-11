## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

# close a single figure, assuming arguments are valid; returns handle of
# the new current figure
function closesinglefigure(handle::Int)
    global gnuplot_state

    term = usr_term_cnf[:terminal]
    term ∈ term_window && gnuplot_send("set term $term $handle close")

    # remove figure from global state
    filter!(h->h.handle!=handle,gnuplot_state.figs)
    # update state
    if isempty(gnuplot_state.figs)
        # we just closed the last figure
        gnuplot_state.current = nothing
    else
        # select the most-recently created figure
        gnuplot_state.current = gnuplot_state.figs[end].handle
    end
    return gnuplot_state.current
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

# return array of existing handles
function gethandles()
    [f.handle for f in gnuplot_state.figs]
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
            gnuplot_state.figs[index].axes = c
        elseif isa(c, Curve)
            if gnuplot_state.figs[index].isempty
                gnuplot_state.figs[index].curves = [c]
            else
                push!(gnuplot_state.figs[index].curves,c)
            end
            gnuplot_state.figs[index].isempty = false
        elseif isa(c, String)
            gnuplot_state.figs[index].gpcom = c
        elseif isa(c, PrintConf)
            gnuplot_state.figs[index].print = c
        elseif isa(c, TermConf)
            gnuplot_state.figs[index].term = c
        end
    end
end

# convert marker string description to gnuplot's expected number
function pointtype(x::String)
    x == "+" && return "1"
    x == "x" && return "2"
    x == "*" && return "3"
    x == "esquare" && return "4"
    x == "fsquare" && return "5"
    x == "ecircle" && return "6"
    x == "fcircle" && return "7"
    x == "etrianup" && return "8"
    x == "ftrianup" && return "9"
    x == "etriandn" && return "10"
    x == "ftriandn" && return "11"
    x == "edmd" && return "12"
    x == "fdmd" && return "13"
    return "1"
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
    if !x.isempty
        if !isjupyter
            llplot(x)
            terminal = usr_term_cnf[:terminal]
            termvar = usr_term_cnf[:termvar]
            if (terminal ∈ term_text) || (termvar == "ijulia")
                write(io, x.svg)
            end
        end
    end
    return nothing
end

function Base.show(io::IO, ::MIME"image/svg+xml", x::Figure)
    llplot(x)
    write(io,x.svg)
    return nothing
end

# return configuration string for a single plot
function linestr_single(conf::CurveConf)
    s = ""
    conf.legend != "" && (s = s*" title '"*conf.legend*"' ")
    conf.plotstyle != "" && (s = s*" with "*conf.plotstyle*" ")
    conf.linecolor != "" && (s = s*"linecolor rgb '"*conf.linecolor*"' ")
    conf.linewidth != "" && (s = s*"lw "*conf.linewidth*" ")
    conf.linestyle != "" && (s = s*"dt '"*conf.linestyle*"' ")
    # some plotstyles don't allow point specifiers
    cp = conf.plotstyle
    if cp ∈ ps_sup_points
        if conf.pointtype != ""
            s = s*"pt "*pointtype(conf.pointtype)*" "
            conf.pointsize != "" && (s = s*"ps "*conf.pointsize*" ")
        end
    end
    return s
end

# build a string with plot commands according to configuration
function linestr(curves::Vector{Curve}, cmd, file)
    # We have to insert "," between plot commands. One easy way to do this
    # is create the first plot command, then the rest
    # We also need to keep track of the current index (starts at zero)
    index = 0
    s = cmd*" '"*file*"' "*" i 0 "*linestr_single(curves[1].conf)
    if length(curves) > 1
        for i in curves[2:end]
            index += 1
            s = s*", '"*file*"' "*" i "*string(index)*" "*linestr_single(i.conf)
        end
    end
    return s
end

# Build a "set term" string appropriate for the terminal type
function termstring(f::Figure)
    global gnuplot_state

    ac = f.axes
    tc = f.term
    pc = f.print

    term = pc.print_flag ?  pc.print_term : term = usr_term_cnf[:terminal]
    termvar = usr_term_cnf[:termvar]

    if term != ""
        # determine font, size, global linewidth and background
        font = pc.print_flag ? pc.print_font : tc.font
        size = pc.print_flag ? pc.print_size : tc.size
        background = pc.print_flag ? pc.print_background : tc.background
        linewidth = pc.print_flag ? pc.print_linewidth : tc.linewidth

        # build term string
        ts = "set term $term "
        term ∈ term_window && (ts = ts*string(gnuplot_state.current)*" ")
        term ∈ term_sup_font && (ts *= " font \""*font*"\" ")
        term ∈ term_sup_lw && (ts *= " linewidth "*linewidth*" ")
        term ∈ term_sup_size && (ts *= " size "*size*" ")
        term ∈ term_sup_bkgnd && (ts *= " background \""*background*"\" ")
        if !pc.print_flag
            to = usr_term_cnf[:termopts]
            to != "" && (ts *= to*" ")
        end

        if term ∈ term_file && termvar != "ijulia"
            ts = ts*"\nset output \"$(pc.print_outputfile)\" "
        end
    end
    return ts
end

# send gnuplot the current figure's configuration
function gnuplot_send_fig_config(config)
    config.title != "" && gnuplot_send("set title '"*config.title*"' ")
    config.fill != "" && gnuplot_send("set style fill "*config.fill)
    if config.grid != ""
        if config.grid == "on"
            gnuplot_send("set grid")
        else
            gnuplot_send("set grid "*config.grid)
        end
    end
    config.keyoptions != "" && gnuplot_send("set key "*config.keyoptions)
    if config.axis != ""
        config.axis == "semilogx" && gnuplot_send("set logscale x")
        config.axis == "semilogy" && gnuplot_send("set logscale y")
        config.axis == "semilogz" && gnuplot_send("set logscale z")
        config.axis == "loglog" && gnuplot_send("set logscale xyz")
    end
    config.xlabel != "" && gnuplot_send("set xlabel '"*config.xlabel*"' ")
    config.ylabel != "" && gnuplot_send("set ylabel '"*config.ylabel*"' ")
    config.zlabel != "" && gnuplot_send("set zlabel '"*config.zlabel*"' ")
    config.xrange != "" && gnuplot_send("set xrange "*config.xrange)
    config.yrange != "" && gnuplot_send("set yrange "*config.yrange)
    config.zrange != "" && gnuplot_send("set zrange "*config.zrange)
    if config.xzeroaxis != ""
        if config.xzeroaxis == "on"
            gnuplot_send("set xzeroaxis")
        else
            gnuplot_send("set xzeroaxis "*config.xzeroaxis)
        end
    end
    if config.yzeroaxis != ""
        if config.yzeroaxis == "on"
            gnuplot_send("set yzeroaxis")
        else
            gnuplot_send("set yzeroaxis "*config.yzeroaxis)
        end
    end
    if config.zzeroaxis != ""
        if config.zzeroaxis == "on"
            gnuplot_send("set zzeroaxis")
        else
            gnuplot_send("set zzeroaxis "*config.zzeroaxis)
        end
    end
    config.palette != "" && gnuplot_send("set palette "*config.palette)
end

# write commands to gnuplot's pipe
function gnuplot_send(s)
    #println(s)
    w = write(P.gstdin, string(s,"\n"))
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(P.gstdin)
end

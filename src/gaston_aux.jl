## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

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

""" mesgrid(x, y, z)

    Create a z-coordinate matrix from `x`, `y` coordinates and a function `f`,
    such that `z[row,col] = f(x[col], y[row)`"""
function meshgrid(x,y,f)
    z = zeros(length(y),length(x))
    for (yi,yy) in enumerate(y)
        for (xi,xx) in enumerate(x)
            z[yi,xi] = f(xx,yy)
        end
    end
    return z
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
    isempty(x) && return nothing
    IsJupyterOrJuno && return nothing
    llplot(x)
    if config[:mode] != "null"
        if (config[:term][:terminal] ∈ term_text) || (config[:mode] == "ijulia")
            write(io, x.svg)
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
    conf.legend != "" && (s *= " title '"*conf.legend*"' ")
    conf.plotstyle != "" && (s *= " with "*conf.plotstyle*" ")
    conf.linecolor != "" && (s *= "lc rgb '"*conf.linecolor*"' ")
    conf.linewidth != "" && (s *= "lw "*conf.linewidth*" ")
    conf.linestyle != "" && (s *= "dt '"*conf.linestyle*"' ")
    conf.fillstyle != "" && (s *= "fs "*conf.fillstyle*" ")
    conf.fillcolor != "" && (s *= "fc \""*conf.fillcolor*"\" ")
    # some plotstyles don't allow point specifiers
    if conf.plotstyle ∈ ps_sup_points
        if conf.pointtype != ""
            if conf.pointtype ∈ supported_pointtypes
                s = s*"pt "*pointtype(conf.pointtype)*" "
            else
                s = s*"pt \""*conf.pointtype*"\" "
            end
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
function termstring(f::Figure,print=false)
    global gnuplot_state

    ac = f.axes
    tc = f.term
    pc = f.print

    term = print ? pc.print_term : config[:term][:terminal]

    if term != ""
        # determine font, size, and background
        font = print ? pc.print_font : tc.font
        size = print ? pc.print_size : tc.size
        background = print ? pc.print_background : tc.background

        # build term string
        ts = "set term $term "
        term ∈ term_window && (ts = ts*string(gnuplot_state.current)*" ")

        isempty(font) ? s = "" : s = " font \""*font*"\" "
        term ∈ term_sup_font && (ts *= s)

        isempty(size) ? s = "" : s = " size "*size*" "
        term ∈ term_sup_size && (ts *= s)

        isempty(background) ? s = "" : s = " background \""*background*"\" "
        term ∈ term_sup_bkgnd && (ts *= s)

        # terminal options
        print || (ts *= config[:term][:termopts]*" ")
        print && (ts *= config[:print][:print_termopts]*" ")

        # set output file
        if term ∈ term_file
            s = ""
            isempty(ac.output) || (s = "\nset output \"$(ac.output)\" ")
            ts = ts*s
        end
    end
    return ts
end

# send gnuplot the current figure's configuration
function gnuplot_send_fig_config(config)
    config.title != "" && gnuplot_send("set title '"*config.title*"' ")
    config.fillstyle != "" && gnuplot_send("set style fill "*config.fillstyle)
    if config.grid != ""
        if config.grid == "on"
            gnuplot_send("set grid")
        else
            gnuplot_send("set grid "*config.grid)
        end
    end
    config.keyoptions != "" && gnuplot_send("set key "*config.keyoptions)
    config.boxwidth != "" && gnuplot_send("set boxwidth "*config.boxwidth)
    if config.axis != ""
        gnuplot_send("set "*config.axis)
    end
    config.xlabel != "" && gnuplot_send("set xlabel '"*config.xlabel*"' ")
    config.ylabel != "" && gnuplot_send("set ylabel '"*config.ylabel*"' ")
    config.zlabel != "" && gnuplot_send("set zlabel '"*config.zlabel*"' ")
    config.xrange != "" && gnuplot_send("set xrange "*config.xrange)
    config.yrange != "" && gnuplot_send("set yrange "*config.yrange)
    config.zrange != "" && gnuplot_send("set zrange "*config.zrange)
    config.xtics != "" && gnuplot_send("set xtics "*config.xtics)
    config.ytics != "" && gnuplot_send("set ytics "*config.ytics)
    config.ztics != "" && gnuplot_send("set ztics "*config.ztics)
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

# Calculating palettes is expensive, so store them in a cache. The cache is
# pre-populated with gnuplot's gray palette
Palette_cache = Dict{Symbol, String}(:gray => "gray")

# parse arguments
function parse(a, v)
    v isa AbstractString && return v
    # parse palette; code inspired by @gcalderone's Gnuplot.jl
    if a == :palette
        if v isa Symbol
            if haskey(Palette_cache, v)
                return Palette_cache[v]
            end
            cm = colorschemes[v]
            colors = Vector{String}()
            for i in range(0, 1, length = length(cm))
                c = get(cm, i)
                push!(colors, "$i $(c.r) $(c.g) $(c.b)")
            end
            s = "defined (" * join(colors, ", ") * ")\nset palette maxcolors $(length(cm))"
            push!(Palette_cache, (v => s))
            return s
        else
            return string(v)
        end
    # parse tics
    elseif a == :xtics || a == :ytics || a == :ztics
        if v isa AbstractRange
            return "$(first(v)),$(step(v)),$(last(v))"
        elseif v isa Tuple
            tics = v[1]
            labs = v[2]
            tics isa AbstractRange && (tics = collect(v[1]))
            s = """("$(labs[1])" $(tics[1])"""
            for i in 2:length(tics)
                s *= """, "$(labs[i])" $(tics[i])"""
            end
            s *= ")"
        end
    # parse axis type
    elseif a == :axis
        s = string(v)
        s == "semilogx" && return "logscale x"
        s == "semilogy" && return "logscale y"
        s == "semilogz" && return "logscale z"
        s == "loglog" && return "logscale xyz"
        return s
    #parse grid
    elseif a == :grid
        v in (true, :on, :true) && return "on"
        return ""
    # parse range
    elseif a == :xrange || a == :yrange || a == :zrange
        return "[$(ifelse(isinf(a[1]),*,a[1]))|$(ifelse(isinf(a[2]),*,a[2]))]"
    # parse zeroaxis
    elseif a == :xzeroaxis || a == :yzeroaxis || a == :zzeroaxis
        v in (true, :on, :true) && return "on"
        return ""
    else
        return string(v)
    end
end

# validate arguments
valid(tc::TermConf) = true
valid(ac::AxesConf) = true
valid(cc::CurveConf) = true
valid(x,y,z;err=[],fin=[]) = true

# write commands to gnuplot's pipe
function gnuplot_send(s)
    config[:debug] && println(s)  # print gnuplot commands if debug enabled
    w = write(P.gstdin, string(s,"\n"))
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(P.gstdin)
end

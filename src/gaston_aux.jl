## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

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

function Base.display(x::Figure)
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    if config[:term][:terminal] == "dumb"
        show(stdout, "text/plain", x)
        return
    end
    llplot(x)
end

function Base.show(io::IO, ::MIME"text/plain", x::Figure)
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="dumb", output=tmpfile)
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
end

function Base.show(io::IO, ::MIME"image/svg+xml", x::Figure)
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="svg", output=tmpfile)
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
end

function Base.show(io::IO, ::MIME"image/png", x::Figure)
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="png", output=tmpfile)
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
end

# return command string for a single curve
function plotstring_single(conf::CurveConf)
    s = ""
    conf.legend != "" && (s *= " title '"*conf.legend*"' ")
    conf.plotstyle != "" && (s *= " with "*conf.plotstyle*" ")
    if conf.linecolor != ""
        if conf.linecolor[1] == '{'
            s *= "lc "*conf.linecolor[2:end-1]*" "
        else
            s *= "lc '"*conf.linecolor*"' "
        end
    end
    conf.linewidth != "" && (s *= "lw "*conf.linewidth*" ")
    conf.linestyle != "" && (s *= "dt '"*conf.linestyle*"' ")
    conf.linetype != "" && (s *= "lt '"*conf.linetype*"' ")
    conf.fillstyle != "" && (s *= "fs "*conf.fillstyle*" ")
    conf.fillcolor != "" && (s *= "fc \""*conf.fillcolor*"\" ")
    if conf.pointtype != ""
        if conf.pointtype isa Real
            s *= "pt $(conf.pointtype) "
        else
            s *= "pt '$(conf.pointtype)' "
        end
    end
    conf.pointsize != "" && (s *= "ps "*conf.pointsize*" ")
    return s
end

# build a string with plot commands according to configuration
function plotstring(fig::Figure)
    curves = fig.curves
    file = fig.datafile
    # We have to insert "," between plot commands. One easy way to do this
    # is create the first plot command, then the rest
    # We also need to keep track of the current index (starts at zero)
    p = Vector{String}()
    for (i, curve) in enumerate(curves)
        push!(p, "'$file' i $(i-1) $(plotstring_single(curve.conf))")
    end
    cmd = "plot "
    fig.dims == 3 && (cmd = "splot")
    return cmd*join(p, ", ")
end

# Build a "set term" string appropriate for the terminal type
function termstring(f::Figure,print=false)
    global gnuplot_state

    tc = f.term
    pc = f.print

    term = print ? pc.term : config[:term][:terminal]

    if term != ""
        # determine font, size, and background
        font = print ? pc.font : tc.font
        size = print ? pc.size : tc.size
        background = print ? pc.background : tc.background

        # build term string
        ts = "set term $term "
        term ∈ term_window && (ts = ts*string(gnuplot_state.current)*" ")

        if print && (term in term_sup_lw)
            !isempty(pc.linewidth) && (ts *= " linewidth $(pc.linewidth) ")
        end

        isempty(font) ? s = "" : s = " font \""*font*"\" "
        term ∈ term_sup_font && (ts *= s)

        isempty(size) ? s = "" : s = " size "*size*" "
        term ∈ term_sup_size && (ts *= s)

        isempty(background) ? s = "" : s = " background \""*background*"\" "
        term ∈ term_sup_bkgnd && (ts *= s)

        # terminal options
        print || (ts *= config[:term][:termopts]*" ")
        print && (ts *= pc.termopts*" ")
    end
    return ts
end

# return a string with the `set` commands for the current figure
function figurestring(f::Figure)
    config = f.axes
    s = Vector{String}()
    config.title != "" && push!(s, "set title '"*config.title*"'")
    config.fillstyle != "" && push!(s, "set style fill "*config.fillstyle)
    if config.grid != ""
        if config.grid == "on"
            push!(s,"set grid")
        else
            push!(s,"set grid "*config.grid)
        end
    end
    config.keyoptions != "" && push!(s, "set key "*config.keyoptions)
    config.boxwidth != "" && push!(s, "set boxwidth "*config.boxwidth)
    config.axis != "" && push!(s, "set "*config.axis)
    config.xlabel != "" && push!(s, "set xlabel '"*config.xlabel*"'")
    config.ylabel != "" && push!(s, "set ylabel '"*config.ylabel*"'")
    config.zlabel != "" && push!(s, "set zlabel '"*config.zlabel*"'")
    config.xrange != "" && push!(s, "set xrange "*config.xrange)
    config.yrange != "" && push!(s, "set yrange "*config.yrange)
    config.zrange != "" && push!(s, "set zrange "*config.zrange)
    config.xtics != "" && push!(s, "set xtics "*config.xtics)
    config.ytics != "" && push!(s, "set ytics "*config.ytics)
    config.ztics != "" && push!(s, "set ztics "*config.ztics)
    config.linetypes != "" && push!(s,config.linetypes)
    if config.xzeroaxis != ""
        if config.xzeroaxis == "on"
            push!(s, "set xzeroaxis")
        else
            push!(s, "set xzeroaxis "*config.xzeroaxis)
        end
    end
    if config.yzeroaxis != ""
        if config.yzeroaxis == "on"
            push!(s, "set yzeroaxis")
        else
            push!(s, "set yzeroaxis "*config.yzeroaxis)
        end
    end
    if config.zzeroaxis != ""
        if config.xzeroaxis == "on"
            push!(s, "set zzeroaxis")
        else
            push!(s, "set zzeroaxis "*config.zzeroaxis)
        end
    end
    config.view != "" && push!(s, "set view "*config.view)
    config.palette != "" && push!(s, "set palette "*config.palette)
    return join(s, "\n")*"\n"
end

# Calculating palettes is expensive, so store them in a cache. The cache is
# pre-populated with gnuplot's gray palette
Palette_cache = Dict{Symbol, String}(:gray => "gray")

# Calculating linetypes from a colorscheme is expensive, so we use a cache.
Linetypes_cache = Dict{Symbol, String}()

# parse arguments
function parse(a, v)
    # parse palette; code inspired by @gcalderone's Gnuplot.jl
    if a == :palette
        if v isa Symbol
            haskey(Palette_cache, v) && return Palette_cache[v]
            cm = colorschemes[v]
            colors = Vector{String}()
            for i in range(0, 1, length=length(cm))
                c = get(cm, i)
                push!(colors, "$i $(c.r) $(c.g) $(c.b)")
            end
            s = "defined (" * join(colors, ", ") * ")\nset palette maxcolors $(length(cm))"
            push!(Palette_cache, (v => s))
            return s
        else
            return string(v)
        end
    # parse linetypes
    elseif a == :linetypes
        if v isa Symbol
            haskey(Linetypes_cache, v) && return Linetypes_cache[v]
            cm = colorschemes[v]
            linetypes = Vector{String}()
            for i in 1:length(cm)
                c = cm[i]
                s = join(string.( round.(Int, 255 .*(c.r, c.g, c.b)), base=16, pad=2))
                push!(linetypes, "set lt $i lc rgb '#$s'")
            end
            s = join(linetypes,"\n")*"\nset linetype cycle $(length(cm))"
            push!(Linetypes_cache, (v => s))
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
        else
            return string(v)
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
        if v isa Vector || v isa Tuple
            return "[$(ifelse(isinf(v[1]),*,v[1]))|$(ifelse(isinf(v[2]),*,v[2]))]"
        else
            return string(v)
        end
    # parse zeroaxis
    elseif a == :xzeroaxis || a == :yzeroaxis || a == :zzeroaxis
        v in (true, :on, :true) && return "on"
        return ""
    # parse view
    elseif a == :view
        v isa AbstractString && return v
        return join(v, ", ")
    # parse pointtype
    elseif a == :pointtype
        v isa Real && return v
        x = string(v)
        haskey(pointtypes, x) && return pointtypes[x]
        return x
    else
        return string(v)
    end
end

# write commands to gnuplot's pipe
function gnuplot_send(s)
    config[:debug] && println(s)  # print gnuplot commands if debug enabled
    w = write(P.gstdin, s*"\n")
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(P.gstdin)
end

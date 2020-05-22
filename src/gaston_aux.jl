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

### Debug mode
function debug(msg, f="")
    if config[:debug]
        s = split(msg, "\n", keepempty=false)
        if !isempty(s)
            if !isempty(f)
                printstyled("⌈Gaston in function $f\n", color=:yellow)
            else
                printstyled("⌈Gaston\n", color=:yellow)
            end
            for ss in s
                println("| $ss")
            end
            printstyled("⌊\n", color=:yellow)
        end
    end
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
    debug("Entering display()")
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    if config[:term] in term_text
        show(stdout, "text/plain", x)
        return nothing
    end
    llplot(x)
end

function Base.show(io::IO, ::MIME"text/plain", x::Figure)
    debug("Entering show() with MIME text/plain")
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="dumb", output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
end

function Base.show(io::IO, ::MIME"image/svg+xml", x::Figure)
    debug("Entering show() with MIME image/svg+xml")
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="svg", output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
end

function Base.show(io::IO, ::MIME"image/png", x::Figure)
    debug("Entering show() with MIME image/png")
    isempty(x) && return nothing
    if config[:mode] == "null"
        return nothing
    end
    tmpfile = tempname()
    save(term="png", output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    return
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
        push!(p, "'$file' i $(i-1) $(curve.conf)")
    end
    cmd = "plot "
    fig.dims == 3 && (cmd = "splot ")
    return cmd*join(p, ", ")
end

# Build a "set term" string appropriate for the terminal type
function termstring(f::Figure;term=config[:term],termopts=config[:termopts])
    global gnuplot_state

    # build termstring
    ts = "set term $term "
    term ∈ term_window && (ts = ts*string(f.handle)*" ")
    ts = ts*termopts
    return ts
end

# Calculating palettes is expensive, so store them in a cache. The cache is
# pre-populated with gnuplot's gray palette
Palette_cache = Dict{Symbol, String}(:gray => "set palette gray")

# Calculating linetypes from a colorscheme is expensive, so we use a cache.
Linetypes_cache = Dict{Symbol, String}()

# parse arguments
function parse(kwargs)
    kwargs = Dict(kwargs)
    # strings that will be returned
    figspec = String[]
    plotspec = String[]
    ### find plotspec keys.
    # the 'plotspec' argument overrides all other
    if :plotspec in keys(kwargs)
        plotspec = kwargs[:plotspec]
    else
        # These keys are processed first and in order.
        for kw in (:every, :e, :skip, :using, :u, :smooth, :bins, :volatile, :noautoscale)
            if kw in keys(kwargs)
                push!(plotspec, " $kw $(kwargs[kw]) ")
                pop!(kwargs, kw)
            end
        end
        # with or plotstyle
        val = pop!(kwargs, :with, pop!(kwargs, :w, pop!(kwargs, :plotstyle, pop!(kwargs, :ps, nothing))))
        if val != nothing
            push!(plotspec, " with $val ")
        end
        # linecolor
        val = pop!(kwargs, :linecolor, pop!(kwargs, :lc, nothing))
        if val != nothing
            if val isa Symbol
                push!(plotspec, " linecolor '$val' ")
            else
                push!(plotspec, " linecolor $val ")
            end
        end
        # pointtype
        val = pop!(kwargs, :pointtype, pop!(kwargs, :pt, nothing))
        if val != nothing
            if val isa String
                push!(plotspec, " pointtype $(pointtypes(val)) ")
            else
                push!(plotspec, " pointtype $val ")
            end
        end
        # other line settings
        for kw in (:ls, :linestyle, :lt, :linetype, :lw, :linewidth, :pz,
                   :pointsize, :fill, :fs, :fillcolor, :fc, :dashtype, :dt,
                   :pointinterval, :pi, :pointnumber, :pn)
            val = get(kwargs, kw, nothing)
            if val != nothing
                push!(plotspec, " $kw $val ")
                pop!(kwargs, kw)
            end
        end
        for kw in (:nohidden3d, :nocontours, :nosurface)
            val = get(kwargs, kw, nothing)
            if val in (true, :on, :true, "on", "true")
                push!(plotspec, " $kw ")
                pop!(kwargs, kw)
            end
        end
        # legend
        val = pop!(kwargs, :legend, pop!(kwargs, :leg, nothing))
        if val != nothing
            if val isa String
                push!(plotspec, " title $val ")
            else
                push!(plotspec, " title '$val'")
            end
        end
        # the rest
        for kw in (:ls, :linestyle, :lt, :linetype, :lw, :linewidth, :pz,
                   :pointsize, :fill, :fs, :fillcolor, :fc, :dashtype, :dt,
                   :pointinterval, :pi, :pointnumber, :pn)
            val = get(kwargs, kw, nothing)
            if val != nothing
                push!(plotspec, " $kw $val ")
                pop!(kwargs, kw)
            end
        end
    end
    ### find special figurespec keys
    # palette; code inspired by @gcalderone's Gnuplot.jl
    val = pop!(kwargs, :pal, pop!(kwargs, :palette, nothing))
    if val != nothing
        debug("found palette")
        val isa Vector || (val = [val])
        for v in val
            if v isa Symbol
                debug("palette is a symbol")
                if haskey(Palette_cache, v)
                    push!(figspec, Palette_cache[v])
                    continue
                end
                cm = colorschemes[v]
                colors = String[]
                for i in range(0, 1, length=length(cm))
                    c = get(cm, i)
                    push!(colors, "$i $(c.r) $(c.g) $(c.b)")
                end
                s = "set palette defined ("*join(colors, ", ")*")\nset palette maxcolors $(length(cm))"
                push!(Palette_cache, (v => s))
                push!(figspec, s)
            else
                push!(figspec, "set palette $v")
            end
        end
    end
    # linetype definitions; code inspired by @gcalderone's Gnuplot.jl
    val = pop!(kwargs, :linetypes, nothing)
    if val != nothing
        val isa Vector || (val = [val])
        for v in val
            if v isa Symbol
                if haskey(Linetypes_cache, v)
                    push!(figspec, Linetypes_cache[v])
                    continue
                end
                cm = colorschemes[v]
                linetypes = String[]
                for i in 1:length(cm)
                    c = cm[i]
                    s = join(string.( round.(Int, 255 .*(c.r, c.g, c.b)), base=16, pad=2))
                    push!(linetypes, "set lt $i lc rgb '#$s'")
                end
                s = join(linetypes,"\n")*"\nset linetype cycle $(length(cm))"
                push!(Linetypes_cache, (v => s))
                push!(figspec, s)
            else
                push!(figspec, "set linetype $v")
            end
        end
    end
    # tics
    for arg in (:xtics, :ytics, :ztics)
        val = get(kwargs, arg, nothing)
        if val != nothing
            val isa Vector || (val = [val])
            for v in val
                if v isa AbstractRange
                    push!(figspec,"set $arg $(first(v)),$(step(v)),$(last(v))")
                elseif v isa Tuple
                    tics = v[1]
                    labs = v[2]
                    tics isa AbstractRange && (tics = collect(v[1]))
                    s = """("$(labs[1])" $(tics[1])"""
                    for i in 2:length(tics)
                        s *= """, "$(labs[i])" $(tics[i])"""
                    end
                    s *= ")"
                    push!(figspec,"set $arg $s")
                else
                    push!(figspec,"set $arg $v")
                end
            end
            pop!(kwargs, arg)
        end
    end
    # axis type
    val = pop!(kwargs, :axis, nothing)
    if val != nothing
        s = string(val)
        s == "semilogx" && push!(figspec, "set logscale x")
        s == "semilogy" && push!(figspec, "set logscale y")
        s == "semilogz" && push!(figspec, "set logscale z")
        s == "loglog" && push!(figspec, "set logscale xyz")
    end
    # range
    for arg in (:xrange, :yrange, :zrange)
        val = pop!(kwargs, arg, nothing)
        if val != nothing
            if val isa Vector || val isa Tuple
                push!(figspec, "set $arg [$(ifelse(isinf(val[1]),*,val[1]))|$(ifelse(isinf(val[2]),*,val[2]))]")
            else
                push!(figspec, "set $arg $val")
            end
        end
    end
    # view
    val = pop!(kwargs, :view, nothing)
    if val != nothing
        if val isa AbstractString
            push!(figspec, "set view $val")
        else
            push!(figspec, "set view $(join(val, ", "))")
        end
    end
    # dashtypes
    val = pop!(kwargs, :dashtypes, nothing)
    if val != nothing
        if val isa String
            push!(figspec, "set dashtype '$val'")
        else
            push!(figspec, "set dashtype $val")
        end
    end
    ### iterate over remaining keys
    for a in keys(kwargs)
        arg = string(a)
        val = kwargs[a]
        # on/off arguments
        if val in (true, :on, :true, "on", "true")
            push!(figspec, "set $arg")
        else
            push!(figspec, "set $arg $val")
        end
    end
    return join(figspec, "\n"), join(plotspec, " ")
end

# write commands to gnuplot's pipe
function gnuplot_send(s)
    debug(s, "gnuplot_send")
    w = write(P.gstdin, s*"\n")
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(P.gstdin)
end

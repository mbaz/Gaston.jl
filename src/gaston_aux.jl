## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

""" meshgrid(x, y, z)

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
                printstyled("┌ Gaston in function $f\n", color=:yellow)
            else
                printstyled("┌ Gaston\n", color=:yellow)
            end
            for ss in s
                println("│ $ss")
            end
            printstyled("└\n", color=:yellow)
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
    if config[:term] in term_text
        show(stdout, "text/plain", x)
        return nothing
    end
    if config[:mode] == "null"
        return nothing
    end
    llplot(x)
end

Base.show(io::IO, ::MIME"text/plain", x::Figure) = show(io, x)

function Base.show(io::IO, x::Figure)
    debug("showable = $(config[:showable])\nmode = $(config[:mode])", "show():text/plain")

    isempty(x) && return nothing
    config[:mode] == "null" && return nothing
    gnuplot_state.gnuplot_available || return nothing
    config[:term] in term_text || return nothing

    tmpfile = tempname()
    save(term = config[:term], saveopts = config[:termopts], output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    nothing
end


function Base.show(io::IO, ::MIME"image/svg+xml", x::Figure)
    debug("showable = $(config[:showable])\nmode = $(config[:mode])", "show():image/svg+xml")

    isempty(x) && return nothing
    config[:mode] == "null" && return nothing
    gnuplot_state.gnuplot_available || return nothing

    tmpfile = tempname()
    save(term="svg", saveopts = config[:termopts], output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    nothing
end


function Base.show(io::IO, ::MIME"image/png", x::Figure)
    debug("showable = $(config[:showable])\nmode = $(config[:mode])", "show():image/png")

    isempty(x) && return nothing
    config[:mode] == "null" && return nothing
    gnuplot_state.gnuplot_available || return nothing

    tmpfile = tempname()
    save(term="png", saveopts = config[:termopts], output=tmpfile)
    while !isfile(tmpfile) end  # avoid race condition with read in next line
    write(io, read(tmpfile))
    rm(tmpfile, force=true)
    nothing
end

# build a string with plot commands according to configuration
function plotstring(sp::SubPlot)
    curves = sp.curves
    file = sp.datafile
    # We have to insert "," between plot commands. One easy way to do this
    # is create the first plot command, then the rest
    # We also need to keep track of the current index (starts at zero)
    p = Vector{String}()
    for (i, curve) in enumerate(curves)
        push!(p, "'$file' i $(i-1) $(curve.conf)")
    end
    cmd = "plot "
    sp.dims == 3 && (cmd = "splot ")
    return cmd*join(p, ", ")
end

# Build a "set term" string appropriate for the terminal type
function termstring(handle ; term=config[:term], termopts=config[:termopts])
    global gnuplot_state

    # build termstring
    ts = "set term $term "
    term ∈ term_window && (ts = ts*string(handle)*" ")
    ts = ts*termopts
    return ts
end

# Calculating palettes is expensive, so store them in a cache. The cache is
# pre-populated with gnuplot's gray palette
Palette_cache = Dict{Symbol, String}(:gray => "set palette gray")

# Calculating linetypes from a colorscheme is expensive, so we use a cache.
Linetypes_cache = Dict{Symbol, String}()

# Convert a symbol to string, converting all '_' to spaces and surrounding it with ' '
function symtostr(s)
    s isa Symbol || return s
    s = string(s)
    return "'$(join(split(s,"_")," "))'"
end

# parse plot configuration
function gparse(kwargs)
    # string that will be returned
    curveconf = String[]
    # the `curveconf` argument overrides all others
    if :curveconf in keys(kwargs)
        curveconf = [kwargs[:curveconf]]
    else
        K = keys(kwargs)
        ## These keys are processed first and in order.
        # Keys that take arguments.
        for kw in (:every, :e, :skip, :using, :u, :smooth, :bins)
            if kw in K
                push!(curveconf, " $kw $(kwargs[kw]) ")
                break
            end
        end
        # Keys that don't take arguments.
        if :noautoscale in keys(kwargs) && kwargs[:noautoscale] in (:on, :true, "on", "true")
            push!(curveconf, " noautoscale ")
        end
        # with or plotstyle
        for kw in (:with, :w, :plotstyle)
            if kw in K
                push!(curveconf, " with $(kwargs[kw]) ")
                break
            end
        end
        # pointtype
        for kw in (:pointtype, :pt, :marker)
            if kw in K
                val = kwargs[kw]
                if val isa String
                    push!(curveconf, " pointtype $(pointtypes(val)) ")
                elseif val isa Char
                    push!(curveconf, " pointtype '$val' ")
                else
                    push!(curveconf, " pointtype $val ")
                end
                break
            end
        end
        # pointsize
        for kw in (:pointsize, :ps, :markersize, :ms)
            if kw in K
                push!(curveconf, " pointsize $(kwargs[kw]) ")
            end
        end
        # other curveconf elements with arguments
        for kw in (:linecolor, :lc, :ls, :linestyle, :lt, :linetype, :lw,
                   :linewidth, :fill, :fs, :fillcolor, :fc, :dashtype, :dt,
                   :pointinterval, :pi, :pointnumber, :pn)
            if kw in K
                val = symtostr(kwargs[kw])
                push!(curveconf, " $kw $val ")
            end
        end
        # legend
        for kw in (:legend, :leg, :title, :t)
            if kw in K
                val = symtostr(kwargs[kw])
                push!(curveconf, " title $val ")
                break
            end
        end
        # elements with no arguments
        for kw in (:nohidden3d, :nocontours, :nosurface, :noautoscale)
            if kw in K
                if kwargs[kw] in (true, :on, :true, "on", "true")
                    push!(curveconf, " $kw ")
                end
            end
        end
    end
    return join(curveconf, " ")
end

function gparse(axes::Axes)
    axesconf = String[]
    K = keys(axes)
    for k in K
        # axesconf is a string with gnuplot commands
        if k == :axesconf
            push!(axesconf, axes[:axesconf])
            continue
        end
        # palette; code inspired by @gcalderone's Gnuplot.jl
        if k in (:pal, :palette)
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                if v isa Symbol
                    if haskey(Palette_cache, v)
                        push!(axesconf, Palette_cache[v])
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
                    push!(axesconf, s)
                else
                    push!(axesconf, "set palette $v")
                end
            end
            continue
        end
        # linetype definitions; code inspired by @gcalderone's Gnuplot.jl
        if k in (:lt, :linetype)
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                if v isa Symbol
                    if haskey(Linetypes_cache, v)
                        push!(axesconf, Linetypes_cache[v])
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
                    push!(axesconf, s)
                else
                    push!(axesconf, "set linetype $v")
                end
            end
            continue
        end
        # tics
        if k in (:xtics, :ytics, :ztics, :tics)
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                if v isa AbstractRange
                    push!(axesconf,"set $k $(first(v)),$(step(v)),$(last(v))")
                elseif v isa Tuple
                    tics = v[1]
                    labs = v[2]
                    tics isa AbstractRange && (tics = collect(tics))
                    println(tics)
                    s = """("$(labs[1])" $(tics[1])"""
                    for i in 2:length(tics)
                        s *= """, "$(labs[i])" $(tics[i])"""
                    end
                    s *= ")"
                    push!(axesconf,"set $k $s")
                elseif v in (:off, :false, false, "false")
                    push!(axesconf,"unset $k")
                else
                    push!(axesconf,"set $k $v")
                end
            end
            continue
        end
        # axis type
        if k == :axis
            val = symtostr(axes[k])
            if val == "semilogx"
                push!(axesconf, "set logscale x")
            elseif val == "semilogy"
                push!(axesconf, "set logscale y")
            elseif val == "semilogz"
                push!(axesconf, "set logscale z")
            elseif val == "loglog"
                push!(axesconf, "set logscale xyz")
            else
                push!(axesconf, "set $val")
            end
            continue
        end
        # range
        if k in (:xrange, :yrange, :zrange, :cbrange)
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                if v isa Vector || v isa Tuple
                    push!(axesconf, "set $k [$(ifelse(isinf(v[1]),*,v[1])):$(ifelse(isinf(v[2]),*,v[2]))]")
                else
                    push!(axesconf, "set $k $v")
                end
            end
            continue
        end
        # view
        if k == :view
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                if v isa Tuple
                    push!(axesconf, "set view $(join(v, ", "))")
                else
                    push!(axesconf, "set view $v")
                end
            end
            continue
        end
        # dashtypes
        if k in (:dt, :dashtype)
            val = axes[k]
            val isa Vector || (val = [val])
            for v in val
                push!(axesconf, "set dashtype $val")
            end
            continue
        end
        ### handle remaining keys
        val = axes[k]
        val isa Vector || (val = [val])
        for v in val
            # on/off arguments
            if v in (true, :on, :true, "on", "true")
                push!(axesconf, "set $k")
            elseif v in (false, :off, :false, "false")
                push!(axesconf, "unset $k")
            else
                push!(axesconf, "set $k $(symtostr(v))")
            end
        end
    end
    return join(axesconf, "\n")
end

# Define pointtype synonyms
const pt_syns = Dict("dot"      => 0,
                     "⋅"        => 0,
                     "+"        => 1,
                     "plus"     => 1,
                     "x"        => 2,
                     "*"        => 3,
                     "star"     => 3,
                     "esquare"  => 4,
                     "fsquare"  => 5,
                     "ecircle"  => 6,
                     "fcircle"  => 7,
                     "etrianup" => 8,
                     "ftrianup" => 9,
                     "etriandn" => 10,
                     "ftriandn" => 11,
                     "edmd"     => 12,
                     "fdmd"     => 13
                    )
const pt_syns_aqua = Dict("dot"      => 0,
                          "⋅"        => 0,
                          "+"        => 1,
                          "plus"     => 1,
                          "x"        => 2,
                          "*"        => 3,
                          "star"     => 3,
                          "esquare"  => 4,
                          "edmd"     => 5,
                          "etrianup" => 6
                         )
function pointtypes(pt)
    if config[:term] == "aqua"
        if pt in keys(pt_syns_aqua)
            return pt_syns_aqua[pt]
        end
    else
        if pt in keys(pt_syns)
            return pt_syns[pt]
        end
    end
    return "'$pt'"
end

# write commands to gnuplot's pipe
function gnuplot_send(s)
    debug(s, "gnuplot_send")
    if gnuplot_state.gnuplot_available
        w = write(P.gstdin, s*"\n")
        # check that data was accepted by the pipe
        if !(w > 0)
            @warn "Something went wrong writing to gnuplot STDIN."
            return
        end
        flush(P.gstdin)
    end
end

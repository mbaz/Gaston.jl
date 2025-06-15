# Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Auxiliary, non-exported functions are declared here.

"""
    Gaston.gp_start()::Base.Process

Returns a new gnuplot process.
"""
function gp_start()
    if state.enabled
        inp = Base.PipeEndpoint()
        out = Base.PipeEndpoint()
        err = Base.PipeEndpoint()
        process = run(config.exec, inp, out, err, wait=false)
        return process
    else
        @warn "gnuplot is not available on this system."
    end
end

"""
    Gaston.gp_quit(process::Base.Process)

End gnuplot process `process`. Returns the exit code."
"""
function gp_quit(process::Base.Process)
    if state.enabled
        if process_running(process)
            write(process, "exit gnuplot\n")
            close(process.in)
            wait(process)
        end
        return process.exitcode
    else
        @warn "gnuplot is not available on this system."
    end
end

"""
    Gaston.gp_quit(f::Figure)

End the gnuplot process associated with `f`. Returns the process exit code.
"""
gp_quit(f::Figure) = gp_quit(f.gp_proc)

"""
    gp_send(process::Base.Process, message::String)

Send string `message` to `process` and handle its response.
"""
function gp_send(process::Base.Process, message::String)
    if state.enabled
        if process_running(process)
            message *= "\n"
            write(process, message) # send user input to gnuplot

            @debug "String sent to gnuplot:" message

            # ask gnuplot to return sigils when it is done
            write(process, """set print '-'
                  print 'GastonDone'
                  set print
                  print 'GastonDone'
                  """)

            gpout = readuntil(process, "GastonDone\n", keep=true)
            gperr = readuntil(process.err, "GastonDone\n", keep=true)

            # handle errors
            gpout == "" && @warn "gnuplot crashed."

            gperr = gperr[1:end-11]
            gperr != "" && @info "gnuplot returned a message in STDERR:" gperr

            return gpout, gperr
        else
            @warn "Tried to send a message to a process that is not running"
            return nothing
        end
    else
        @warn "gnuplot is not available on this system."
    end
end

"""
    gp_send(f::Figure, message)

Send string `message` to the gnuplot process associated with `f` and handle its response.
"""
gp_send(f::Figure, message) = gp_send(f.gp_proc, message)

"""
    gp_exec(message::AbstractString)

Run an arbitrary gnuplot command and return gnuplot's stdout.
"""
function gp_exec(message::AbstractString)
    if state.enabled
        p = gp_start()
        (gpout, gperr) = gp_send(p, message)
        gp_quit(p)
        return gpout[1:end-11]
    else
        @warn "gnuplot is not available on this system."
    end
end

"""
    save(f::Figure = figure(); filename = nothing, term = "pngcairo font ',7'")::Nothing

Save figure `f` using the specified terminal `term` and `filename`.

If `filename` is not provided, the filename used is `"figure-handle.ext`, where
`handle = f.handle` and `ext` is given by the first three characters of the
current terminal.
"""
function save(f::Figure = figure() ; filename = nothing, term = "pngcairo font ',7'")
    # determine file name
    if isnothing(filename)
        # determine extension
        ext = split(term)[1]
        if length(ext) > 2
            ext = ext[1:3]
        end
        filename = "figure-$(f.handle)."*ext
    end
    producefigure(f ; filename, term)
    return nothing
end

"""
    save(handle; filename = nothing, term = "pngcairo font ',7'")::Nothing

Save the figure with the given handle.
"""
function save(handle ; kwargs...)
    f = figure(handle)
    save(f::Figure ; kwargs...)
end

"""
    Gaston.terminals()

Return a list of available gnuplot terminals"""
terminals() = print(gp_exec("set term"))

"Enable or disable debug mode."
function debug(flag)
    if flag
        ENV["JULIA_DEBUG"] = Gaston
    else
        ENV["JULIA_DEBUG"] = ""
    end
    return nothing
end

"Restore default configuration."
function reset()
    global config
    config.embedhtml = false
    config.output = :external
    config.term = ""
    config.exec = `gnuplot`
end

""" meshgrid(x, y, z)
    Return a z-coordinate matrix from `x`, `y` coordinates and a function `f`,
    such that `z[row,col] = f(x[row], y[col])`
"""
meshgrid(x, y, f::F) where {F<:Function} = [f(xx,yy) for yy in y, xx in x]

"""
    hist(s::Vector{T}, nbins=10, norm=false) where {T<:Real}

Return the histogram of values in `s` using `nbins` bins. If `normalize` is true,
the values of `s` are scaled so that `sum(s) == 1.0`.
"""
function hist(s ;
              edges        = nothing,
              nbins        = 10,
              norm::Bool   = false,
              mode::Symbol = :pdf)
    if edges === nothing
        # Unfortunately, `StatsBase.fit` regards `nbins` as a mere suggestion.
        # Therefore, we need to give it the actual edges.
        (ms, Ms) = extrema(s)
        if Ms == ms
            # compute a "natural" scale
            g = (10.0^floor(log10(abs(ms)+eps()))) / 2
            ms, Ms = ms - g, ms + g
        end
        edges = range(ms, Ms, length=nbins+1)
    end

    h = fit(Histogram, s, edges)
    norm && (h = normalize(h, mode=mode))

    @debug "hist():" nbins collect(edges) h.weights

    return h
end

# 2D histogram
function hist(s1, s2 ;
              edges          = nothing,
              nbins          = (10, 10),
              mode :: Symbol = :none)
    edg = edges
    if edges === nothing
        (ms1, Ms1) = extrema(s1)
        if Ms1 == ms1
            g = (10.0^floor(log10(abs(ms1)+eps()))) / 2
            ms1, Ms1 = ms1 - g, ms1 + g
        end
        edges1 = range(ms1, Ms1, length=nbins[1]+1)

        (ms2, Ms2) = extrema(s2)
        if Ms2 == ms2
            g = (10.0^floor(log10(abs(ms2)+eps()))) / 2
            ms2, Ms2 = ms2 - g, ms2 + g
        end
        edges2 = range(ms2, Ms2, length=nbins[2]+1)
        edg = (edges1, edges2)
    elseif !(edges isa Tuple)
        edg = (edges, edges)
    end

    h = fit(Histogram, (s1, s2), edg)
    h = normalize(h, mode = mode)

    @debug "hist():" nbins collect(edges) h.weights

    return h
end

function showable(::MIME{mime}, f::Figure) where {mime}
    rv = false
    if config.alttoggle
        t = split(config.altterm)[1]
    else
        t = split(config.term)[1]
    end
    h = config.embedhtml
    if (mime == Symbol("image/gif")) && (t == "gif")
        rv = true
    end
    if (mime == Symbol("image/webp")) && (t == "webp")
        rv = true
    end
    if (mime == Symbol("image/png")) && (t == "png" || t == "pngcairo")
        rv = true
    end
    if (mime == Symbol("image/svg+xml")) && (t == "svg")
        rv = true
    end
    if (mime == Symbol("text/html")) && (t == "svg" || t == "canvas") && h
        rv = true
    end
    @debug "showable():" mime config.term config.embedhtml t rv
    return rv
end

function show(io::IO, figax::FigureAxis)
    println(io, "Gaston.Axis with $(length(figax.f.axes)) ax(es),")
    println(io, "    stored in figure with handle ", figax.f.handle)
end

function show(io::IO, a::Axis)
    p = length(a) == 1 ? "plot" : "plots"
    println(io, "Gaston.Axis ($(a.is3d ? "3D" : "2D")) with $(length(a.plots)) $p")
end

function show(io::IO, p::Plot)
    println(io, "Gaston.Plot with plotline: \"$(p.plotline)\"")
end

function internal_show(io::IO, f::Figure)

    @debug "internal_show()" config.term config.output state.enabled

    # handle cases where no output is produced
    state.enabled || return nothing
    config.output == :null && return nothing

    # verify figure's gnuplot process is running
    if !process_running(f.gp_proc)
        error("gnuplot process associated with figure handle $(f.handle) has exited.")
    end

    if isempty(f)
        println(io, "Empty Gaston.Figure with handle ", f.handle)
        return nothing
    end

    # echo mode: save plot, read it and write to io
    if config.output == :echo
        @debug "Notebook plotting" config.term config.embedhtml
        tmpfile = tempname()
        producefigure(f, filename = tmpfile, term = config.term)
        while !isfile(tmpfile) end  # avoid race condition with read in next line
        if config.embedhtml
            println(io, "<html><body>")
        end
        write(io, read(tmpfile))
        if config.embedhtml
            println(io, "</body></html>")
        end
        rm(tmpfile, force=true)
    # external mode: create graphical window
    elseif config.output == :external
        producefigure(f)
    end

    return nothing
end

function producefigure(f::Figure ; filename::String = "", term = config.term)
    iob = IOBuffer()
    # Determine which terminal to use. Precedence order is:
    # * `config.altterm` if `config.alttoggle` (highest)
    # * function kw argument `term`
    # * default global value `config.term` (lowest)
    if config.alttoggle
        term = config.altterm
        config.alttoggle = false
    end
    if term isa Symbol
        term = String(term)
    end
    animterm = contains(term, "animate")  # this is an animation, not a multiplot

    # auto-calculate multiplot layout if mp_auto is true
    # note: here I'm trying to be clever, there may be undiscovered edge cases
    autolayout = ""
    if f.autolayout
        if length(f) <= 2
            rows = 1
            cols = length(f)
        elseif length(f) <= 4
            rows = 2
            cols = 2
        else
            cols = ceil(Int, sqrt(length(f)))
            rows = ceil(Int, length(f)/cols)
        end
        autolayout = " layout $rows, $cols "
    end

    write(iob, "reset session\n")

    # if term is different than config.term, push it, and pop it after plotting is done
    term != config.term && write(iob, "set term push\n")
    term != "" && write(iob, "set term $(term)\n")

    # if saving the plot
    filename != "" && write(iob, "set output '$(filename)'\n")

    # handle multiplot
    (length(f) > 1 && !animterm) && write(iob, "set multiplot " * autolayout * f.multiplot * "\n")
    for axis in f.axes
        if isempty(axis)
            if f.autolayout
                write(iob, "set multiplot next\n")
            end
            continue
        else
            write(iob, axis.settings*"\n")
            write(iob, plotstring(axis)*"\n") # send plotline
        end
    end
    (length(f) > 1 && !animterm) && write(iob, "unset multiplot\n")
    filename != "" && write(iob, "set output\n")
    term != config.term && write(iob, "set term pop\n")
    seekstart(iob)
    gp_send(f, String(read(iob)))
end

Base.show(io::IO, ::MIME"text/plain", x::Figure) = internal_show(io, x)
Base.show(io::IO, ::MIME"text/html", x::Figure) = internal_show(io, x)
Base.show(io::IO, ::MIME"image/png", x::Figure) = internal_show(io, x)
Base.show(io::IO, ::MIME"image/gif", x::Figure) = internal_show(io, x)
Base.show(io::IO, ::MIME"image/webp", x::Figure) = internal_show(io, x)
Base.show(io::IO, ::MIME"image/svg+xml", x::Figure) = internal_show(io, x)
Base.show(io::IO, x::Figure) = internal_show(io, x)

# build a string with plot commands according to configuration
function plotstring(a::Axis)
    # We have to insert "," between plot commands.
    pstring = Vector{String}()
    for p in a.plots
        push!(pstring, " '$(p.datafile)' " * p.plotline)
    end
    command = "plot "
    a.is3d && (command = "splot ")
    command * join(pstring, ", ")
end

# Calculating palettes is expensive, so store them in a cache. The cache is
# pre-populated with gnuplot's gray palette. The key is `(name, rev)`, where
# `name` is the palette name and `rev` is true if the palette is reversed.
Palette_cache = Dict{Tuple{Symbol, Bool}, String}((:gray, false) => "set palette gray")

# Calculating linetypes from a colorscheme is expensive, so we use a cache.
Linetypes_cache = Dict{Symbol, String}()

# Convert a symbol to string, converting all '_' to spaces and surrounding it with ' '
function symtostr(s)
    s isa Symbol || return s
    s = string(s)
    return "'$(join(split(s,"_")," "))'"
end

function strstr(s)
    s isa String || return s
    return "'$s'"
end

parse_settings(x) = x

function parse_settings(s::Vector{<:Pair})::String
    @debug "parse_settings" s
    # Initialize string that will be returned
    settings = String[]
    for (key::String, v) in s
        if v isa Bool
            v && push!(settings, "set $key")
            v || push!(settings, "unset $key")
        elseif key ∈ ("xtics", "ytics", "ztics", "tics")
            # tics
            if v isa AbstractRange
                push!(settings,"set $key $(first(v)),$(step(v)),$(last(v))")
            elseif v isa Tuple
                push!(settings, "set $key $v")
            elseif v isa NamedTuple
                ticstr = "("
                for i in eachindex(v.positions)
                    ticstr *= string("'", v.labels[i], "' ", v.positions[i], ", ")
                end
                ticstr *= ")"
                push!(settings,"set $key $ticstr")
            else
                push!(settings,"set $key $v")
            end
        elseif key ∈ ("xrange", "yrange", "zrange", "cbrange")
            # ranges
            if v isa Vector || v isa Tuple
                push!(settings, "set $key [$(ifelse(isinf(v[1]),*,v[1])):$(ifelse(isinf(v[2]),*,v[2]))]")
            else
                push!(settings, "set $key $v")
            end
        elseif key == "ranges"
            if v isa Vector || v isa Tuple
                r = "[$(ifelse(isinf(v[1]),*,v[1])):$(ifelse(isinf(v[2]),*,v[2]))]"
                push!(settings, "set xrange $r\nset yrange $r\nset zrange $r\nset cbrange $r")
            else
                push!(settings, "set xrange $v\nset yrange $v\nset zrange $v\nset cbrange $v")
            end
        elseif key ∈ ("pal", "palette")
            # palette; code inspired by @gcalderone's Gnuplot.jl
            rev = false
            if v isa Tuple
                if v[2] == :reverse
                    rev = true
                end
                v = v[1]
            end
            if v isa ColorScheme || v isa Symbol
                if v isa Symbol
                    if haskey(Palette_cache, (v, rev))
                        push!(settings, Palette_cache[(v, rev)])
                        continue
                    else
                        cm = colorschemes[v]
                    end
                else
                    cm = v
                end
                colors = String[]
                if rev
                    r = range(1, 0, length(cm))
                else
                    r = range(0, 1, length(cm))
                end
                for i in 1:length(cm)
                    c = get(cm, r[i])
                    push!(colors, "$i $(c.r) $(c.g) $(c.b)")
                end
                cols = join(colors, ", ")
                pal = "set palette defined (" * cols * ")\nset palette maxcolors $(length(cm))"
                if v isa Symbol
                    push!(Palette_cache, ((v, rev) => pal))
                end
                push!(settings, pal)
            else
                push!(settings, "set palette $v")
            end
        elseif key == "view"
            # view
            if v isa Tuple
                push!(settings, "set view $(join(v, ", "))")
            else
                push!(settings, "set view $v")
            end
        elseif key ∈ ("lt", "linetype")
            # linetype definitions; code inspired by @gcalderone's Gnuplot.jl
            if v isa Symbol
                if haskey(Linetypes_cache, v)
                    push!(settings, Linetypes_cache[v])
                else
                    cm = colorschemes[v]
                    linetypes = String[]
                    for i in 1:length(cm)
                        c = cm[i]
                        s = join(string.( round.(Int, 255 .*(c.r, c.g, c.b)), base=16, pad=2))
                        push!(linetypes, "set lt $i lc rgb '#$s'")
                    end
                    s = join(linetypes,"\n")*"\nset linetype cycle $(length(cm))"
                    push!(Linetypes_cache, (v => s))
                    push!(settings, s)
                end
            else
                push!(settings, "set linetype $v")
            end
        elseif key == "margins" && v isa Tuple
            # margin definitions using at screen: left, right, bottom top
            push!(settings, """set lmargin at screen $(v[1])
                  set rmargin at screen $(v[2])
                  set bmargin at screen $(v[3])
                  set tmargin at screen $(v[4])""")
        else
            push!(settings, "set $key $v")
        end
    end
    return join(settings, "\n")
end

# parse plot configuration
parse_plotline(x) = x

function parse_plotline(pl::Vector{<:Pair})::String
    @debug "parse_plotline()" pl
    # Initialize string that will be returned
    plotline = String[]
    count::Int = 0
    for (k, v) in pl
        # ensure that the same key does not appear later
        flag = true
        count += 1
        for z in pl[(count+1):end]
            if k == z[1]
                flag = false
                break
            end
        end
        if flag
            if v == true
                push!(plotline, k)
            else
                if k == "marker" || k == "pointtype" || k == "pt"
                    k = "pointtype"
                    if v isa Symbol
                        v = get(pointtypes, v, "'$v'")
                    end
                    @debug k v
                elseif k == "plotstyle"
                    k = "with"
                elseif k == "markersize" || k == "ms"
                    k = "pointsize"
                elseif k == "legend"
                    k = "title"
                end
                push!(plotline, k*" "*string(v))
            end
        end
    end
    return join(plotline, " ")
end

"""
    cs2dec(cs::ColorScheme)

Convert a colorsheme to a vector of integers, where each number corresponds to
each color in `cs`, expressed in base 10. Meant to be used with `lc rgb variable`.

This function accepts color schemes made up of `RGB` or `RGBA` values.
"""
function cs2dec(cs::ColorScheme)
    colors = cs.colors
    s = Int[]
    str(c) = string(c, base = 16, pad = 2)
    if colors[1] isa RGB
        # no alpha
        for c in colors
            push!(s, parse(Int, string(str(round(Int, 255*c.r)) *
                                       str(round(Int, 255*c.g)) *
                                       str(round(Int, 255*c.b))), base = 16))
        end
    else
        # alpha
        for c in colors
            push!(s, parse(Int, string(str(round(Int, 255*c.alpha)) *
                                       str(round(Int, 255*c.r)) *
                                       str(round(Int, 255*c.g)) *
                                       str(round(Int, 255*c.b))), base = 16))
        end
    end
    s
end

# Define pointtype synonyms
pointtypes = (dot      = 0,
              ⋅        = 0,
              +        = 1,
              plus     = 1,
              x        = 2,
              *        = 3,
              star     = 3,
              esquare  = 4,
              fsquare  = 5,
              ecircle  = 6,
              fcircle  = 7,
              etrianup = 8,
              ftrianup = 9,
              etriandn = 10,
              ftriandn = 11,
              edmd     = 12,
              fdmd     = 13,
             )

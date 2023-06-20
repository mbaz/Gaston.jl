## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.


"""
    plot(...) -> Gaston.Figure

Plot the coordinates provided in the arguments.

Arguments (in order from left to right):
* `f::Figure` (optional). If a figure `f` is given as argument, the plot will be
  created in the first axis of `f`.
* `a::Axis` (optional), usually provided as an indexed figure (for example `f[3]`).
  The plot will be created in `a`.
* Plot settings (optional, default ""). Settings may be provided as a string
  (for example, "set view 30,60") or as a list of options in brackets (for example,
  `{view = (30,60)}`, which requires using the `@gp` macro.
* The data to be plotted. Data may be provided as vectors, ranges, matrices,
  functions, etcetera.
* A "plotline" (optional, default "") specifiying the plot formatting. This may
  be a string or a list of options in brackets.

# Examples

* `plot(1:10) # The simplest plot`
* `@gp plot({title = "'test'"}, 1:10)  # Configure the axes`
* `@gp plot({title = "'test'"}, 1:10, "w p")  # plot points only`
* `plot(sin)  # plot the sine function from -10 to 10`
* `plot(0:0.01:1, sin) # plot the sine function from 0 to 1`

See also [plot!](@ref), [splot](@ref).

"""
function plot(args... ;
              handle          = state.activefig,
              is3d   ::Bool   = false,
              stheme ::Symbol = :none,
              ptheme ::Symbol = :none,
              kwargs...
             )::Figure
    @debug args

    ### 1. Determine figure to use
    (f, a, args) = whichfigaxis(handle, args...)
    empty!(a) # remove all previous curves in this axis
    @debug args

    ### 2. settings -- loop over all strings, symbols or Vector{Pairs} and join them
    (settings, args) = whichsettings(stheme, args...)
    @debug args

    ### 3. plotline -- look for the last arguments
    (plotline, args) = whichplotline(ptheme, args...)
    @debug args

    ### 4. Populate figure
    if is3d && applicable(convert_args3, args...)
        po = convert_args3(args... ; kwargs...)
    elseif applicable(convert_args, args...)
        po = convert_args(args...; kwargs...)
    end

    if (is3d && applicable(convert_args3, args...)) || (!is3d && applicable(convert_args, args...))
        f.multiplot = po.mp_settings
        for bundle in po.bundles
            if bundle.settings == ""
                st = settings
            elseif bundle.settings isa Symbol
                st = join((parse_settings(sthemes[bundle.settings]), settings), "\n")
            else
                st = join((bundle.settings, settings), "\n")
            end
            set!(a, st)
            for ts in bundle.series
                pl = plotline
                if ts.pl == ""
                    pl = plotline
                elseif ts.pl isa String
                    pl = ts.pl
                elseif ts.pl isa Symbol
                    pl = parse_plotline(pthemes[ts.pl])
                end
                push!(a, Plot(ts.ts..., pl; ts.is3d))
            end
            if length(po.bundles) > 1
                a = Axis()
                push!(f, a)
            end
        end
    else
        set!(a, settings)
        push!(a, Plot(args..., plotline; is3d))
    end

    return f
end

"""
    plot!(...) -> Figure

Similar to `plot`, but adds a new curve to an existing axis.

# Example

```plot(1:10)        # plot a curve
   plot!((1:10.^2))  # add a second curve```

See also [plot](@ref).
"""
function plot!(args... ; is3d = false, handle = state.activefig, ptheme = :none, kwargs...)::Figure
    (f, a, args) = whichfigaxis(handle, args...)
    # remove all arguments related to settings
    while args[1] isa String || args[1] isa Vector{Pair} || args[1] isa Symbol
        args = args[2:end]
    end
    (plotline, args) = whichplotline(ptheme, args...)

    if is3d && applicable(convert_args3, args...)
        po = convert_args3(args... ; kwargs...)
    elseif applicable(convert_args, args...)
        po = convert_args(args...; kwargs...)
    end

    if (is3d && applicable(convert_args3, args...)) || applicable(convert_args, args...)
        for bundle in po.bundles
            for ts in bundle.series
                pl = plotline
                if isempty(ts.pl)
                    pl = plotline
                elseif ts.pl isa String
                    pl = ts.pl
                elseif ts.pl isa Symbol
                    pl = parse_plotline(pthemes[ps.pl])
                else
                    pl = ""
                end
                push!(a, Plot(ts.ts..., pl; is3d))
            end
        end
    else
        push!(a, Plot(args..., plotline; is3d))
    end

    return f
end

struct DataTable
    data :: IOBuffer
end
function DataTable(vs::Vector{String})
    iob = IOBuffer()
    for l in vs
        write(iob, l*"\n")
    end
    DataTable(iob)
end

"Create and generate a table"
function plotwithtable(settings::String, args...)
    if applicable(convert_args3, args...)
        po = convert_args3(args...)
        x = po.bundles[1].series[1].ts[1]
        y = po.bundles[1].series[1].ts[2]
        z = po.bundles[1].series[1].ts[3]
    else
        x, y, z = args
    end
    tmpf = tempname()
    tblf = tempname()
    writedata(tmpf, x, y, z)
    s = "set term unknown\n" * settings * "\nset table '$tblf'\n" * "splot '$tmpf'\n" * "unset table\n"
    gp_exec(s)
    table = readlines(tblf)
    rm(tmpf)
    rm(tblf)
    return DataTable(table)
end

function whichfigaxis(handle, args...)
    if args[1] isa FigureAxis
        # plot(fig[1], ...)
        (; f, a) = args[1]
        args = Base.tail(args)
    elseif args[1] isa Figure
        # plot(fig, ...)
        f = args[1]
        a = f(1)
        args = Base.tail(args)
    else
        # neither a figure nor an axis were given as first argument
        handle ∈ gethandles() ? f = figure(handle) : f = Figure(handle)
        a = f(1)
        f.axes = [a]
    end
    (f, a, args)
end

function whichsettings(stheme, args...)
    _settings = String[]
    stheme != :none && push!(_settings, parse_settings(sthemes[stheme]))  # insert theme given as argument
    while true
        if args[1] isa String || args[1] isa Vector{Pair}
            push!(_settings, parse_settings(args[1]))
            args = Base.tail(args)
        elseif args[1] isa Symbol
            push!(_settings, parse_settings(sthemes[args[1]]))
            args = Base.tail(args)
        else
            break
        end
    end
    (join(_settings, "\n"), args)
end

function whichplotline(ptheme, args...)
    _plotline = String[]
    while true
        if args[end] isa String || args[end] isa Vector{Pair}
            pushfirst!(_plotline, parse_plotline(args[end]))
        elseif args[end] isa Symbol
            pushfirst!(_plotline, parse_plotline(pthemes[args[end]]))
        else
            break
        end
        args = Base.front(args)
    end
    ptheme != :none && pushfirst!(_plotline, parse_plotline(pthemes[ptheme]))  # insert theme given as argument
    (join(_plotline, " "), args)
end

"""
   splot(...) -> Figure

Similar to [plot](@ref), but creates a 3D plot.

# Example:

Plot an equation in the specified range:
`splot(-1:0.1:1, -1:0.1:1, (x,y)->sin(x)*cos(y))`

See also: [plot](@ref), [splot!](@ref).
"""
splot(args... ; kwargs...) = plot(args... ; kwargs..., is3d = true, handle = state.activefig)

"""
    splot!(...) -> Figure

Similar to [splot](@ref), but adds a new surface to an existing plot.
"""
splot!(args... ; kwargs...) = plot!(args... ; kwargs..., is3d = true, handle = state.activefig)

function animate(f::Figure, term = config.altterm)
    global config.alttoggle = true
    return f
end

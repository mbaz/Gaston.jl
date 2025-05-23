## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

"""
    plot([f::Figure,] [indexed figure,], [settings...,] data..., [plotline...,] [kwargs...])::Figure

Plot the provided data, returning a figure.

Arguments (in order from left to right):
* `f::Figure` (optional). If a figure `f` is given as argument, the figure is reset
  (all previous axes are removed), and the new plot is created in the first axis of `f`.
* An indexed figure (e.g. `f[3]`) (optional). The axis at the given index is cleared
  (or created if it does not exist), and the plot is added to it.
* Axis settings (optional, default `""`). See documentation for details on how to
  specify these settings.
* The data to be plotted. Data may be provided as vectors, ranges, matrices,
  functions, etcetera (see documentation).
* A plotline (optional, default `""`) specifiying the plot formatting. See
  documentation for details on how to specify these settings.

The figure to use for plotting may also be specified using the keyword argument
`handle`.  Other keyword arguments are passed to `convert_args`, documented
under [Recipes](reference.qmd#recipes).

# Examples

```{.julia}
plot(1:10) # A simple plot
plot("set title 'test'}, 1:10)  # Configure the axes
plot("set title 'test'}, 1:10, "w p")  # Configure the axes and plotline
plot(sin)  # plot the sine function from -10 to 10
plot(0:0.01:1, sin) # plot the sine function at the given time instants
```

See also `plot!` and `splot`.
"""
function plot(args... ;
              handle           = state.activefig,
              splot  :: Bool   = false,  # true if called by splot
              stheme :: Symbol = :none,
              ptheme :: Symbol = :none,
              kwargs...
             ) :: Figure
    @debug args

    ### 1. Determine figure and axis to use, and reset them as appropriate
    # if no index is provided, the whole figure is reset and the first axis is used
    (f, idx, args) = whichfigaxis(handle, args...)
    if ismissing(idx)
        reset!(f)
        idx = 1
    end
    @debug args

    ### 2. settings -- loop over all strings, symbols or Vector{Pairs} and join them
    (settings, args) = whichsettings(stheme, args...)
    @debug args

    ### 3. plotline -- look for the last arguments
    (plotline, args) = whichplotline(ptheme, args...)
    @debug args

    ### 4. Apply recipe to arguments, if one exists
    if splot && applicable(convert_args3, args...)
        po = convert_args3(args... ; kwargs...)
    elseif !splot && applicable(convert_args, args...)
        po = convert_args(args...; kwargs...)
    else
        try
            # if there is no conversion function, try to parse data directly
            po = Plot(args...)
        catch
            err = """Gaston does not know how to plot this. The data provided has the following type(s):
                  """
            for i in eachindex(args)
                err *= "           argument $i of type $(typeof(args[i]))\n"
            end
            error(err)
        end
    end

    ### 5. Build axis and place it in figure
    if po isa Plot
        ensure(f.axes, idx)
        if isempty(po.plotline)
            po.plotline = plotline
        elseif !isempty(plotline)
            po.plotline = join( (plotline, po.plotline, " ") )
        end
        if splot
            f.axes[idx] = Axis3(settings, po)
        else
            f.axes[idx] = Axis(settings, po)
        end
    elseif po isa Axis
        po.settings = po.settings * "\n" * settings
        if isempty(f)
            push!(f, po)
        else
            f.axes[idx] = po
        end
    elseif po isa NamedTuple
        f.axes = po.axes
        f.multiplot = po.multiplot
        f.autolayout = po.autolayout
    end

    return f
end

"""
    plot(f1::Figure, f2::Figure, ... ; kwargs...)::Figure

Return a new figure whose axes come from the figures provided in the arguments.
"""
plot #TODO

"""
    plot!(...)::Figure

Similar to `plot`, but adds a new curve to an axis. If the axis does not exist, it
is created. However, `plot!` does not support specification of the axis settings.

# Examples

```{.julia}
plot(1:10)        # plot a curve
plot!((1:10.^2))  # add a second curve
f = plot(sin)     # store new plot in f
plot!(f, cos)     # add second curve to plot
```

See documentation to `plot` for more details.
"""
function plot!(args... ; splot = false, handle = state.activefig, ptheme = :none, kwargs...)::Figure
    # determine figure and axis to use
    (f, idx, args) = whichfigaxis(handle, args...)
    if ismissing(idx)
        idx = 1
    end

    # parse plotline
    while args[1] isa String || args[1] isa Vector{Pair} || args[1] isa Symbol
        args = args[2:end]
    end
    (plotline, args) = whichplotline(ptheme, args...)

    # apply recipe if one exists
    if splot && applicable(convert_args3, args...)
        po = convert_args3(args... ; kwargs...)
    elseif !splot && applicable(convert_args, args...)
        po = convert_args(args...; kwargs...)
    else
        try
            # if there is no conversion function, try to parse data directly
            po = Plot(args...)
        catch
            err = """Gaston does not know how to plot this. The data provided has the following type(s):
                  """
            for i in eachindex(args)
                err *= "           argument $i of type $(typeof(args[i]))\n"
            end
            error(err)
        end
    end

    if po isa Plot
        ensure(f.axes, idx)
        # For flexibility, we want to allow splot! before any splot commands. We want to make sure
        # that, in this case, the axis is set to 3D.
        if splot
            f.axes[idx].is3d = true
        end
        if isempty(po.plotline)
            po.plotline = plotline
        elseif !isempty(plotline)
            po.plotline = join( (plotline, po.plotline, " ") )
        end
        push!(f.axes[idx], po)
    else
        error("Argument to plot! must be a single curve.")
    end

    return f
end

"""
    splot(...)::Figure

Similar to plot, but creates a 3D plot.

# Example

```{.julia}
splot(-1:0.1:1, -1:0.1:1, (x,y)->sin(x)*cos(y)) # Plot an equation in the specified range
```

See documentation to `plot` for more details.
"""
splot(args... ; kwargs...) = plot(args... ; splot = true, handle = state.activefig, kwargs...)

"""
    splot!(...) -> Figure

Similar to `splot`, but adds a new surface to an existing plot.

See documentation to `plot!` for more details.
"""
splot!(args... ; kwargs...) = plot!(args... ; splot = true, handle = state.activefig, kwargs...)

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

"""
    plotwithtable(settings, args... ; splot = true)

Create and generate a table. 3D is assumend, so `splot` default to `true`.
"""
function plotwithtable(settings::String, args... ; splot = true)
    if applicable(convert_args3, args...)
        po = convert_args3(args...)
        tmpf = po.datafile
    elseif applicable(convert_args, args...)
        po = convert_args(args...)
        tmpf = po.datafile
    else
        tmpf = tempname()
        writedata(tmpf, args...)
    end
    tblf = tempname()
    cmd = splot ? "splot" : "plot"
    s = "set term unknown\n" * settings * "\nset table '$tblf'\n" * "$cmd '$tmpf'\n" * "unset table\n"
    gp_exec(s)
    table = readlines(tblf)
    rm(tmpf)
    rm(tblf)
    return DataTable(table)
end

"""
    whichfigaxis(handle, args...)

Return a figure and an index into its axes.

Provided arguments may be:
* f::Figure. Returns (f, missing, remaining args)
* f::FigureAxis. Returns (f, index, true, remaining args)
* Else, returns (f, missing, remaining args)
"""
function whichfigaxis(handle, args...)
    index_provided = false
    if args[1] isa FigureAxis
        # plot(fig[1], ...)
        (; f, idx) = args[1]
        args = Base.tail(args)
    elseif args[1] isa Figure
        # plot(fig, ...)
        f = args[1]
        idx = missing
        args = Base.tail(args)
    else
        # neither a figure nor an axis were given as first argument
        if handle ∈ gethandles()
            f = figure(handle)
        else
            f = Figure(handle)
        end
        idx = missing
    end
    (f, idx, args)
end

"""
    whichsettings(stheme, args...)

Return a settings string.
"""
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

"""
    whichplotline(stheme, args...)

Return a plotline string.
"""
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
    animate(f::Figure, term = config.altterm)

Render an animated plot in notebooks such as Pluto and Jupyter.

This function is meant to be used to render an animation within a notebook environment.
Normally, all plots are rendered in a terminal such as `png`. However, rendering an
animation requires switching to `gif`, `webp` or other terminal that supports animations.
Changing the global terminal configuration wil cause all other plots in the notebook to
be re-rendered with the wrong terminal. This function allows changing the terminal
on a plot-by-plot basis, without changing the global terminal configuration.
"""
function animate(f::Figure, term = config.altterm)
    global config.alttoggle = true
    global config.altterm = term
    return f
end

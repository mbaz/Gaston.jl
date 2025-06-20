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
    settings = Union{Vector{<:Pair},AbstractString}[sthemes[stheme]]
    while true
        if args[1] isa AbstractString || args[1] isa Vector{<:Pair}
            push!(settings, args[1])
            args = Base.tail(args)
        elseif args[1] isa Symbol
            push!(settings, sthemes[args[1]])
            args = Base.tail(args)
        else
            break
        end
    end
    @debug args

    ### 3. plotline -- check arguments from last to first
    plotline = Union{Vector{<:Pair}, AbstractString}[pthemes[ptheme]]
    while true
        if args[end] isa AbstractString || args[end] isa Vector{<:Pair}
            insert!(plotline, 2, args[end])
            args = Base.front(args)
        elseif args[end] isa Symbol
            insert!(plotline, 2, pthemes[args[end]])
            args = Base.front(args)
        else
            break
        end
    end
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
            err = "Gaston does not know how to plot this.\n" *
                  "The data provided has the following type(s):\n"
            for i in eachindex(args)
                err *= "    argument $i of type $(typeof(args[i]))\n"
            end
            error(err)
        end
    end

    ### 5. Build axis and place it in figure
    if po isa Plot
        ensure(f.axes, idx)
        push!(plotline, po.plotline)
        po.plotline = merge_plotline(plotline)
        setts = merge_settings(settings)
        f.axes[idx] = Axis(setts, [po], splot)
    elseif po isa PlotRecipe
        ensure(f.axes, idx)
        push!(plotline, po.plotline)
        pl = merge_plotline(plotline)
        setts = merge_settings(settings)
        f.axes[idx] = Axis(setts, [Plot(po.data..., pl)], splot)
    elseif po isa AxisRecipe
        push!(settings, po.settings)
        setts = merge_settings(settings)
        P = Plot[]
        for p in po.plots
            push!(P, Plot(p.data..., parse_plotline(p.plotline)))
        end
        a = Axis(setts, P, po.is3d)
        if isempty(f)
            push!(f, a)
        else
            f.axes[idx] = a
        end
    elseif po isa FigureRecipe
        A = Axis[]
        for a in po.axes
            P = Plot[]
            for p in a.plots
                push!(P, Plot(p.data..., parse_plotline(p.plotline)))
            end
            push!(A, Axis(parse_settings(a.settings), P, a.is3d))
        end
        f.axes = A
        f.multiplot = po.multiplot
        f.autolayout = po.autolayout
    end
    return f
end

"""
    plot(f1::Figure, f2::Figure,... ; multiplot = "", autolayout = false, kwargs...)::Figure

Return a new figure whose axes come from the figures provided in the arguments.
"""
function plot(fs::Figure...; multiplot = "", autolayout = true, kwargs...)
    f = Figure(;multiplot, autolayout)
    for fig in fs
        for ax in fig.axes
            push!(f, ax)
        end
    end
    f
end

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

    # remove stray settings
    while true
        if args[1] isa AbstractString || args[1] isa Vector{<:Pair} || args[1] isa Symbol
            args = Base.tail(args)
        else
            break
        end
    end

    # parse plotline
    plotline = Union{Vector{<:Pair}, AbstractString}[pthemes[ptheme]]
    while true
        if args[end] isa AbstractString || args[end] isa Vector{<:Pair}
            insert!(plotline, 2, args[end])
            args = Base.front(args)
        elseif args[end] isa Symbol
            insert!(plotline, 2, pthemes[args[end]])
            args = Base.front(args)
        else
            break
        end
    end

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
            err = "Gaston does not know how to plot this.\n" *
                  "The data provided has the following type(s):\n"
            for i in eachindex(args)
                err *= "    argument $i of type $(typeof(args[i]))\n"
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
        push!(plotline, po.plotline)
        po.plotline = merge_plotline(plotline)
        push!(f.axes[idx], po)
    elseif po isa PlotRecipe
        ensure(f.axes, idx)
        splot && (f.axes[idx].is3d = true)
        push!(plotline, po.plotline)
        pl = merge_plotline(plotline)
        push!(f.axes[idx], Plot(po.data..., pl))
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

"Create a DataTable from a vector of strings"
function DataTable(vs::Vector{<:AbstractString}...)
    iob = IOBuffer()
    for block in vs
        for l in block
            write(iob, l*"\n")
        end
        write(iob, "\n")
    end
    DataTable(iob)
end

"Create a DataTable from a tuple of strings"
function DataTable(ts::T) where T <: Tuple
    iob = IOBuffer()
    for l in ts
        write(iob, l*"\n")
    end
    DataTable(iob)
end

"Create a DataTable from matrices. Each matrix is a datablock, which are separated by spaces."
function DataTable(args::Matrix...)
    length(args)
    iob = IOBuffer()
    for m in args
        for r in eachrow(m)
            write(iob, join(r, " "))
            write(iob, "\n")
        end
        write(iob, "\n")
    end
    DataTable(iob)
end

"""
    plotwithtable(settings, args... ; splot = true)

Create and generate a table. 3D is assumed, so `splot` defaults to `true`.
"""
function plotwithtable(settings::AbstractString, args... ; splot = true)
    if applicable(convert_args3, args...)
        po = convert_args3(args...)
        tmpf = tempname()
        writedata(tmpf, po.data...)
    elseif applicable(convert_args, args...)
        po = convert_args(args...)
        tmpf = tempname()
        writedata(tmpf, po.data...)
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

Provided arguments and return values may be:
* f::Figure. Returns (f, missing, remaining args)
* f::FigureAxis. Returns (f, index, remaining args)
* else, returns:
  * (f(handle), missing, remaining args) if f(handle) exists
  * (Figure(handle), missing, remaining args) if it does not
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

function merge_settings(s)
    ans = ""
    for a in s
        if !isempty(a)
            if a isa AbstractString
                !isempty(ans) && (ans *= '\n')
                ans *= a
            else
                !isempty(ans) && (ans *= '\n')
                ans *= parse_settings(a)
            end
        end
    end
    return ans
end

function merge_plotline(p)
    ans = ""
    for a in p
        if !isempty(a)
            if a isa AbstractString
                !isempty(ans) && (ans *= ' ')
                ans *= a
            else
                !isempty(ans) && (ans *= ' ')
                ans *= parse_plotline(a)
            end
        end
    end
    return ans
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

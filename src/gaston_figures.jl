## Copyright (c) 2013-2021 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Code related to figures.

"""
    Gaston.Plot(datafile::String, plotline::String)

Type that stores the data needed to plot a curve.

    Gaston.Plot(args..., plotline = "")

Construct a new Plot. The curve data (for instance, `x` and `y` coordinates) are
provided first. The curve plotline is the last argument.
"""
mutable struct Plot
    const datafile :: String
    plotline       :: String

    function Plot(args...)
        if isempty(args) || all(i -> isa(i, Union{String, Vector{<:Pair}}), args)
            throw(ArgumentError("No plot data provided."))
        end
        if args[end] isa String
            plotline = args[end]
            args = args[1:end-1]
        elseif args[end] isa Vector{<:Pair}
            plotline = parse_plotline(args[end])
            args = args[1:end-1]
        else
            plotline = ""
        end
        datafile = tempname()
        writedata(datafile, args...)
        new(datafile, plotline)
    end
end

"""
    Gaston.Plot!(P, args...)::Nothing

Update existing plot `P` with provided `args`.

The existing data file is overwritten; no new data file is created. A quick
benchmark shows that this has no advantage over creating new Plots; however,
in some cases avoiding the creation of lots of small files might be desired.
"""
function Plot!(P::Plot, args...)
    if isempty(args)
        return P
    end
    if args[end] isa String
        plotline = args[end]
        args = args[1:end-1]
    elseif args[end] isa Vector{<:Pair}
        plotline = parse_plotline(args[end])
        args = args[1:end-1]
    else
        plotline = P.plotline
    end
    datafile = P.datafile
    writedata(datafile, args...)
    P.plotline = plotline
    return nothing
end

"""
    Axis(settings::String           = "",
         plots::Vector{Gaston.Plot} = Gaston.Plot[],
         is3d::Bool                 = false)

Type that stores the data required to create a 2-D or 3-D axis.

The constructor takes the following arguments:

* `settings`: stores the axis settings.
* `plots`: a vector of Plot, one per curve.
* `is3d`: determines if axis is generated with `plot` or `splot`.
"""
mutable struct Axis
    settings :: String         # axis settings
    plots    :: Vector{Plot}   # one Plot per curve in the axis
    is3d     :: Bool           # if true, 'splot' is used; otherwise, 'plot' is used
end

# Axis constructors
Axis(x, y) = Axis(x, y, false)
Axis3(x, y) = Axis(x, y, true)

Axis() = Axis("", Plot[])
Axis3() = Axis3("", Plot[])

Axis(p::Plot) = Axis("", [p])
Axis3(p::Plot) = Axis3("", [p])

Axis(s::String) = Axis(s, Plot[])
Axis3(s::String) = Axis3(s, Plot[])

Axis(s::String, p::Plot) = Axis(s, [p])
Axis3(s::String, p::Plot) = Axis3(s, [p])

Axis(s::Vector{T}) where T <: Pair = Axis(parse_settings(s), Plot[])
Axis3(s::Vector{T}) where T <: Pair = Axis3(parse_settings(s), Plot[])

Axis(s::Vector{T}, p::Plot) where T <: Pair = Axis(parse_settings(s), [p])
Axis3(s::Vector{T}, p::Plot) where T <: Pair = Axis3(parse_settings(s), [p])

Axis(s::Vector{T}, p::Vector{Plot}) where T <: Pair = Axis(parse_settings(s), p)
Axis3(s::Vector{T}, p::Vector{Plot}) where T <: Pair = Axis3(parse_settings(s), p)

# Figures

"""
    Figure

Type that stores a figure. It has the following fields:

* `handle`: the figure's unique identifier (it may be of any type).
* `gp_proc`: the gnuplot process associated with the figure (type `Base.Process`).
* `axes`: a vector of `Gaston.Axis`.
* `multiplot`: a string with arguments to `set multiplot`.
* `autolayout`: `true` if Gaston should handle the figure's layout (`Bool`).
"""
mutable struct Figure <: AbstractFigure
    handle
    gp_proc    :: Base.Process
    axes       :: Vector{Axis}
    multiplot  :: String
    autolayout :: Bool
end

"""
    Figure(h = nothing, autolayout = true, multiplot = "")::Figure

Return an empty a figure with given handle. If `h === nothing`, automatically
assign the next available numerical handle. A new gnuplot process is started
and associated with the new figure, which becomes the active figure.

If the handle provided already exists, an error is thrown.

# Examples

```{.julia}
fig = Figure()   # new figure with next available numerical handle
fig = Figure(5)  # new figure with handle 5 (if it was available)
fig = Figure(multiplot = "'title 'test'") # new figure with multiplot settings
```
"""
function Figure(handle = nothing ; autolayout = true, multiplot = "")
    global state
    handle === nothing && (handle = nexthandle())
    if handle ∈ gethandles()
        error("Figure with given handle already exists. Handle: ", handle)
    else
        f = finalizer(finalize_figure, Figure(handle, gp_start(), Axis[], multiplot, autolayout))
        push!(state.figures.figs, f)
        state.activefig = handle
    end
    @debug "Returning figure with handle: " handle
    return f
end

"""
    Gaston.FigureAxis

When indexing a figure, a FigureAxis is returned. It contains the figure
itself along with the index.

This is required because `plot(figure[index])` modifies the axis at
`figure.axis[index]`, but it must return `figure`.
"""
struct FigureAxis
    f   :: Figure
    idx :: Int
end

"""
    (f::Figure)(index)::Gaston.Axis

Return the axis stored at the specified index. If the axis does not exist, an
empty axis is created.
"""
function (f::Figure)(idx)::Axis
    ensure(f.axes, idx)
    return f.axes[idx]
end

function finalize_figure(f::Figure)
    #@async @info "Finalizing figure with handle $(f.handle)."
    for i in eachindex(f.axes)
        empty!(f(i))
    end
    @async gp_quit(f)
end

# functions to push stuff into figures/axis/plots

"""
    push!(a::Axis, p::Plot)

Push plot (curve) `p` into axis `a`.
"""
function push!(a::Axis, p::Plot)
    push!(a.plots, p)
    return a
end

"""
    push!(f::Figure, a::Axis)

Push axis `a` into figure `f`.
"""
function push!(f::Figure, a::Axis)
    push!(f.axes, a)
    return f
end

"""
    push!(f::FigureAxis, p::Plot)

Push plot (curve) `p` into the indexed axis of figure `f`.
"""
function push!(fa::FigureAxis, p::Plot)
    a = fa.f.axes[fa.idx]
    push!(a, p)
    return fa.f
end

"""
    push!(f1::Figure, f2::Figure)::Figure

Insert the first axis of f2 into f1.

# Example
```julia
f1 = plot(sin)
f2 = Figure()
histogram(randn(100), bins = 10)  # plots on f2
push!(f1, f2)  # insert the histogram as second axis of f1
```
"""
function push!(f1::Figure, f2::Figure)::Figure
    push!(f1, f2(1))
end

"""
    push!(f1::Figure, an::FigureAxis)::Figure

Insert the axis in `an` into `f`.

# Example

``` julia
f1 = plot(sin)
f2 = Figure()
plot(f2, cos)
plot(f2[2], tan)
push!(f1, f2[2]) # insert the plot of tan into f1
"""
function push!(f1::Figure, f2::FigureAxis)::Figure
    push!(f1.axes, f2.f.axes[f2.idx])
    return f1
end

"""
    set!(a::Gaston.Axis, s)
    set!(f::Gaston.FigureAxis, s)

Set the settings of the axis or indexed figure. `s` can be a string or a
vector of pairs.
"""
function set!(a::Axis, s::S)::Axis where {S <: AbstractString}
    a.settings = s
    return a
end

function set!(fa::FigureAxis, s::S)::Figure where {S <: AbstractString}
    set!(fa.f.axes[fa.idx], s)
    return fa.f
end

function set!(a::Axis, s::Vector{<:Pair})::Axis
    a.settings = parse_settings(s)
    return a
end

function set!(fa::FigureAxis, s::Vector{<:Pair})::Figure
    set!(fa.f.axes[fa.idx], s)
    return fa.f
end

## Indexing into figures/axes
# It is possible to set/get plots and axes using indexing.
# Important: accessing a non-assigned location in a figure will create that location (like in Makie).
# Notation, assuming `f::Figure`, `a::Axis`, and `p::Plot`.
# `f[3]`        # `f.axes[3]`, creating it (and `f[1]` and `f[2]` as well) if necessary
# `f[3] = a`    # `f.axes[3] = a`, setting `f[1]` and `f[2]` to `Axis()` if necessary
# `f[i,j] = p`  # Replace `f.axes[i].plots[j]` with `p`. `f.axes[i]` will be created if necessary.
# `f[i] = p`    # Replace `f.axes[1].plots[i]` with `p`.
# `f[] = p`     # Replace `f.axes[1].plots[1]` with `p`.

"""
    getindex(f::Figure, index)::Gaston.FigureAxis

Return `Gaston.FigureAxis(f, index)`. If the axis at the specified index
does not exist, one is created.

To obtain (or create) an axis, use `f(index)`.

# Example
```julia
f1 = Figure()
plot(f1[3], sin) # Figure f1 contains three axes: the first two are empty,
                 # and the third one contains a sine wave.
```
"""
function getindex(f::Figure, idx)::FigureAxis
    ensure(f.axes, idx)
    return FigureAxis(f, idx)
end

getindex(a::Axis, idx)::Plot = a.plots[idx]

# Index into a Plot
function (f::Figure)(idx1, idx2)::Plot
    return f.axes[idx1][idx2]
end

# Replace an axis
function setindex!(f::Figure, a::Axis, idx)
    ensure(f.axes, idx)
    f.axes[idx] = a
end

# Replace a plot. Plot must already exist. (see `push!` to insert plots).
function setindex!(f::Figure, p::Plot, idx...)
    if isempty(idx)
        plotidx, axisidx = 1, 1
    elseif length(idx) == 1
        plotidx, axisidx = idx[1], 1
    else
        plotidx, axisidx = idx
    end
    f[axisidx].a[plotidx] = p
end

# Replace a plot in an axis.
function setindex!(a::Axis, p::Plot, idx)
    a.plots[idx] = p
    return a
end

# utility functions

isempty(f::Figure) = all(isempty(a) for a in f.axes)
isempty(a::Axis) = isempty(a.plots)

length(f::Figure) = length(f.axes)
length(a::Axis) = length(a.plots)

function empty!(a::Axis)
    a.settings = ""
    a.plots = Plot[]
    a
end

function ensure(v::Vector{T}, idx) where T <: Union{Axis, Plot}
    if !isassigned(v, idx)
        for i in (length(v)+1):idx
            push!(v, T())
        end
    end
end

"""
    figure(handle = <active figure handle> ; index = nothing)::Figure

Return specified figure (by handle or index) and make it the active
figure. If no figures exist, then a new figure is returned.

If no arguments are given, the current active figure is returned.
"""
function figure(handle = state.activefig ; index = nothing)::Figure
    global state
    if isnothing(handle) && isnothing(index)
        return Figure()
    end
    if isnothing(index)
        for fig in state.figures.figs
            if fig.handle == handle
                state.activefig = handle
                return fig
            end
        end
        error("No figure with handle: ", handle)
    end
    if isassigned(state.figures.figs, index)
        fig = state.figures.figs[index]
        state.activefig = fig.handle
        return fig
    else
        error("No figure stored in index: " , index)
    end
end

"""
    Gaston.listfigures()

Display a list of all existing figures.
"""
function listfigures(io::IO = stdin)
    L = length(state.figures.figs)
    if L == 0
        println(io, "Currently managing no figures.")
    elseif L == 1
        println(io, "Currently managing 1 figure:")
    else
        println(io, "Currently managing $L figures:")
    end
    for idx in 1:length(state.figures.figs)
        h = state.figures.figs[idx].handle
        s = "Figure with index: $idx and handle: $h"
        if h == state.activefig
            s = "  (Active) "*s
        else
            s = "  "*s
        end
        println(io, s)
    end
end

"""
    reset!(f::Figure)

Reset figure `f` to its initial state, without restarting its associated
gnuplot process.
"""
function reset!(f::Figure)
    f.axes = Axis[]
    f.multiplot = ""
    f.autolayout = true
end

"""
    closefigure(h = nothing)::Nothing

Close figure with handle `h`. If no arguments are given, the active figure is
closed. The most recent remaining figure (if any) is made active.

The associated gnuplot process is also terminated.

# Examples

```{.julia}
plot(sin, handle = :first);
plot(cos, handle = :second);
plot(tan, handle = :third);
closefigure()        # close figure with handle `:third`
closefigure(:first)  # close figure with handle `:first`
closefigure()        # close figure with handle `:second`
```
"""
function closefigure(handle = nothing)
    handle === nothing && (handle = state.activefig)
    if handle ∉ gethandles()
        error("Attempted to close figure with non-existing handle ", handle)
    end
    closefigure(figure(handle))
    nothing
end

"""
    closefigure(fig::Figure)::Nothing

Closes the specified figure. The associated gnuplot process is also terminated.

# Example

```{.julia}
p = plot(1:10);
closefigure(p)
```
"""
function closefigure(fig::Figure)
    @debug "closefigure(): closing figure with handle: " fig.handle
    #gp_quit(fig)
    finalize(fig)
    deleteat!(state.figures.figs, getidx(fig))
    state.activefig = isempty(state.figures.figs) ? nothing : state.figures.figs[end].handle
    nothing
end

"""
    closeall()::Nothing

Close all existing figures.
"""
function closeall()
    while true
        if isempty(state.figures.figs)
            break
        end
        closefigure(state.figures.figs[end])
    end
    nothing
end

"""
    Gaston.nexthandle()::Int

Return the next available handle (smallest not-yet-used positive integer).
"""
function nexthandle()
    isempty(state.figures.figs) && return 1
    handles = filter(t->isa(t, Int), gethandles())  # remove non-integer handles
    mh = maximum(handles, init=1)  # largest handle, or 1 if handles is empty
    if mh <= 0
        return 1
    else
        for i = 1:mh+1
            i ∉ handles && return i
        end
    end
end

"""
    Gaston.gethandles()::Vector{Any}

Return a vector with the handles of all existing figures.
"""
gethandles() = [figure.handle for figure in state.figures.figs]

"""
    Gaston.getidx(fig::Figure)

Return the index (in Gaston's internal state) of given figure
"""
function getidx(fig::Figure)
    h = fig.handle
    idx = 1
    for f in state.figures.figs
        h == f.handle && return idx
        idx += 1
    end
end

## Copyright (c) 2013-2021 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Code related to figures.

"""
    Plot(is3d, datafile, plotline)

Type to store the data needed to plot a curve: name of data file, a gnuplot plotline,
and whether the plot is 3d.
"""
struct Plot
    is3d     :: Bool
    datafile :: String
    plotline :: String

    function Plot(args... ; is3d = false)
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
        new(is3d, datafile, plotline)
    end
end

"""Instantiate a Plot with `is3d` set to `true`."""
Plot3(args...) = Plot(args... ; is3d = true)

"""
    Gaston.Axis(data, settings, plotlines)

Type that stores all information required to create a 2-D or 3-D axis.
"""
mutable struct Axis
    settings :: String         # plot settings
    plots    :: Vector{Plot}   # plot lines ("w lp pt 2 ps 3 ...."), one per curve
end

# Axis constructors
Axis() = Axis("", Plot[])

Axis(p::Plot) = Axis("", [p])

Axis(s::String) = Axis(s, Plot[])

Axis(s::String, p::Plot) = Axis(s, [p])

Axis(s::Vector{T}) where T <: Pair = Axis(parse_settings(s), Plot[])

Axis(s::Vector{T}, p::Plot) where T <: Pair = Axis(parse_settings(s), [p])

"""
    Gaston.Figure

Type that stores a figure.
"""
mutable struct Figure
    handle
    gp_proc   :: Base.Process
    multiplot :: String
    axes      :: Vector{Axis}
end

"""
    Gaston.Figure(h = nothing) -> figure::Gaston.Figure

Construct a figure with given handle. If `h === nothing`, automatically
assign the next available numerical handle. A new gnuplot process is
started and associated with the new figure, which becomes the active
figure, and is stored in Gaston's internal state.

    Gaston.Figure(handle, multiplot = m::String) -> figure::Gaston.Figure

Construct a figure with multiplot configuration `m`. The default value is `false`,
which disables multiplot.

Examples:

    f = Figure(multiplot = "") # activates multiplot
    f = Figure(multiplot = "layout 3, 1")
    f = Figure(multiplot = "title 'Title' font Sans,12")

"""
function Figure(handle = nothing ; multiplot = "")
    global state
    handle === nothing && (handle = nexthandle())
    if handle ∈ gethandles()
        error("Figure with given handle already exists. Handle: ", handle)
    else
        fig = finalizer(finalize_figure, Figure(handle, gp_start(), multiplot, Axis[]))
        push!(state.figures.figs, fig)
        state.activefig = handle
    end
    @debug "Returning figure with handle: " handle
    return fig
end

function finalize_figure(f::Figure)
    #@async @info "Finalizing figure with handle $(f.handle)."
    for i in eachindex(f.axes)
        empty!(f.axes[i])
    end
    @async gp_quit(f)
end

struct FigureAxis
    f::Figure
    a::Axis
end

function push!(a::Axis, p::Plot)
    push!(a.plots, p)
    return a
end

# push an axis into a figure
function push!(f::Figure, a::Axis)
    push!(f.axes, a)
    return f
end

# push a plot into an axis in a figure
function push!(f::Figure, p::Plot, index = 1)
    a = f[index].a
    push!(a, p)
    return f
end

push!(f::FigureAxis, p::Plot) = push!(f.a, p)

function set!(a::Axis, s::String)
    a.settings = s
    return a
end

function set!(a::Axis, s::Vector{<:Pair})
    a.settings = parse_settings(s)
    return a
end

function getindex(f::Figure, idx)::FigureAxis
    ensure(f.axes, idx)
    return FigureAxis(f, f.axes[idx])
end

getindex(a::Axis, idx)::Plot = a.plots[idx]

# () notation for indexing a figure.
# f(1) returns f.axes[1]
# f(2, 3) returns f.axes[2][3]
function (f::Figure)(idx)::Axis
    ensure(f.axes, idx)
    return f.axes[idx]
end

function (f::Figure)(idx1, idx2)::Plot
    return f.axes[idx1][idx2]
end

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

function setindex!(a::Axis, p::Plot, idx)
    a.plots[idx] = p
    return a
end

###

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

""" Return specified figure (by handle or index) and set it to active.
"""
function figure(handle = state.activefig ; index = nothing)::Figure
    global state
    if index === nothing
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
    listfigures()

List of all existing figures.
"""
function listfigures(io::IO = stdin)
    println(io, "Currently managing ", length(state.figures.figs), " figure(s).")
    println(io, state.activefig)
    for idx in 1:length(state.figures.figs)
        h = state.figures.figs[idx].handle
        s = "Figure with index: $idx and handle: $h"
        if h == state.activefig
            s = "(Active) "*s
        end
        println(io, s)
    end
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
    closefigure(h = nothing)

Close figure with handle `h`. If no arguments are given, the
active figure is closed. The most recent remaining figure (if
any) is made active.

Returns `nothing`.

# Examples
```julia-repl
julia> plot(sin, handle = :first);

julia> plot(cos, handle = :second);

julia> plot(tan, handle = :third);

julia> closefigure()        # close figure with handle `:third`

julia> closefigure(:first)  # close figure with handle `:first`

julia> closefigure()        # close figure with handle `:second`

```
"""
function closefigure(handle = nothing)
    handle === nothing && (handle = state.activefig)
    if handle ∉ gethandles()
        error("Attempted to close figure with non-existing handle ", handle)
    end
    closefigure(figure(handle))
end

"""
    closefigure(fig::Figure)

Closes the specified figure.

# Example
```julia-repl
julia> p = plot(1:10);

julia> closefigure(p)

```
"""
function closefigure(fig::Figure)
    @debug "closefigure(): closing figure with handle: " fig.handle
    #gp_quit(fig)
    finalize(fig)
    deleteat!(state.figures.figs, getidx(fig))
    state.activefig = isempty(state.figures.figs) ? nothing : state.figures.figs[end].handle
end

"""
    closeall()

Close all existing figures. Returns nothing.

See also: [`closefigure`](@ref)
"""
function closeall()
    while true
        if isempty(state.figures.figs)
            break
        end
        closefigure(state.figures.figs[end])
    end
end

"""
    Gaston.nexthandle() -> Int

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
    Gaston.gethandles() -> Vector::Any

Return a vector will all handles in `Gaston.state.figures`
"""
gethandles() = [figure.handle for figure in state.figures.figs]

"""Return the index of given figure """
function getidx(fig::Figure)
    h = fig.handle
    idx = 1
    for f in state.figures.figs
        h == f.handle && return idx
        idx += 1
    end
end

"""
    figure(handle::Int = 0) -> handle

Select a figure with the specified handle, or with the next available handle
if none is specified. Make the specified figure current. If the figure exists,
display it.
"""
function figure(handle::Int = 0)
    global gnuplot_state

    # make sure handleandle is valid
    handle < 0 && throw(DomainError(handle, "handleandle must be a positive integer or 0"))

    # determine figure handleandle
    handle == 0 && (handle = nexthandle())
    # set current figure to handle
    gnuplot_state.current = handle

    # if figure exists, display it
    if handle in gethandles()
        i = findfigure(handle)
        fig = gnuplot_state.figs[i]
        display(fig)
    else
        # if it doesn't, create it
        fig = newfigure(handle)
    end

    return handle
end

"""
    closefigure(x...) -> Vector{Int}

Close one or more figures.

If no arguments are given, the current figure is closed.

Returns a handle to the current figure, or `nothing` if all figures are closed.
"""
function closefigure(x...)

    isempty(x) && (x = (gnuplot_state.current,))
    any(i -> i::Int<1, x) && throw(DomainError(x, " all handles must be positive integers"))

    curr = gnuplot_state.current
    for handle ∈ x
        handles = gethandles()
        handle ∉ handles && continue
        curr = closesinglefigure(handle)
    end
    gnuplot_state.current = curr

    return curr
end

"""
    closeall() -> Int

Closes all existing figures. Returns the number of closed figures.
"""
function closeall()
    global gnuplot_state

    h = gethandles()
    closed = length(h)
    closed > 0 && closefigure(h...)
    gnuplot_state.current = nothing

    return closed
end

# Create a new figure and return it, with the specified handle (or the next
# available one if # handle == 0, and with the specified dimensions, axisconf
# and curve. Update Gaston state as necessary.
function newfigure(handle = 0;
                   dims = 2,
                   axisconf = "",
                   curve = Curve())

    # make sure handle is valid
    handle === nothing && (handle = 0) # no figures exist yet
    handle < 0 && throw(DomainError(handle,"handle must be a positive integer or 0"))

    # if h == 0, determine next available handle
    handle == 0 && (handle = nexthandle())

    # create and push or update, as necessary
    if handle in gethandles()
        # pre-existing; update
        fig = gnuplot_state.figs[findfigure(handle)]
        fig.dims = dims
        fig.axisconf = axisconf
        fig.curves = [curve]
    else
        # new; create and push
        fig = Figure(handle = handle, dims = dims, axisconf = axisconf, curves = [curve])
        push!(gnuplot_state.figs, fig)
    end

    # make this figure current
    gnuplot_state.current = handle

    return fig
end

# close a single figure, assuming arguments are valid; returns handle of
# the new current figure
function closesinglefigure(handle::Int)
    global gnuplot_state

    term = config[:term]
    term ∈ term_window && gnuplot_send("set term $term $handle close")

    # remove figure from global state
    filter!(h->h.handle!=handle,gnuplot_state.figs)

    # update state
    gnuplot_state.current = mostrecenthandle()
    return gnuplot_state.current
end

# Return index to figure with handle `c`. If no such figure exists, returns 0.
function findfigure(c)
    global gnuplot_state
    i = 0
    for j = 1:length(gnuplot_state.figs)
        if gnuplot_state.figs[j].handle == c
            i = j
            break
        end
    end
    return i
end

# return array of existing handles
function gethandles()
    [f.handle for f in gnuplot_state.figs]
end

# Return the next available handle (smallest non-used positive integer)
function nexthandle()
    isempty(gnuplot_state.figs) && return 1
    handles = gethandles()
    mh = maximum(handles)
    for i = 1:mh+1
        !in(i,handles) && return i
    end
end

# Return the most-recently added handle
function mostrecenthandle()
    isempty(gnuplot_state.figs) && return nothing
    return gnuplot_state.figs[end].handle
end

# Push configuration, axes or curves to a figure. The handle is assumed valid.
function push!(f::Figure, c::Curve)
    if isempty(f)
        f.curves = [c]
    else
        push!(f.curves, c)
    end
end

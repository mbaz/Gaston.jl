#=
Select a figure, creating it if it doesn't exist. When called with no
arguments or with h=0, create and select a new figure with next available
handle. Figure handles must be natural numbers.

When selecting a figure that must not be redrawn (e.g. because it will be
immediately overwritten), set redraw = false.

Returns the current figure handle.
=#
function figure(h::Handle = 0; redraw = true)
    global gnuplot_state

    # build vector of handles
    handles = gethandles()

    # make sure handle is valid
    h == nothing && (h = 0)
    if !isa(h,Int) || h < 0
        throw(DomainError(h,"handle must be a positive integer or 0"))
    end

    # determine figure handle
    h == 0 && (h = nexthandle())
    # set current figure to h
    gnuplot_state.current = h
    if !in(h, handles)
        # figure does not exist: create it and store it
        push!(gnuplot_state.figs, Figure(h))
    else
        # when selecting a pre-existing window, gnuplot requires that it be
        # redrawn in order to have mouse interactivity. Also, we want to
        # display the figure again if it was closed.
        i = findfigure(h)
        fig = gnuplot_state.figs[i]
        redraw && display(fig)
    end
    return h
end

""""Close one or more figures. Returns a handle to the active figure,
or `nothing` if all figures were closed."""
function closefigure(x::Vararg{Int})

    isempty(x) && (x = gnuplot_state.current)
    curr = 0

    for handle ∈ x
        handles = gethandles()
        # make sure handle is valid
        handle < 1 && throw(DomainError(handle, "handle must be a positive integer"))
        isempty(handles) && return nothing
        handle ∈ handles || continue

        curr = closesinglefigure(handle)
    end

    return curr
end

# close all figures
function closeall()
    global gnuplot_state

    closed = 0
    for i = 1:length(gnuplot_state.figs)
        closefigure()
        closed = closed + 1
    end
    return closed
end

# close a single figure, assuming arguments are valid; returns handle of
# the new current figure
function closesinglefigure(handle::Int)
    global gnuplot_state

    term = config[:term][:terminal]
    term ∈ term_window && gnuplot_send("set term $term $handle close")

    # remove figure from global state
    filter!(h->h.handle!=handle,gnuplot_state.figs)
    # update state
    if isempty(gnuplot_state.figs)
        # we just closed the last figure
        gnuplot_state.current = nothing
    else
        # select the most-recently created figure
        gnuplot_state.current = gnuplot_state.figs[end].handle
    end
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

# remove a figure's data without closing it
function clearfigure(h::Handle)
    global gnuplot_state

    f = findfigure(h)
    if f != 0
        gnuplot_state.figs[f] = Figure(h)
    end
end

# return array of existing handles
function gethandles()
    [f.handle for f in gnuplot_state.figs]
end

# Return the next available handle (smallest non-used positive integer)
function nexthandle()
    isempty(gnuplot_state.figs) && return 1
    handles = [f.handle for f in gnuplot_state.figs]
    mh = maximum(handles)
    for i = 1:mh+1
        !in(i,handles) && return i
    end
end

# Push configuration, axes or curves to a figure. The handle is assumed valid.
function push_figure!(handle,args...)
    index = findfigure(handle)
    f = gnuplot_state.figs[index]
    for c in args
        if isa(c, Curve)
            isempty(f) ? f.curves = [c] : push!(f.curves,c)
        end
        isa(c,AxesConf) && (f.axes = c)
        isa(c, String) && (f.gpcom = c)
        isa(c, PrintConf) && (f.print = c)
        isa(c, TermConf) && (f.term = c)
        isa(c, Int) && (f.dims = c)
    end
end

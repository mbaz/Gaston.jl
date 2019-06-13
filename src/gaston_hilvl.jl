## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains exported, high-level commands

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

#=
Select a figure, creating it if it doesn't exist. When called with no
arguments or with h=0, create and select a new figure with next available
handle. Figure handles must be natural numbers.

When selecting a figure that must not be redrawn (e.g. because it will be
immediately overwritten), set redraw = false.

Returns the current figure handle.
=#
function figure(h::Union{Int,Nothing} = 0; redraw = true)
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

# 2D plots
function plot(x::Coord,y::Coord;
             legend::String     = "",
             title::String      = "",
             xlabel::String     = "",
             ylabel::String     = "",
             plotstyle::String  = config[:curve][:plotstyle],
             linecolor::String  = config[:curve][:linecolor],
             linewidth::String  = "1",
             linestyle::String  = config[:curve][:linestyle],
             pointtype::String  = config[:curve][:pointtype],
             pointsize::String  = config[:curve][:pointsize],
             fillcolor::String  = config[:curve][:fillcolor],
             fillstyle::String  = config[:axes][:fillstyle],
             grid::String       = config[:axes][:grid],
             keyoptions::String = config[:axes][:keyoptions],
             axis::String       = config[:axes][:axis],
             xrange::String     = config[:axes][:xrange],
             yrange::String     = config[:axes][:yrange],
             xzeroaxis::String  = config[:axes][:xzeroaxis],
             yzeroaxis::String  = config[:axes][:yzeroaxis],
             font::String       = config[:term][:font],
             size::String       = config[:term][:size],
             background::String = config[:term][:background],
             financial::FinancialCoords = FinancialCoords(),
             err::ErrorCoords   = ErrorCoords(),
             handle::Union{Int,Nothing} = gnuplot_state.current,
             gpcom::String      = ""
            )
    # validation
    valid_2Dplotstyle(plotstyle)
    valid_linestyle(linestyle)
    valid_pointtype(pointtype)
    valid_axis(axis)
    valid_range(xrange)
    valid_range(yrange)
    valid_coords(x,y,err=err,fin=financial)

    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    linewidth == "" && (linewidth = "1")
    background == "" && (background = TerminalDefaults[term][:background])

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    tc = TermConf(font,size,linewidth,background)
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  grid = grid,
                  keyoptions = keyoptions,
                  axis = axis,
                  xrange = xrange,
                  yrange = yrange,
                  xzeroaxis = xzeroaxis,
                  yzeroaxis = yzeroaxis,
                 )
    cc = CurveConf(legend,plotstyle,linecolor,linewidth,
                   linestyle,pointtype,pointsize,fillstyle,fillcolor)
    c = Curve(x,y,financial,err,cc)
    push_figure!(handle,tc,ac,c,gpcom)

    return gnuplot_state.figs[findfigure(handle)]
end
plot(y::Coord;args...) = plot(1:length(y),y;args...)
plot(x::Real,y::Real;args...) = plot([x],[y];args...)  # plot a single point
# plot complex inputs
plot(c::Complex;args...) = plot(real(c),imag(c);args...)
plot(c::Vector{<:Complex};args...) = plot(real(c),imag(c);args...)

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord;
             legend::String    = "",
             plotstyle::String = config[:curve][:plotstyle],
             linecolor::String = config[:curve][:linecolor],
             linewidth::String = "1",
             linestyle::String = config[:curve][:linestyle],
             pointtype::String = config[:curve][:pointtype],
             pointsize::String = config[:curve][:pointsize],
             fillcolor::String  = config[:curve][:fillcolor],
             fillstyle::String  = config[:axes][:fillstyle],
             financial::FinancialCoords = FinancialCoords(),
             err::ErrorCoords  = ErrorCoords(),
             handle::Union{Int,Nothing} = gnuplot_state.current
         )

    # validation
    valid_2Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    valid_linestyle(linestyle)
    valid_coords(x,y,err=err,fin=financial)

    handle = figure(handle, redraw = false)
    cc = CurveConf(legend,plotstyle,linecolor,linewidth,linestyle,pointtype,
                   pointsize,fillstyle,fillcolor)
    c = Curve(x,y,financial,err,cc)
    push_figure!(handle,c)
    return gnuplot_state.figs[findfigure(handle)]
end
plot!(y::Coord;args...) = plot!(1:length(y),y;args...)
plot!(x::Real,y::Real;args...) = plot!([x],[y];args...)
plot!(c::Complex;args...) = plot!(real(c),imag(c);args...)
plot!(c::Vector{<:Complex};args...) = plot!(real(c),imag(c);args...)

function scatter(x::Coord,y::Coord;
                 handle::Union{Int,Nothing} = gnuplot_state.current,
                 args...)
    plot(x,y,plotstyle="points",handle=handle;args...)
end

function stem(x::Coord,y::Coord;
              onlyimpulses = config[:axes][:onlyimpulses],
              handle::Union{Int,Nothing} = gnuplot_state.current, args...)
    println("1")
    p = plot(x,y;handle=handle,plotstyle="impulses",
             linecolor="blue",linewidth="1.25",args...)
    println("2")
    onlyimpulses || (p = plot!(x,y;handle=handle,plotstyle="points",
                               linecolor="blue", pointtype="ecircle",
                               pointsize="1.5",args...))
    println("3")
    return p
end
function stem(y::Coord;handle=gnuplot_state.current,
              onlyimpulses=config[:axes][:onlyimpulses],args...)
    stem(1:length(y),y;handle=handle,onlyimpulses=onlyimpulses,args...)
end

function histogram(data::Coord;
                   bins::Int          = 10,
                   norm::Real         = 1.0,
                   legend::String     = "",
                   title::String      = "",
                   xlabel::String     = "",
                   ylabel::String     = "",
                   linecolor::String  = config[:curve][:linecolor],
                   linewidth::String  = "1",
                   fillcolor::String  = config[:curve][:fillcolor],
                   fillstyle::String  = config[:axes][:fillstyle],
                   keyoptions::String = config[:axes][:keyoptions],
                   xrange::String     = config[:axes][:xrange],
                   yrange::String     = config[:axes][:yrange],
                   font::String       = config[:term][:font],
                   size::String       = config[:term][:size],
                   background::String = config[:term][:background],
                   handle::Union{Int,Nothing} = gnuplot_state.current,
                   gpcom::String      = ""
                   )
    # validation
    valid_range(xrange)
    valid_range(yrange)
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  keyoptions = keyoptions,
                  xrange = xrange,
                  yrange = yrange)
    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    background == "" && (background = TerminalDefaults[term][:background])
    tc = TermConf(font,size,"1",background)

    x, y = hist(data,bins)
    y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm
    cc = CurveConf(legend = legend,
                   plotstyle = "boxes",
                   linecolor = linecolor,
                   linewidth = linewidth,
                   fillstyle = fillstyle,
                   fillcolor = fillcolor)
    c = Curve(x,y,cc)
    push_figure!(handle,tc,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end

# image plots
function imagesc(x::Coord,y::Coord,Z::Coord;
                 title::String     = "",
                 xlabel::String    = "",
                 ylabel::String    = "",
                 clim::Vector{Int} = [0,255],
                 xrange::String    = config[:axes][:xrange],
                 yrange::String    = config[:axes][:yrange],
                 font::String      = config[:term][:font],
                 size::String      = config[:term][:size],
                 gpcom::String     = "",
                 handle::Union{Int,Nothing} = gnuplot_state.current
                 )
    # validation
    valid_range(xrange)
    valid_range(yrange)
    length(clim) == 2 || throw(DomainError(length(clim), "clim must be a 2-element vector."))
    length(x) == Base.size(Z)[2] || throw(DimensionMismatch("invalid coordinates."))
    length(y) == Base.size(Z)[1] || throw(DimensionMismatch("invalid coordinates."))
    2 <= ndims(Z) <= 3 || throw(DimensionMismatch(ndims(Z), "Z must have two or three dimensions"))

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    ndims(Z) == 2 ? plotstyle = "image" : plotstyle = "rgbimage"
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  xrange = xrange,
                  yrange = yrange)
    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    tc = TermConf(font,size,"1","white")
    cc = CurveConf(plotstyle=plotstyle)

    if ndims(Z) == 3
        Z[:] = Z.-clim[1]
        Z[Z.<0] .= 0.0
        Z[:] = Z.*255.0/(clim[2]-clim[1])
        Z[Z.>255] .= 255
    end
    c = Curve(x,y,Z,cc)

    push_figure!(handle,tc,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
              legend::String     = "",
              title::String      = "",
              xlabel::String     = "",
              ylabel::String     = "",
              zlabel::String     = "",
              plotstyle::String  = config[:curve][:plotstyle],
              linecolor::String  = config[:curve][:linecolor],
              linewidth::String  = "1",
              pointtype::String  = config[:curve][:pointtype],
              pointsize::String  = config[:curve][:pointsize],
              keyoptions::String = config[:axes][:keyoptions],
              xrange::String     = config[:axes][:xrange],
              yrange::String     = config[:axes][:yrange],
              zrange::String     = config[:axes][:zrange],
              xzeroaxis::String  = config[:axes][:xzeroaxis],
              yzeroaxis::String  = config[:axes][:yzeroaxis],
              zzeroaxis::String  = config[:axes][:zzeroaxis],
              palette::String    = config[:axes][:palette],
              font::String       = config[:term][:font],
              size::String       = config[:term][:size],
              background::String = config[:term][:background],
              handle::Union{Int,Nothing} = gnuplot_state.current,
              gpcom::String      = ""
              )
    # validation
    valid_3Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    valid_range(xrange)
    valid_range(yrange)
    valid_range(zrange)
    ndims(Z) == 2 || throw(DimensionMismatch("Z must have two dimensions."))
    length(x) == Base.size(Z)[1] || throw(DimensionMismatch("invalid coordinates."))
    length(y) == Base.size(Z)[2]  || throw(DimensionMismatch("Invalid coordinates."))

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  zlabel = zlabel,
                  keyoptions = keyoptions,
                  xrange = xrange,
                  yrange = yrange,
                  zrange = zrange,
                  xzeroaxis = xzeroaxis,
                  yzeroaxis = yzeroaxis,
                  zzeroaxis = zzeroaxis,
                  palette = palette)
    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    background == "" && (background = TerminalDefaults[term][:background])
    tc = TermConf(font,size,"1",background)
    cc = CurveConf(plotstyle = plotstyle,
                   legend = legend,
                   linecolor = linecolor,
                   pointtype = pointtype,
                   linewidth = linewidth,
                   pointsize = pointsize)
    c = Curve(x,y,Z,cc)
    push_figure!(handle,tc,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

# print a figure to a file
function printfigure(;handle::Union{Int,Nothing} = gnuplot_state.current,
                     term::String       = config[:print][:print_term],
                     font::String       = config[:print][:print_font],
                     size::String       = config[:print][:print_size],
                     linewidth::String  = config[:print][:print_linewidth],
                     background::String = config[:print][:print_background],
                     outputfile::String = config[:print][:print_outputfile]
                    )

    # disable this command in IJulia
    # TODO: see if it's desirable and/or possible to re-enable it
    IsJupyter && error("printfigure command disabled in Jupyter notebook.")

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    isempty(outputfile) && throw(DomainError("Please specify an output filename."))

    # set figure's print parameters
    term == "pdf" && (term = "pdfcairo")
    term == "png" && (term = "pngcairo")
    term == "eps" && (term = "epscairo")
    valid_file_term(term)

    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    linewidth == "" && (linewidth = "1")
    background == "" && (background = TerminalDefaults[term][:background])

    fig = gnuplot_state.figs[h]
    pc = PrintConf(term,font,size,linewidth,background,outputfile)
    fig.print = pc
    llplot(fig,print=true)
    gnuplot_send("set output") # gnuplot needs this to close the output file

    return nothing
end


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
    global gaston_config

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
             plotstyle::String  = gaston_config.plotstyle,
             linecolor::String  = gaston_config.linecolor,
             linewidth::String  = gaston_config.linewidth,
             linestyle::String  = gaston_config.linestyle,
             pointtype::String  = gaston_config.pointtype,
             pointsize::String  = gaston_config.pointsize,
             fill::String       = gaston_config.fill,
             grid::String       = gaston_config.grid,
             keyoptions::String = gaston_config.keyoptions,
             axis::String       = gaston_config.axis,
             xrange::String     = gaston_config.xrange,
             yrange::String     = gaston_config.yrange,
             xzeroaxis::String  = gaston_config.xzeroaxis,
             yzeroaxis::String  = gaston_config.yzeroaxis,
             font::String       = gaston_config.font,
             size::String       = gaston_config.size,
             background::String = gaston_config.background,
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

    handle = figure(handle, redraw = false)
    clearfigure(handle)
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  fill = fill,
                  grid = grid,
                  keyoptions = keyoptions,
                  axis = axis,
                  xrange = xrange,
                  yrange = yrange,
                  xzeroaxis = xzeroaxis,
                  yzeroaxis = yzeroaxis,
                  font = font,
                  size = size,
                  background = background
                 )
    cc = CurveConf(legend,plotstyle,linecolor,pointtype,linewidth,linestyle,pointsize)
    c = Curve(x,y,financial,err,cc)
    push_figure!(handle,ac,c,gpcom)
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
             plotstyle::String = gaston_config.plotstyle,
             linecolor::String = gaston_config.linecolor,
             linewidth::String = gaston_config.linewidth,
             linestyle::String = gaston_config.linestyle,
             pointtype::String = gaston_config.pointtype,
             pointsize::String = gaston_config.pointsize,
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
    cc = CurveConf(legend,plotstyle,linecolor,pointtype,linewidth,linestyle,pointsize)
    c = Curve(x,y,financial,err,cc)
    push_figure!(handle,c)
    return gnuplot_state.figs[findfigure(handle)]
end
plot!(y::Coord;args...) = plot!(1:length(y),y;args...)
plot!(x::Real,y::Real;args...) = plot!([x],[y];args...)
plot!(c::Complex;args...) = plot!(real(c),imag(c);args...)
plot!(c::Vector{<:Complex};args...) = plot!(real(c),imag(c);args...)

function histogram(data::Coord;
                   bins::Int          = 10,
                   norm::Real         = 1.0,
                   legend::String     = "",
                   title::String      = "",
                   xlabel::String     = "",
                   ylabel::String     = "",
                   linecolor::String  = gaston_config.linecolor,
                   linewidth::String  = gaston_config.linewidth,
                   fill::String       = gaston_config.fill,
                   keyoptions::String = gaston_config.keyoptions,
                   xrange::String     = gaston_config.xrange,
                   yrange::String     = gaston_config.yrange,
                   font::String       = gaston_config.font,
                   size::String       = gaston_config.size,
                   background::String = gaston_config.background,
                   handle::Union{Int,Nothing} = gnuplot_state.current,
                   gpcom::String      = ""
                   )
    # validation
    valid_range(xrange)
    valid_range(yrange)
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  fill = fill,
                  keyoptions = keyoptions,
                  xrange = xrange,
                  yrange = yrange,
                  font = font,
                  size = size,
                  background = background)
    x, y = hist(data,bins)
    y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm
    cc = CurveConf(legend = legend,
                   plotstyle = "boxes",
                   linecolor = linecolor,
                   linewidth = linewidth)
    c = Curve(x,y,cc)
    push_figure!(handle,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end

# image plots
function imagesc(x::Coord,y::Coord,Z::Coord;
                 title::String     = "",
                 xlabel::String    = "",
                 ylabel::String    = "",
                 clim::Vector{Int} = [0,255],
                 xrange::String    = gaston_config.xrange,
                 yrange::String    = gaston_config.yrange,
                 font::String      = gaston_config.font,
                 size::String      = gaston_config.size,
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

    ndims(Z) == 2 ? plotstyle = "image" : plotstyle = "rgbimage"

    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  xrange = xrange,
                  yrange = yrange,
                  font = font,
                  size = size)
    cc = CurveConf(plotstyle=plotstyle)

    if ndims(Z) == 3
        Z[:] = Z.-clim[1]
        Z[Z.<0] .= 0.0
        Z[:] = Z.*255.0/(clim[2]-clim[1])
        Z[Z.>255] .= 255
    end
    c = Curve(x,y,Z,cc)

    push_figure!(handle,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
              legend::String     = "",
              plotstyle::String  = gaston_config.plotstyle,
              linecolor::String  = gaston_config.linecolor,
              linewidth::String  = gaston_config.linewidth,
              pointtype::String  = gaston_config.pointtype,
              pointsize::String  = gaston_config.pointsize,
              title::String      = "",
              xlabel::String     = "",
              ylabel::String     = "",
              zlabel::String     = "",
              keyoptions::String = gaston_config.keyoptions,
              xrange::String     = gaston_config.xrange,
              yrange::String     = gaston_config.yrange,
              zrange::String     = gaston_config.zrange,
              xzeroaxis::String  = gaston_config.xzeroaxis,
              yzeroaxis::String  = gaston_config.yzeroaxis,
              zzeroaxis::String  = gaston_config.zzeroaxis,
              font::String       = gaston_config.font,
              size::String       = gaston_config.size,
              handle::Union{Int,Nothing} = gnuplot_state.current,
              gpcom::String      = ""
              )
    # validation
    valid_3Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    valid_range(xrange)
    valid_range(yrange)
    valid_range(zrange)
    ndims(Z) == 2 || throw(DimensionMismatch(ndims(Z), "Z must have two dimensions."))
    length(x) == Base.size(Z)[1] || throw(DimensionMismatch("invalid coordinates."))
    length(y) == Base.size(Z)[2]  || throw(DimensionMismatch("Invalid coordinates."))

    handle = figure(handle, redraw = false)
    clearfigure(handle)
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
                  font = font,
                  size = size
                 )
    cc = CurveConf(plotstyle = plotstyle,
                   legend = legend,
                   linecolor = linecolor,
                   pointtype = pointtype,
                   linewidth = linewidth,
                   pointsize = pointsize)
    c = Curve(x,y,Z,cc)
    push_figure!(handle,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

# print a figure to a file
function printfigure(;handle::Union{Int,Nothing} = gnuplot_state.current,
                     term::String       = gaston_config.print_term,
                     font::String       = gaston_config.print_font,
                     size::String       = gaston_config.print_size,
                     linewidth::String  = gaston_config.print_linewidth,
                     outputfile::String = gaston_config.print_outputfile
                    )

    # disable this command in IJulia
    # TODO: see if it's desirable and/or possible to re-enable it
    isjupyter && error("printfigure command disabled in Jupyter notebook.")

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    isempty(outputfile) && throw(DomainError("Please specify an output filename."))
    valid_file_term(term)

    # set figure's print parameters
    fig = gnuplot_state.figs[h]
    fig.conf.print_flag = true
    fig.conf.print_term = term
    fig.conf.print_font = font
    fig.conf.print_size = size
    fig.conf.print_linewidth = linewidth
    fig.conf.print_outputfile = outputfile
    llplot(fig)
    # gnuplot is weird: this command is needed to close the output file
    gnuplot_send("set output")

    # unset print_flag
    fig.conf.print_flag = false

    return nothing
end


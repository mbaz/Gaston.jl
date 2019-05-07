## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains exported, high-level commands

""""Close one or more figures. Returns a handle to the active figure,
or `nothing` if all figures were closed."""
function closefigure(x...)

    isempty(x) && (x = gnuplot_state.current)
    curr = 0

    for handle ∈ x
        handles = gethandles()
        # make sure handle is valid
        isempty(handles) && return nothing
        isa(handle,Int) || error("Invalid handle.")
        handle < 1 && error("Invalid handle.")
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
function figure(h = 0; redraw = true)
    global gnuplot_state
    global gaston_config

    # build vector of handles
    handles = gethandles()

    # make sure handle is valid
    h == nothing && (h = 0)
    isa(h,Int) || error("Invalid handle.")
    h < 0 && error("Invalid handle.")

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
             legend          = "",
             title           = "",
             xlabel          = "",
             ylabel          = "",
             plotstyle       = gaston_config.plotstyle,
             linecolor       = gaston_config.linecolor,
             linewidth       = gaston_config.linewidth,
             linestyle       = gaston_config.linestyle,
             pointtype       = gaston_config.pointtype,
             pointsize       = gaston_config.pointsize,
             fill            = gaston_config.fill,
             grid            = gaston_config.grid,
             keyoptions      = gaston_config.keyoptions,
             axis            = gaston_config.axis,
             xrange          = gaston_config.xrange,
             yrange          = gaston_config.yrange,
             xzeroaxis       = gaston_config.xzeroaxis,
             yzeroaxis       = gaston_config.yzeroaxis,
             font            = gaston_config.font,
             size            = gaston_config.size,
             background      = gaston_config.background,
             financial       = FinancialCoords(),
             err             = ErrorCoords(),
             handle          = gnuplot_state.current,
             gpcom           = ""
            )
    # validation
    @assert valid_2Dplotstyle(plotstyle) "Non-recognized plotstyle."
    @assert valid_linestyle(linestyle) string("Line style pattern accepts: ",
            "space, dash, underscore and dot.")
    @assert valid_pointtype(pointtype) "Pointtype $(pointtype) not supported."
    @assert valid_axis(axis) "Axis $(axis) not supported."
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert valid_coords(x,y,err=err,fin=financial) "Input vectors must have the same number of elements."

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
             legend          = "",
             plotstyle       = gaston_config.plotstyle,
             linecolor       = gaston_config.linecolor,
             linewidth       = gaston_config.linewidth,
             linestyle       = gaston_config.linestyle,
             pointtype       = gaston_config.pointtype,
             pointsize       = gaston_config.pointsize,
             financial       = FinancialCoords(),
             err             = ErrorCoords(),
             handle          = gnuplot_state.current
         )

    # validation
    @assert valid_2Dplotstyle(plotstyle) "Non-recognized plotstyle."
    @assert valid_pointtype(pointtype) "pointtype $(pointtype) not supported."
    @assert valid_linestyle(linestyle) string("Line style pattern accepts:",
                                              " space, dash, underscore and dot")
    @assert valid_coords(x,y,err=err,fin=financial) "Input vectors must have the same number of elements."

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
                   bins::Int  = 10,
                   norm       = 1.0,
                   legend     = "",
                   title      = "",
                   xlabel     = "",
                   ylabel     = "",
                   linecolor  = gaston_config.linecolor,
                   linewidth  = gaston_config.linewidth,
                   fill       = gaston_config.fill,
                   keyoptions = gaston_config.keyoptions,
                   xrange     = gaston_config.xrange,
                   yrange     = gaston_config.yrange,
                   font       = gaston_config.font,
                   size       = gaston_config.size,
                   background = gaston_config.background,
                   handle     = gnuplot_state.current,
                   gpcom      = ""
                   )
    # validation
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert bins > 0 "At least one bin is required."
    @assert norm > 0 "norm must be a positive number."

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
                 title     = "",
                 xlabel    = "",
                 ylabel    = "",
                 clim      = [0,255],
                 handle    = gnuplot_state.current,
                 xrange    = gaston_config.xrange,
                 yrange    = gaston_config.yrange,
                 font      = gaston_config.font,
                 size      = gaston_config.size,
                 gpcom     = ""
                 )
    # validation
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert length(clim) == 2 "clim must be a 2-element vector."
    @assert length(x) == Base.size(Z)[2] "Invalid coordinates."
    @assert length(y) == Base.size(Z)[1] "Invalid coordinates."
    @assert 2 <= ndims(Z) <= 3 "Z must have two or three dimensions."

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
              legend     = "",
              plotstyle  = gaston_config.plotstyle,
              linecolor  = gaston_config.linecolor,
              linewidth  = gaston_config.linewidth,
              pointtype  = gaston_config.pointtype,
              pointsize  = gaston_config.pointsize,
              title      = "",
              xlabel     = "",
              ylabel     = "",
              zlabel     = "",
              keyoptions = gaston_config.keyoptions,
              xrange     = gaston_config.xrange,
              yrange     = gaston_config.yrange,
              zrange     = gaston_config.zrange,
              xzeroaxis  = gaston_config.xzeroaxis,
              yzeroaxis  = gaston_config.yzeroaxis,
              zzeroaxis  = gaston_config.zzeroaxis,
              font       = gaston_config.font,
              size       = gaston_config.size,
              handle     = gnuplot_state.current,
              gpcom      = ""
              )
    # validation
    @assert valid_3Dplotstyle(plotstyle) "Non-recognized plotstyle."
    @assert valid_pointtype(pointtype) "pointtype $(pointtype) not supported."
    @assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert valid_range(zrange) "Range $(zrange) not supported."
    @assert ndims(Z) == 2 "Z must have two dimensions."
    @assert length(x) == Base.size(Z)[1] "Invalid coordinates."
    @assert length(y) == Base.size(Z)[2] "Invalid coordinates."

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
function printfigure(;handle=gnuplot_state.current,
                     term=gaston_config.print_term,
                     font=gaston_config.print_font,
                     size=gaston_config.print_size,
                     linewidth=gaston_config.print_linewidth,
                     outputfile=gaston_config.print_outputfile)

    # disable this command in IJulia
    # TODO: see if it's desirable and/or possible to re-enable it
    isjupyter && error("printfigure command disabled in Jupyter notebook.")

    h = findfigure(handle)
    h == 0 && error("Requested figure does not exist.")
    isempty(outputfile) && error("Please specify an output filename.")
    term ∈ term_file || error("Unsupported terminal $(term).")

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


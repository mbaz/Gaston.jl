## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains exported, high-level commands

function closefigure(x...)
    global gnuplot_state
    global gaston_config

    # build vector of handles
	handles = [f.handle for f in gnuplot_state.figs]
	isempty(handles) && error("No figures exist.")

    # get handle of figure to close
    isempty(x) ? handle = gnuplot_state.current : handle = x[1]

    # make sure handle is valid
	isa(handle,Int) || error("Invalid handle.")
	handle < 1 && error("Invalid handle.")
	handle ∈ handles || error("No such figure exists.")

	# only inform gnuplot if term type is screen
	term = gaston_config.terminal
    term ∈ supported_screenterms && gnuplot_send("set term $term $handle close")

	# remove figure
	filter!(h->h.handle!=handle,gnuplot_state.figs)

	# update state
	if isempty(gnuplot_state.figs)
		# we just closed the last figure
		gnuplot_state.current = nothing
	else
		# select the most-recently created figure
		gnuplot_state.current = gnuplot_state.figs[end].handle
	end
	return handle
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

# Select or create a figure. When called with no arguments, create a new
# figure. Figure handles must be natural numbers.
# Returns the current figure handle.
function figure(h,redraw::Bool)
    global gnuplot_state
    global gaston_config

    # see if we need to set up gnuplot
    gnuplot_state.running || gnuplot_init()

    # build vector of handles
	handles = [f.handle for f in gnuplot_state.figs]

    # make sure handle is valid
	h == nothing && (h = 0)
	isa(h,Int) || error("Invalid handle.")
	h < 0 && error("Invalid handle.")

    # determine figure handle
	h == 0 && (h = nexthandle())
    # if figure with handle h exists, replot it; otherwise create it
    gnuplot_state.current = h
    if !in(h, handles)
        push!(gnuplot_state.figs, Figure(h))
    else
        if redraw
            llplot()
        end
    end
    return h
end
figure() = figure(0,true)  # create new figure with next available handle
figure(h) = figure(h,true) # create/select figure with handle h

# 2D plots
function plot(x::Coord,y::Coord;
			 legend          = gaston_config.legend,
			 plotstyle       = gaston_config.plotstyle,
			 color           = gaston_config.color,
			 marker          = gaston_config.marker,
			 linewidth       = gaston_config.linewidth,
			 pointsize       = gaston_config.pointsize,
			 title           = gaston_config.title,
			 xlabel          = gaston_config.xlabel,
			 ylabel          = gaston_config.ylabel,
			 fill            = gaston_config.fill,
			 grid            = gaston_config.grid,
			 box             = gaston_config.box,
			 axis            = gaston_config.axis,
			 xrange          = gaston_config.xrange,
			 yrange          = gaston_config.yrange,
			 financial       = FinancialCoords(),
			 err             = ErrorCoords(),
			 handle          = gnuplot_state.current,
			)
	# validation
	@assert valid_label(legend) "Legend must be a string."
	@assert valid_2Dplotstyle(plotstyle) "Non-recognized plotstyle."
	@assert valid_label(color) "Color must be a string."
	@assert valid_marker(marker) "Marker $(marker) not supported."
	@assert valid_number(linewidth) "Invalid linewidth $linewidth."
	@assert valid_number(pointsize) "Invalid pointsize $pointsize."
	@assert valid_label(title) "Title must be a string."
	@assert valid_label(xlabel) "xlabel must be a string."
	@assert valid_label(ylabel) "ylabel must be a string."
	@assert valid_fill(fill) "Fill style $(fill) not supported."
	@assert valid_grid(grid) "Grid style $(grid) not supported."
	@assert valid_label(box) "box must be a string."
	@assert valid_axis(axis) "Axis $(axis) not supported."
	@assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
	@assert valid_coords(x,y,err=err,fin=financial) "Input vectors must have the same number of elements."

	handle = figure(handle,false)
	clearfigure(handle)
	ac = AxesConf(title = title,
				  xlabel = xlabel,
				  ylabel = ylabel,
				  fill = fill,
				  grid = grid,
				  box = box,
				  axis = axis,
				  xrange = xrange,
				  yrange = yrange)
	cc = CurveConf(legend,plotstyle,color,marker,linewidth,pointsize)
	c = Curve(x,y,financial,err,cc)
	push_figure!(handle,ac,c)
	llplot()
	return handle
end
plot(y::Coord;args...) = plot(1:length(y),y;args...)
plot(x::Real,y::Real;args...) = plot([x],[y];args...)  # plot a single point
# plot complex inputs
plot(c::Complex{T} where T<:Number;args...) = plot(real(c),imag(c);args...)
plot(c::Vector{Complex{T}} where T<:Number;args...) = plot(real(c),imag(c);args...)

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord;
			 legend          = gaston_config.legend,
			 plotstyle       = gaston_config.plotstyle,
			 color           = gaston_config.color,
			 marker          = gaston_config.marker,
			 linewidth       = gaston_config.linewidth,
			 pointsize       = gaston_config.pointsize,
			 financial       = FinancialCoords(),
			 err             = ErrorCoords(),
			 handle          = gnuplot_state.current
		 )

	# validation
	@assert valid_label(legend) "Legend must be a string."
	@assert valid_2Dplotstyle(plotstyle) "Non-recognized plotstyle."
	@assert valid_label(color) "Color must be a string."
	@assert valid_marker(marker) "Marker $(marker) not supported."
	@assert valid_number(linewidth) "Invalid linewidth $linewidth."
	@assert valid_number(pointsize) "Invalid pointsize $pointsize."
	@assert valid_coords(x,y,err=err,fin=financial) "Input vectors must have the same number of elements."

	handle = figure(handle,false)
	cc = CurveConf(legend,plotstyle,color,marker,linewidth,pointsize)
	c = Curve(x,y,financial,err,cc)
	push_figure!(handle,c)
	llplot()
	return handle
end
plot!(y::Coord;args...) = plot!(1:length(y),y;args...)

function histogram(data::Coord;
				   bins::Int = 10,
				   norm      = 1.0,
				   legend    = gaston_config.legend,
				   color     = gaston_config.color,
				   linewidth = gaston_config.linewidth,
				   title     = gaston_config.title,
				   xlabel    = gaston_config.xlabel,
				   ylabel    = gaston_config.ylabel,
				   fill      = gaston_config.fill,
				   box       = gaston_config.box,
				   xrange    = gaston_config.xrange,
				   yrange    = gaston_config.yrange,
				   handle    = gnuplot_state.current
				   )
	# validation
	@assert valid_label(legend) "Legend must be a string."
	@assert valid_label(color) "Color must be a string."
	@assert valid_number(linewidth) "Invalid linewidth $linewidth."
	@assert valid_label(title) "Title must be a string."
	@assert valid_label(xlabel) "xlabel must be a string."
	@assert valid_label(ylabel) "ylabel must be a string."
	@assert valid_fill(fill) "Fill style $(fill) not supported."
	@assert valid_label(box) "box must be a string."
	@assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
	@assert bins > 0 "At least one bin is required."
	@assert norm > 0 "norm must be a positive number."

	handle = figure(handle,false)
	clearfigure(handle)

	ac = AxesConf(title = title,
				  xlabel = xlabel,
				  ylabel = ylabel,
				  fill = fill,
				  box = box,
				  xrange = xrange,
				  yrange = yrange)
	x, y = hist(data,bins)
	y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm
	cc = CurveConf(legend = legend,
				   plotstyle = "boxes",
				   color = color,
				   linewidth = linewidth)
	c = Curve(x,y,cc)
	f = Figure(handle,ac,[c],false)
	push_figure!(handle,ac,c)
	llplot()
	return handle
end

# image plots
function imagesc(x::Coord,y::Coord,Z::Coord;
				 title = gaston_config.title,
				 xlabel = gaston_config.xlabel,
				 ylabel = gaston_config.ylabel,
				 clim = [0,255],
				 handle = gnuplot_state.current
				 )
	# validation
	@assert valid_label(title) "Title must be a string."
	@assert valid_label(xlabel) "xlabel must be a string."
	@assert valid_label(ylabel) "ylabel must be a string."
	@assert length(clim) == 2 "clim must be a 2-element vector."
	@assert length(x) == size(Z)[2] "Invalid coordinates."
	@assert length(y) == size(Z)[1] "Invalid coordinates."
	@assert 2 <= ndims(Z) <= 3 "Z must have two or three dimensions."

	handle = figure(handle,false)
	clearfigure(handle)

	ndims(Z) == 2 ? plotstyle = "image" : plotstyle = "rgbimage"

	ac = AxesConf(title = title,
				  xlabel = xlabel,
				  ylabel = ylabel)
	cc = CurveConf(plotstyle=plotstyle)

	if ndims(Z) == 3
		Z[:] = Z.-clim[1]
		Z[Z.<0] = 0.0
		Z[:] = Z.*255.0/(clim[2]-clim[1])
		Z[Z.>255] = 255
	end
	c = Curve(x,y,Z,cc)

	push_figure!(handle,ac,c)
	llplot()
	return handle
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
			  legend    = gaston_config.legend,
			  plotstyle = gaston_config.plotstyle,
			  color     = gaston_config.color,
			  marker    = gaston_config.marker,
			  linewidth = gaston_config.linewidth,
			  pointsize = gaston_config.pointsize,
			  title     = gaston_config.title,
			  xlabel    = gaston_config.xlabel,
			  ylabel    = gaston_config.ylabel,
			  zlabel    = gaston_config.zlabel,
			  box       = gaston_config.box,
			  xrange    = gaston_config.xrange,
			  yrange    = gaston_config.yrange,
			  zrange    = gaston_config.zrange,
			  handle    = gnuplot_state.current)
	# validation
	@assert valid_label(legend) "Legend must be a string."
	@assert valid_3Dplotstyle(plotstyle) "Non-recognized plotstyle."
	@assert valid_label(color) "Color must be a string."
	@assert valid_marker(marker) "Marker $(marker) not supported."
	@assert valid_number(linewidth) "Invalid linewidth $linewidth."
	@assert valid_number(pointsize) "Invalid pointsize $pointsize."
	@assert valid_label(title) "Title must be a string."
	@assert valid_label(xlabel) "xlabel must be a string."
	@assert valid_label(ylabel) "ylabel must be a string."
	@assert valid_label(box) "box must be a string."
	@assert valid_range(xrange) "Range $(xrange) not supported."
    @assert valid_range(yrange) "Range $(yrange) not supported."
    @assert valid_range(zrange) "Range $(zrange) not supported."
	@assert length(x) == size(Z)[1] "Invalid coordinates."
	@assert length(y) == size(Z)[2] "Invalid coordinates."
	@assert ndims(Z) == 2 "Z must have two dimensions."

	handle = figure(handle,false)
	clearfigure(handle)
	ac = AxesConf(title = title,
				  xlabel = xlabel,
				  ylabel = ylabel,
				  zlabel = zlabel,
				  box = box)
	cc = CurveConf(plotstyle = plotstyle,
				   legend = legend,
				   color = color,
				   marker = marker,
				   linewidth = linewidth,
				   pointsize = pointsize)
	c = Curve(x,y,Z,cc)
	push_figure!(handle,ac,c)
	llplot()
	return handle
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

# print a figure to a file
function printfigure(;handle=gnuplot_state.current,
					 term="pdf",
					 outputfile=gaston_config.outputfile)

    # disable this command in IJulia
    # TODO: see if it's desirable and/or possible to re-enable it
	gnuplot_state.isjupyter && error("printfigure command disabled in Jupyter notebook.")

    findfigure(handle) == 0 && error("Requested figure does not exist.")
	isempty(outputfile) && error("Please specify an output filename.")
	term ∈ supported_fileterms || error("Unsupported filetype $(term).")

	set(outputfile=outputfile)
    # save terminal
    saveterm = gaston_config.terminal
    # set temporary terminal and replot
    set(terminal=term)
    figure(handle)
    set(terminal=saveterm)
    # gnuplot is weird: this command is needed to close the output file
    gnuplot_send("set output")

    return handle
end


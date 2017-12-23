## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

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

# remove a figure's data without closing it
function clearfigure(h::Int)
    global gnuplot_state

    f = findfigure(h)
    if f != 0
        gnuplot_state.figs[f] = Figure(h)
    end
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
    if gnuplot_state.current == nothing
		h == 0 && (h = 1)
    else
        if h == 0
            # use lowest numbered handle available
            mh = maximum(handles)
            for i = 1:mh+1
                if !in(i, handles)
                    h = i
                    break
                end
            end
        end
    end
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
			 zlabel          = gaston_config.zlabel,
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
	plotstyle ∈ supported_2Dplotstyles || error("Plotstyle $(plotstyle) not supported.")
    marker ∈ supported_markers || error("Marker $(marker) not supported.")
	fill ∈ supported_fillstyles || error("Fill style $(fill) not supported.")
	grid ∈ supported_grids || error("Grid style $(grid) not supported.")
    axis ∈ supported_axis || error("Axis $(axis) not supported.")
    validate_range(xrange) || error("Range $(xrange) not supported.")
    validate_range(yrange) || error("Range $(yrange) not supported.")
	length(x) != length(y) && error("Input vectors must have the same number of elements.")

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
	f = Figure(handle,ac,[c],false)
	push_figure!(f)
	llplot()
	return handle
end
plot(y::Coord;args...) = plot(1:length(y),y;args...)

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
	plotstyle ∈ supported_2Dplotstyles || error("Plotstyle $(plotstyle) not supported.")
    marker ∈ supported_markers || error("Marker $(marker) not supported.")
	length(x) != length(y) && error("Input vectors must have the same number of elements.")

	handle = figure(handle,false)
	index = findfigure(handle)
	gnuplot_state.figs[index].isempty && error("Cannot add curve to empty figure.")

	cc = CurveConf(legend,plotstyle,color,marker,linewidth,pointsize)
	c = Curve(x,y,financial,err,cc)
	push_curve!(handle,c)
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
	bins < 1 && error("At least one bin is required.")
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
	push_figure!(f)
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

	handle = figure(handle,false)
	clearfigure(handle)

	length(x) == size(Z)[2] || error("Invalid coordinates.")
	length(y) == size(Z)[1] || error("Invalid coordinates.")
	2 <= ndims(Z) <= 3 || error("Z must have two or three dimensions.")
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

	f = Figure(handle,ac,[c],false)
	push_figure!(f)
	llplot()
	return handle
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
			  title     = gaston_config.title,
			  plotstyle = gaston_config.plotstyle,
			  xlabel    = gaston_config.xlabel,
			  ylabel    = gaston_config.ylabel,
			  zlabel    = gaston_config.zlabel,
			  legend    = gaston_config.legend,
			  color     = gaston_config.color,
			  marker    = gaston_config.marker,
			  linewidth = gaston_config.linewidth,
			  pointsize = gaston_config.pointsize,
			  box       = gaston_config.box,
			  handle    = gnuplot_state.current)

	length(x) == size(Z)[1] || error("Invalid coordinates.")
	length(y) == size(Z)[2] || error("Invalid coordinates.")
	ndims(Z) == 2 || error("Z must have two dimensions.")

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
	f = Figure(handle,ac,[c],false)
	push_figure!(f)
	llplot()
	return handle
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

# print a figure to a file
function printfigure(args...)
    global gnuplot_state
    global gaston_config

    # if args is empty, print current figure in pdf
    if isempty(args)
        term = "pdf"
        h = gnuplot_state.current
    elseif length(args) == 1
        a = args[1]
        if isa(a, Int)
            # if a is an integer, it's the figure handle.
            h = a
        elseif isa(a, AbstractString)
            # if a is a string, it's the term type
            h = gnuplot_state.current
            term = a
        else
            error("Wrong arguments.")
        end
    elseif length(args) == 2
        a = args[1]
        if isa(a, Int)
            h = a
        else
            error("Wrong arguments.")
        end
        term = args[2]
        if term ∉ supported_fileterms
            error("Wrong arguments.")
        end
    end

    # make sure requested figure exists
    if findfigure(h) == 0
        error("Requested figure does not exist.")
    end

    # save terminal
    saveterm = gaston_config.terminal
    # set temporary terminal and replot
    set(terminal=term)
    figure(h)
    set(terminal=saveterm)
    # gnuplot is weird: this command is needed to close the output file
    gnuplot_send("set output")

    return h
end


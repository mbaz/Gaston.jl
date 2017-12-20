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
	index = findfigure(handle)
	clearfigure(handle)
	ac = AxesConf(title,xlabel,ylabel,"",fill,grid,box,axis,xrange,yrange,"")
	cc = CurveConf(legend,plotstyle,color,marker,linewidth,pointsize)
	c = [Curve(x,y,[],financial,err,cc)]
	f = Figure(handle,ac,c,false)
	if gnuplot_state.figs[index].isempty
		gnuplot_state.figs[index] = f
	else
		push!(gnuplot_state.figs,f)
	end
	llplot()
	return handle
end
plot(y;args...) = plot(1:length(y),y;args...)

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
	c = Curve(x,y,[],financial,err,cc)
	push!(gnuplot_state.figs[index].curves,c)
	llplot()
	return handle
end

function histogram(args...)
    global gnuplot_state
    # if args[1] is an integer, it's the figure handle.
    if isa(args[1], Int)
        h = args[1]
        args = args[2:end]   # argument parsing starts with 1 (eases debug)
    else
        h = gnuplot_state.current
    end
    h = figure(h,false) # create/select figure
    clearfigure(h)  # remove all figure configuration
    # parse arguments
    state = "SINI"
    la = length(args)
    while(true)
        if state == "SINI"
            i = 1
            bins = 10
            norm = 0
            cc = CurveConf()
            cc.plotstyle = "boxes"
            ac = AxesConf()
            state = "S1"
        elseif state == "S1"
            if i > la
                state = "SERROR"
                continue
            end
            y = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                # validate bins and norm
                if !isa(bins,Int) || !isa(norm,Real) || bins <= 0 || norm < 0
                    state = "SERROR"
                    continue
                end
                x, y = hist(y,bins)
                if norm != 0
                    delta = step(x)
                    y = norm*y/(delta*sum(y))
                end
                addcoords(x,y,cc)
                state = "SEND"
                continue
            end
            state = "S3"
        elseif state == "S3"
            if i+1 > la
                state = "SERROR"
                continue
            end
            ai = args[i]; ai1 = args[i+1]
            if ai == "legend"
                cc.legend = ai1
            elseif ai == "color"
                cc.color = ai1
            elseif ai == "linewidth"
                cc.linewidth = ai1
            elseif ai == "bins"
                bins = ai1
            elseif ai == "norm"
                norm = ai1
            elseif ai == "title"
                ac.title = ai1
            elseif ai == "xlabel"
                ac.xlabel = ai1
            elseif ai == "ylabel"
                ac.ylabel = ai1
			elseif ai == "fillstyle"
				ac.fill = ai1
            elseif ai == "box"
                ac.box = ai1
            elseif ai == "xrange"
                ac.xrange = ai1
            elseif ai == "yrange"
                ac.yrange = ai1
            else
                error("Invalid property specified")
            end
            i = i+2
            state = "S2"
        elseif state == "SEND"
            addconf(ac)
            llplot()
            break
        elseif state == "SERROR"
            error("Invalid arguments")
        else
            error("Unforseen situation, bailing out")
        end
    end
    return h
end

# image plots
function imagesc(args...)
    global gnuplot_state
    # if args[1] is an integer, it's the figure handle.
    if isa(args[1], Int)
        h = args[1]
        args = args[2:end]   # argument parsing starts with 1 (eases debug)
    else
        h = gnuplot_state.current
    end
    h = figure(h,false) # create/select figure
    clearfigure(h)  # remove all figure configuration
    # parse arguments
    state = "SINI"
    la = length(args)
    while(true)
        if state == "SINI"
            i = 1
            cc = CurveConf()
            ac = AxesConf()
            state = "S1"
        elseif state == "S1"
            if i > la
                state = "SERROR"
                continue
            end
            tmp = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                Z = tmp
                if isa(Z,Array) && 2 <= ndims(Z) <= 3
                    y = 1:size(Z)[1]
                    x = 1:size(Z)[2]
                    state = "S3"
                else
                    state = "SERROR"
                end
            else
                if isa(args[i],AbstractString)
                    Z = tmp
                    if isa(Z,Array) && 2 <= ndims(Z) <= 3
                        y = 1:size(Z)[1]
                        x = 1:size(Z)[2]
                        state = "S6"
                    else
                        state = "SERROR"
                    end
                else
                    y = tmp
                    tmp = args[i]
                    i = i+1
                    state = "S4"
                end
            end
        elseif state == "S3"
            if ndims(Z) == 2
                cc.plotstyle = "image"
            elseif ndims(Z) == 3
                cc.plotstyle = "rgbimage"
            end
            addcoords(x,y,Z,cc)
            state = "SEND"
        elseif state == "S4"
            if i > la
                Z = tmp
                x = 1:size(Z)[2]
                state = "S3"
            else
                if isa(args[i],AbstractString)
                    Z = tmp
                    x = 1:size(Z)[2]
                    state = "S6"
                else
                    x = tmp
                    tmp = args[i]
                    i = i+1
                    state = "S5"
                end
            end
        elseif state == "S5"
            Z = tmp
            if i > la
                state = "S3"
            else
                state = "S6"
            end
        elseif state == "S6"
            if i+1 > la
                state = "S3"
            else
                ai = args[i]; ai1 = args[i+1]
                if ai == "xlabel"
                    ac.xlabel = ai1
                elseif ai == "ylabel"
                    ac.ylabel = ai1
                elseif ai == "title"
                    ac.title = ai1
                elseif ai == "clim"
                        cmin = ai1[1]
                        cmax = ai1[2]
                        if !isa(cmin,Real) || !isa(cmax,Real)
                            error("Invalid limits specified")
                        else
                            Z -= cmin
                            Z[Z<0] = 0
                            Z *= 255/(cmax-cmin)
                            Z[Z>255] = 255
                        end
                else
                    error("Invalid property specified")
                end
                i = i+2
            end
        elseif state == "SEND"
            addconf(ac)
            llplot()
            break
        elseif state == "SERROR"
            error("Invalid arguments")
        else
            error("Unforseen situation, bailing out")
        end
    end
    return h
end

# surface plots
function surf(args...)
    global gnuplot_state
    # if args[1] is an integer, it's the figure handle.
    if isa(args[1], Int)
        h = args[1]
        args = args[2:end]   # argument parsing starts with 1 (eases debug)
    else
        h = gnuplot_state.current
    end
    h = figure(h,false) # create/select figure
    clearfigure(h)  # remove all figure configuration
    # parse arguments
    state = "SINI"
    la = length(args)
    while(true)
        if state == "SINI"
            i = 1
            cc = CurveConf()
            ac = AxesConf()
            state = "S1"
        elseif state == "S1"
            if i > la
                state = "SERROR"
                continue
            end
            tmp = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                Z = tmp
                if isa(Z,Array) && ndims(Z) == 2
                    y = 1:size(Z)[1]
                    x = 1:size(Z)[2]
                    state = "S3"
                else
                    state = "SERROR"
                end
            else
                if isa(args[i],AbstractString)
                    Z = tmp
                    if isa(Z,Array) && ndims(Z) == 2
                        y = 1:size(Z)[1]
                        x = 1:size(Z)[2]
                        state = "S6"
                    else
                        state = "SERROR"
                    end
                else
                    y = tmp
                    tmp = args[i]
                    i = i+1
                    state = "S4"
                end
            end
        elseif state == "S3"
            if isa(Z,Function)
                Z = meshgrid(x,y,Z)
            end
            addcoords(x,y,Z,cc)
            state = "SEND"
        elseif state == "S4"
            if i > la
                Z = tmp
                if isa(Z,Array) && ndims(Z) == 2
                    x = 1:size(Z)[2]
                    state = "S3"
                else
                    state = "SERROR"
                end
            else
                if isa(args[i],AbstractString)
                    Z = tmp
                    if isa(Z,Array) && ndims(Z) == 2
                        x = 1:size(Z)[2]
                        state = "S6"
                    else
                        state = "SERROR"
                    end
                else
                    x = tmp
                    tmp = args[i]
                    i = i+1
                    state = "S5"
                end
            end
        elseif state == "S5"
            Z = tmp
            if i > la
                state = "S3"
            else
                state = "S6"
            end
        elseif state == "S6"
            if i+1 > la
                state = "S3"
            else
                ai = args[i]; ai1 = args[i+1]
                if ai == "xlabel"
                    ac.xlabel = ai1
                elseif ai == "ylabel"
                    ac.ylabel = ai1
                elseif ai == "zlabel"
                    ac.zlabel = ai1
                elseif ai == "title"
                    ac.title = ai1
                elseif ai == "legend"
                    cc.legend = ai1
                elseif ai == "plotstyle"
                    cc.plotstyle = ai1
                elseif ai == "color"
                    cc.color = ai1
                elseif ai == "marker"
                    cc.marker = ai1
                elseif ai == "linewidth"
                    cc.linewidth = ai1
                elseif ai == "pointsize"
                    cc.pointsize = ai1
                elseif ai == "box"
                    ac.box = ai1
                elseif ai == "xrange"
                    ac.xrange = ai1
                elseif ai == "yrange"
                    ac.yrange = ai1
                elseif ai == "zrange"
                    ac.zrange = ai1
                else
                    error("Invalid property specified")
                end
                i = i+2
            end
        elseif state == "SEND"
            addconf(ac)
            llplot()
            break
        elseif state == "SERROR"
            error("Invalid arguments")
        else
            error("Unforseen situation, bailing out")
        end
    end
    return h
end

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


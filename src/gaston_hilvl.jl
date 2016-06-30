## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

function closefigure(x...)
    global gnuplot_state
    global gaston_config

    # parse argument
    if isempty(x)
        # close current figure
        h = gnuplot_state.current
    else
        h = x[1]
        if !(isa(h,Int) && h > 0)
            error("Invalid handle")
        end
    end

    term = gaston_config.terminal
    # create vector of handles
    handles = Any[]
    if gnuplot_state.current != 0
        for i in gnuplot_state.figs
            push!(handles, i.handle)
        end
    end
    if in(h, handles)
        # only care about closing windows if term type is screen
        if is_term_screen(term)
            if gnuplot_state.running
                gnuplot_send("set term $term $h close")
            end
        end
        # delete all data related to this figure
        _figs = Any[]
        for i in gnuplot_state.figs
            if i.handle != h
                push!(_figs, i)
            end
        end
        gnuplot_state.figs = _figs
        # update state
        if isempty(gnuplot_state.figs)
            # we just closed the last figure
            gnuplot_state.current = 0
        else
            # select the most-recently created figure
            gnuplot_state.current = gnuplot_state.figs[end].handle
        end
    else
        h = 0
    end
    return h
end

# close all figures
function closeall()
    global gnuplot_state

	closed = 0
	for i in gnuplot_state.figs
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
function figure(h::Int,redraw::Bool)
    global gnuplot_state
    global gaston_config

    term = gaston_config.terminal

    # assert h is non-negative
    @assert(h >= 0, "Figure handle must not be negative.")

    # see if we need to set up gnuplot
    if gnuplot_state.running == false
        gnuplot_init();
    end
    # create vector of handles, needed later
    handles = Any[]
    for i in gnuplot_state.figs
        push!(handles, i.handle)
    end
    # determine figure handle
    if gnuplot_state.current == 0
        if h == 0
            h = 1
        end
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
figure() = figure(0,true)
figure(h::Int) = figure(h,true)

# 2-d plots
function plot(args...)
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
            y = args[i]
            i = i+1
            state = "S2"
        elseif state == "S2"
            if i > la
                addcoords(y,cc)
                state = "SEND"
                continue
            end
            if isa(args[i], AbstractString)
                x = 1:length(y)
                state = "S4"
            else
                x = y
                y = args[i]
                i = i+1
                state = "S3"
            end
        elseif state == "S3"
            if i > la
                addcoords(x,y,cc)
                state = "SEND"
                continue
            end
            if isa(args[i], AbstractString)
                state = "S4"
            else
                addcoords(x,y,cc)
                cc = CurveConf()
                y = args[i]
                i = i+1
                state = "S2"
            end
        elseif state == "S4"
            if i+1 > la
                state = "SERROR"
                continue
            end
            ai = args[i]; ai1 = args[i+1]
            if ai == "legend"
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
            elseif ai == "axis"
                ac.axis = ai1
            elseif ai == "xrange"
                ac.xrange = ai1
            elseif ai == "yrange"
                ac.yrange = ai1
            else
                error("Invalid property specified")
            end
            i = i+2
            state = "S3"
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
                x = midpoints(x)
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
        if !is_term_file(term)
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
    set_terminal(term)
    figure(h)
    set_terminal(saveterm)
    # gnuplot is weird: this command is needed to close the output file
    gnuplot_send("set output")

    return h
end


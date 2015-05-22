## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# append x,y,z coordinates and configuration to current figure
function addcoords(x::Coord,y::Coord,Z::Array,conf::CurveConf)
    global gnuplot_state

    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end

    # check coordinates: dimensions, sizes and types
    nex = !isempty(x); ney = !isempty(y); neZ = !isempty(Z)
    # check types
    if nex
        @assert(eltype(x)<:Real,"Invalid coordinates")
    end
    if ney
        @assert(eltype(y)<:Real,"Invalid coordinates")
    end
    if neZ
        @assert(eltype(Z)<:Real,"Invalid coordinates")
        @assert(1 < ndims(Z) < 4,"Invalid coordinates")
    end
    # fill missing x, y coordinates when Z is not empty
    if neZ && !nex
        x = 1:size(Z,2)
    end
    if neZ && !ney
        y = 1:size(Z,1)
    end
    # if x,y are matrices, convert to vectors
    if isa(x,Matrix)
        s = size(x)
        if s[1] == 1 || s[2] == 1
            x = squeeze(x)
        else
            error("Invalid abscissa coordinates")
        end
    elseif isa(x,UnitRange) || isa(x,Range)
        x = collect(x)
    end
    if isa(y,Matrix)
        s = size(y)
        if s[1] == 1 || s[2] == 1
            y = squeeze(y)
        else
            error("Invalid abscissa coordinates")
        end
    elseif isa(y,UnitRange) || isa(y,Range)
        y = collect(y)
    end
    # check number of elements
    if neZ
        if conf.plotstyle == "image" || conf.plotstyle == "rgbimage"
            @assert(size(Z,2) == length(x), "Wrong number of columns in Z")
            @assert(size(Z,1) == length(y), "Wrong number of rows in Z")
        else
            @assert(size(Z,1) == length(x), "Wrong number of columns in Z")
            @assert(size(Z,2) == length(y), "Wrong number of rows in Z")
        end
    else
        @assert(length(x) == length(y),
        "Abscissa and ordinate must have the same number of elements")
    end

    # check curve configuration: property names
    # TODO: figure out how to check valid color names -- gnuplot supports
    #  112 different color names.
    # check valid values of marker
    @assert(validate_marker(conf.marker), "Invalid mark name specified")
    if nex && !neZ ## 2-d plot
        # check valid values of plotstyle
        @assert(validate_2d_plotstyle(conf.plotstyle),
            "Invalid plotstyle specified")
    elseif nex && neZ ## 3-d plot or image
        @assert(validate_3d_plotstyle(conf.plotstyle),
            "Invalid plotstyle specified")
    end

    conf = copy(conf)       # we need to dereference conf
    # append data to figure
    c = findfigure(gnuplot_state.current)
    fig = gnuplot_state.figs[c]
    if fig.isempty == true
        fig.curves[1] = CurveData(x,y,Z,conf)
        fig.isempty = false
    else
        push!(fig.curves, CurveData(x,y,Z,conf))
    end
    gnuplot_state.figs[c] = fig
end
addcoords(y) = addcoords(1:length(y),y,Any[],CurveConf())
addcoords(y,c::CurveConf) = addcoords(1:length(y),y,Any[],c)
addcoords(x,y) = addcoords(x,y,Any[],CurveConf())
addcoords(x,y,c::CurveConf) = addcoords(x,y,Any[],c)
addcoords(x,y,Z) = addcoords(x,y,Z,CurveConf())
# X, Y data in matrix columns
function addcoords(X::Matrix,Y::Matrix,conf::CurveConf)
    for i = 1:size(X,2)
        addcoords(X[:,i],Y[:,i],Any[],conf)
    end
end
function addcoords(Y::Matrix,conf::CurveConf)
    x = 1:size(Y,1)
    X = zeros(size(Y))
    for i = 1:size(Y,2)
        X[:,i] = x
    end
    addcoords(X,Y,conf)
end
addcoords(X::Matrix, Y::Matrix) = addcoords(X,Y,CurveConf())
addcoords(Y::Matrix) = addcoords(Y,CurveConf())

# append error data to current set of coordinates
function adderror(yl::Coord,yh::Coord)
    global gnuplot_state
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end
    c = findfigure(gnuplot_state.current)

    # check arguments and convert to vectors
    if isempty(yl)
        error("Invalid error data")
    else
        @assert(eltype(yl)<:Real,"Invalid error data")
        if isa(yl,Matrix)
            s = size(yl)
            if s[1] == 1 || s[2] == 1
                yl = squeeze(yl)
            else
                error("Invalid error data")
            end
        elseif isa(yl,UnitRange) || isa(yl,Range)
            yl = collect(yl)
        end
    end
    if !isempty(yh)
        @assert(eltype(yh)<:Real,"Invalid error data")
        if isa(yl,Matrix)
            s = size(yh)
            if s[1] == 1 || s[2] == 1
                yh = squeeze(yh)
            else
                error("Invalid error data")
            end
        elseif isa(yh,UnitRange) || isa(yh,Range)
            yh = collect(yh)
        end
    end
    # verify vector sizes -- this also implies that x,y coordinates must be
    # added to figure, before error data can be attached to it
    @assert(length(gnuplot_state.figs[c].curves[end].x) == length(yl),
        "Error data vector must be of same size as abscissa")
    if !isempty(yh)
        @assert(length(yh) == length(yl),
            "Error data vectors must be of same size")
    end

    # set fields in current curve
    gnuplot_state.figs[c].curves[end].ylow = yl
    gnuplot_state.figs[c].curves[end].yhigh = yh

end
adderror(ydelta) = adderror(ydelta,Any[])

# add axes configuration to current figure
function addconf(conf::AxesConf)
    global gnuplot_state
    # check that at least one figure has been setup
    if gnuplot_state.current == 0
        figure(1)
    end

    # Perform argument validation
    # TODO: find a way to validate the box argument
    # validate axis type
    @assert(validate_axis(conf.axis),"Invalid axis type specified")
    # validate ranges
    @assert(validate_range(conf.xrange),"Invalid xrange specified")
    @assert(validate_range(conf.yrange),"Invalid yrange specified")
    @assert(validate_range(conf.zrange),"Invalid zrange specified")

    conf = copy(conf)
    # select current plot
    c = findfigure(gnuplot_state.current)
    gnuplot_state.figs[c].conf = conf
end

# llplot() is our workhorse plotting function
function llplot()
    global gnuplot_state
    global gaston_config

    # select current plot
    c = findfigure(gnuplot_state.current)
    if c == 0
        println("No current figure")
        return
    end
    figs = gnuplot_state.figs
    config = figs[c].conf

    # Build terminal setup string and send it to gnuplot
    ts = termstring(gaston_config.terminal)
    gnuplot_send(ts)

    # if figure has no data, stop here
    if isempty(figs[c].curves[1].x)
        return
    end

    # datafile filename
    filename = "$(gnuplot_state.tmpdir)figure$(gnuplot_state.current).dat"

    # Send appropriate coordinates and data to gnuplot, depending on
    # whether we are doing 2-d, 3-d or image plots.

    # 2-d plot: Z is empty or plostyle is {,rgb}image
    if isempty(figs[c].curves[1].Z) ||
        figs[c].curves[1].conf.plotstyle == "image" ||
        figs[c].curves[1].conf.plotstyle == "rgbimage"
        # create data file
        f = open(filename,"w")
        for i in figs[c].curves
            ps = i.conf.plotstyle
            if ps == "errorbars" || ps == "errorlines"
                if isempty(i.yhigh)
                    # ydelta (single error coordinate)
                    writedlm(f,[i.x i.y i.ylow],' ')
                else
                    # ylow, yhigh (double error coordinate)
                    writedlm(f,[i.x i.y i.ylow i.yhigh],' ')
                end
            elseif ps == "image"
                # output matrix
                for col = 1:length(i.x)
                    y = length(i.y)
                    for row = 1:length(i.y)
                        writedlm(f,[i.x[col] i.y[row] i.Z[y,col]],' ')
                        y = y-1
                    end
                end
            elseif ps == "rgbimage"
                # output matrix
                for col = 1:length(i.x)
                    y = length(i.y)
                    for row = 1:length(i.y)
                        writedlm(f,
                        [i.x[col] i.y[row] i.Z[y,col,1] i.Z[y,col,2] i.Z[y,col,3]],
                        ' ')
                        y = y-1
                    end
                end
            else
                writedlm(f,[i.x i.y],' ')
            end
            write(f,"\n\n")
        end
        flush(f)
        close(f)
        # send figure configuration to gnuplot
        gnuplot_send_fig_config(config)
        # send plot command to gnuplot
        gnuplot_send(linestr(figs[c].curves, "plot", filename))

    # 3-d plot: Z is not empty and plotstyle is not {,rgb}image
    elseif !isempty(figs[c].curves[1].Z) &&
            figs[c].curves[1].conf.plotstyle != "image" &&
            figs[c].curves[1].conf.plotstyle != "rgbimage"
        # create data file
        f = open(filename,"w")
        for i in figs[c].curves
            for row in 1:length(i.x)
                for col in 1:length(i.y)
                    writedlm(f,[i.x[row] i.y[col] i.Z[row,col]],' ')
                end
                write(f,"\n")
            end
            write(f,"\n\n")
        end
        close(f)
        # send figure configuration to gnuplot
        gnuplot_send_fig_config(config)
        # send command to gnuplot
        gnuplot_send(linestr(figs[c].curves, "splot",filename))
    end
    gnuplot_send("reset")
end

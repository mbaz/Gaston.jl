# image plots
function imagesc(x::Coord,y::Coord,Z::Coord;
                 handle::Handle    = gnuplot_state.current,
                 clim::Vector{Int} = [0, 255],
                 args...)

    # process arguments
    PA = PlotArgs()
    for k in keys(args)
        # substitute synonyms
        key = k
        for s in syn
            key ∈ s && (key = s[1]; break)
        end
        # store arguments
        for f in fieldnames(PlotArgs)
            f == key && (setfield!(PA, f, string(args[k])); break)
        end
    end

    # validation
    valid_range(PA.xrange)
    valid_range(PA.yrange)
    length(clim) == 2 || throw(DomainError(length(clim), "clim must be a 2-element vector."))
    length(x) == Base.size(Z)[2] || throw(DimensionMismatch("invalid coordinates."))
    length(y) == Base.size(Z)[1] || throw(DimensionMismatch("invalid coordinates."))
    2 <= ndims(Z) <= 3 || throw(DimensionMismatch(ndims(Z), "Z must have two or three dimensions"))

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    ndims(Z) == 2 ? plotstyle = "image" : plotstyle = "rgbimage"
    if ndims(Z) == 3
        Z[:] = Z.-clim[1]
        Z[Z.<0] .= 0.0
        Z[:] = Z.*255.0/(clim[2]-clim[1])
        Z[Z.>255] .= 255
    end

    term = config[:term][:terminal]
    PA.font == "" && (PA.font = TerminalDefaults[term][:font])
    PA.size == "" && (PA.size = TerminalDefaults[term][:size])
    PA.background == "" && (PA.background = "white")

    tc = TermConf(font       = PA.font,
                  size       = PA.size,
                  background = "white")

    ac = AxesConf(title  = PA.title,
                  xlabel = PA.xlabel,
                  ylabel = PA.ylabel,
                  xrange = PA.xrange,
                  yrange = PA.yrange)

    cc = CurveConf(plotstyle = plotstyle)

    c = Curve(x    = x,
              y    = y,
              Z    = Z,
              conf = cc)

    push_figure!(handle,tc,ac,c,PA.gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

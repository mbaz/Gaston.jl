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
                 handle::Handle    = gnuplot_state.current
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
    c = Curve(x=x,y=y,Z=Z,conf=cc)

    push_figure!(handle,tc,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
imagesc(Z::Coord;args...) = imagesc(1:size(Z)[2],1:size(Z)[1],Z;args...)

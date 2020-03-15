# 3-D plot commands

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
              handle::Handle = gnuplot_state.current,
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

    # validation and defaults
    valid_3Dplotstyle(PA.plotstyle)
    valid_numeric(PA.linewidth)
    valid_linestyle(PA.linestyle)
    valid_pointtype(PA.pointtype)
    valid_numeric(PA.pointsize)
    valid_axis(PA.axis)
    valid_range(PA.xrange)
    valid_range(PA.yrange)
    valid_range(PA.zrange)

    if isa(Z, Matrix)
        if length(x) != Base.size(Z)[1] || length(y) != Base.size(Z)[2]
            throw(DimensionMismatch("invalid coordinates in surface plot."))
        end
    elseif isa(Z, Vector)
        if length(x) != length(y) || length(x) != length(Z)
            throw(DimensionMismatch("all coordinates must have the same dimension"))
        end
    else
        throw(DimensionMismatch("Z must be a matrix or a vector."))
    end

    term = config[:term][:terminal]
    PA.font == "" && (PA.font = TerminalDefaults[term][:font])
    PA.size == "" && (PA.size = TerminalDefaults[term][:size])
    PA.linewidth == "" && (PA.linewidth = "1")
    PA.background == "" && (PA.background = TerminalDefaults[term][:background])

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create curve
    tc = TermConf(font       = PA.font,
                  size       = PA.size,
                  background = PA.background)

    ac = AxesConf(title      = PA.title,
                  xlabel     = PA.xlabel,
                  ylabel     = PA.ylabel,
                  zlabel     = PA.zlabel,
                  keyoptions = PA.keyoptions,
                  xrange     = PA.xrange,
                  yrange     = PA.yrange,
                  zrange     = PA.zrange,
                  xzeroaxis  = PA.xzeroaxis,
                  yzeroaxis  = PA.yzeroaxis,
                  zzeroaxis  = PA.zzeroaxis,
                  palette    = PA.palette)

    cc = CurveConf(plotstyle = PA.plotstyle,
                   legend    = PA.legend,
                   linecolor = PA.linecolor,
                   pointtype = PA.pointtype,
                   linewidth = PA.linewidth,
                   pointsize = PA.pointsize)

    c = Curve(x    = x,
              y    = y,
              Z    = Z,
              conf = cc)

    # push curve we just created to current figure
    push_figure!(handle,tc,ac,c,PA.gpcom)

    return gnuplot_state.figs[findfigure(handle)]
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

function surf!(x::Coord,y::Coord,Z::Coord;
               handle::Handle = gnuplot_state.current,
               args...)

    # process arguments
    PA = PlotArgs()
    for k in keys(args)
        for f in fieldnames(PlotArgs)
            k == f && setfield!(PA, f, string(args[k]))
        end
    end
    # validation and defaults
    valid_3Dplotstyle(PA.plotstyle)
    valid_linestyle(PA.linestyle)
    valid_pointtype(PA.pointtype)
    valid_numeric(PA.pointsize)
    valid_pointtype(PA.pointtype)
    valid_numeric(PA.linewidth)

    if isa(Z, Matrix)
        if length(x) != Base.size(Z)[1] || length(y) != Base.size(Z)[2]
            throw(DimensionMismatch("invalid coordinates in surface plot."))
        end
    elseif isa(Z, Vector)
        if length(x) != length(y) || length(x) != length(Z)
            throw(DimensionMismatch("all coordinates must have the same dimension"))
        end
    else
        throw(DimensionMismatch("Z must be a matrix or a vector."))
    end

    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)

    # configure curve
    cc = CurveConf(plotstyle = PA.plotstyle,
                   legend    = PA.legend,
                   linecolor = PA.linecolor,
                   pointtype = PA.pointtype,
                   linewidth = PA.linewidth,
                   pointsize = PA.pointsize)

    c = Curve(x    = x,
              y    = y,
              Z    = Z,
              conf = cc)

    push_figure!(handle,c)

    return gnuplot_state.figs[findfigure(handle)]
end
surf!(x::Coord,y::Coord,f::Function;args...) = surf!(x,y,meshgrid(x,y,f);args...)
surf!(Z::Matrix;args...) = surf!(1:size(Z)[2],1:size(Z)[1],Z;args...)

function contour(x::Coord,y::Coord,Z::Coord;labels=true,args...)
    gp = """unset key
            set view map
            set contour base
            unset surface
            set cntrlabel font ",7"
            set cntrparam levels 10"""
    p = surf(x,y,Z;gpcom=gp,args...)
    labels && (p = surf!(x,y,Z;plotstyle="labels"))
    return p
end
contour(x::Coord,y::Coord,f::Function;args...) = contour(x,y,meshgrid(x,y,f);args...)
contour(Z::Matrix;args...) = contour(1:size(Z)[2],1:size(Z)[1],Z;args...)

scatter3(x::Coord,y::Coord,Z::Coord;args...) = surf(x,y,Z,plotstyle="points";args...)
scatter3!(x::Coord,y::Coord,Z::Coord;args...) = surf!(x,y,Z,plotstyle="points";args...)

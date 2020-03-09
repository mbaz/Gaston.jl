# 3-D plot commands

# surface plots
function surf(x::Coord,y::Coord,Z::Coord;
              legend::String     = "",
              title::String      = "",
              xlabel::String     = "",
              ylabel::String     = "",
              zlabel::String     = "",
              plotstyle::String  = config[:curve][:plotstyle],
              linecolor::String  = config[:curve][:linecolor],
              linewidth::String  = "1",
              pointtype::String  = config[:curve][:pointtype],
              pointsize::String  = config[:curve][:pointsize],
              keyoptions::String = config[:axes][:keyoptions],
              xrange::String     = config[:axes][:xrange],
              yrange::String     = config[:axes][:yrange],
              zrange::String     = config[:axes][:zrange],
              xzeroaxis::String  = config[:axes][:xzeroaxis],
              yzeroaxis::String  = config[:axes][:yzeroaxis],
              zzeroaxis::String  = config[:axes][:zzeroaxis],
              palette::String    = config[:axes][:palette],
              font::String       = config[:term][:font],
              size::String       = config[:term][:size],
              background::String = config[:term][:background],
              handle::Handle     = gnuplot_state.current,
              gpcom::String      = ""
              )
    # validation
    valid_3Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    valid_range(xrange)
    valid_range(yrange)
    valid_range(zrange)
    if isa(Z, Matrix)
        length(x) == Base.size(Z)[1] ||
            throw(DimensionMismatch("invalid X coordinates in surface plot."))
        length(y) == Base.size(Z)[2]  ||
            throw(DimensionMismatch("Invalid Y coordinates in surface plot."))
    elseif isa(Z, Coord)
        length(x) == length(y) || throw(DimensionMismatch("in a 3D scatter plot, all coordinates must have the same dimension."))
        length(x) == length(Z) || throw(DimensionMismatch("in a 3D scatter plot, all coordinates must have the same dimension."))
    else
        throw(DimensionMismatch("Z must be a matrix or a vector."))
    end

    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
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
                  palette = palette)
    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    background == "" && (background = TerminalDefaults[term][:background])
    tc = TermConf(font,size,"1",background)
    cc = CurveConf(plotstyle = plotstyle,
                   legend = legend,
                   linecolor = linecolor,
                   pointtype = pointtype,
                   linewidth = linewidth,
                   pointsize = pointsize)
    c = Curve(x=x,y=y,Z=Z,conf=cc)
    push_figure!(handle,tc,ac,c,gpcom)
    return gnuplot_state.figs[findfigure(handle)]
end
surf(x::Coord,y::Coord,f::Function;args...) = surf(x,y,meshgrid(x,y,f);args...)
surf(Z::Matrix;args...) = surf(1:size(Z)[2],1:size(Z)[1],Z;args...)

function surf!(x::Coord,y::Coord,Z::Coord;
      legend::String     = "",
      plotstyle::String  = config[:curve][:plotstyle],
      linecolor::String  = config[:curve][:linecolor],
      linewidth::String  = "1",
      pointtype::String  = config[:curve][:pointtype],
      pointsize::String  = config[:curve][:pointsize],
      handle::Handle     = gnuplot_state.current
     )
    valid_3Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    if isa(Z, Matrix)
        length(x) == Base.size(Z)[1] ||
        throw(DimensionMismatch("invalid X coordinates in surface plot."))
        length(y) == Base.size(Z)[2]  ||
        throw(DimensionMismatch("Invalid Y coordinates in surface plot."))
    elseif isa(Z, Coord)
        length(x) == length(y) || throw(DimensionMismatch("in a 3D scatter plot, all coordinates must have the same dimension."))
        length(x) == length(Z) || throw(DimensionMismatch("in a 3D scatter plot, all coordinates must have the same dimension."))
    else
        throw(DimensionMismatch("Z must be a matrix or a vector."))
    end
    handles =gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)
    cc = CurveConf(plotstyle = plotstyle,
                   legend = legend,
                   linecolor = linecolor,
                   pointtype = pointtype,
                   linewidth = linewidth,
                   pointsize = pointsize)
    c = Curve(x=x,y=y,Z=Z,conf=cc)
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



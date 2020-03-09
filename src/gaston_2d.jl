# 2D plots
function plot(x::Coord,y::Coord;
             legend::String     = "",
             title::String      = "",
             xlabel::String     = "",
             ylabel::String     = "",
             plotstyle::String  = config[:curve][:plotstyle],
             linecolor::String  = config[:curve][:linecolor],
             linewidth::String  = "1",
             linestyle::String  = config[:curve][:linestyle],
             pointtype::String  = config[:curve][:pointtype],
             pointsize::String  = config[:curve][:pointsize],
             fillcolor::String  = config[:curve][:fillcolor],
             fillstyle::String  = config[:curve][:fillstyle],
             grid::String       = config[:axes][:grid],
             boxwidth::String   = config[:axes][:boxwidth],
             keyoptions::String = config[:axes][:keyoptions],
             axis::String       = config[:axes][:axis],
             xrange::String     = config[:axes][:xrange],
             yrange::String     = config[:axes][:yrange],
             xzeroaxis::String  = config[:axes][:xzeroaxis],
             yzeroaxis::String  = config[:axes][:yzeroaxis],
             font::String       = config[:term][:font],
             size::String       = config[:term][:size],
             background::String = config[:term][:background],
             financial::FCuN    = FinancialCoords(),
             err::ECuN          = ErrorCoords(),
             handle::Handle     = gnuplot_state.current,
             gpcom::String      = ""
            )
    # validation
    valid_2Dplotstyle(plotstyle)
    valid_linestyle(linestyle)
    valid_pointtype(pointtype)
    valid_axis(axis)
    valid_range(xrange)
    valid_range(yrange)
    valid_coords(x,y,err=err,fin=financial)

    term = config[:term][:terminal]
    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    linewidth == "" && (linewidth = "1")
    background == "" && (background = TerminalDefaults[term][:background])

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create figure configuration
    tc = TermConf(font,size,linewidth,background)
    ac = AxesConf(title = title,
                  xlabel = xlabel,
                  ylabel = ylabel,
                  grid = grid,
                  boxwidth = boxwidth,
                  keyoptions = keyoptions,
                  axis = axis,
                  xrange = xrange,
                  yrange = yrange,
                  xzeroaxis = xzeroaxis,
                  yzeroaxis = yzeroaxis,
                 )
    cc = CurveConf(legend,plotstyle,linecolor,linewidth,
                   linestyle,pointtype,pointsize,fillstyle,fillcolor)
    c = Curve(x=x,y=y,F=financial,E=err,conf=cc)
    push_figure!(handle,tc,ac,c,gpcom)

    return gnuplot_state.figs[findfigure(handle)]
end
plot(y::Coord;args...) = plot(1:length(y),y;args...)
plot(x::Real,y::Real;args...) = plot([x],[y];args...)  # plot a single point
# plot complex inputs
plot(c::Complex;args...) = plot(real(c),imag(c);args...)
plot(c::ComplexCoord;args...) = plot(real(c),imag(c);args...)

# plot a matrix
plot(M::Matrix;args...) = plot(1:size(M)[1],M;args...)

function plot(x::Coord,M::Matrix;
             legend     = "",
             title      = "",
             xlabel     = "",
             ylabel     = "",
             plotstyle  = config[:curve][:plotstyle],
             linecolor  = config[:curve][:linecolor],
             linewidth  = "1",
             linestyle  = config[:curve][:linestyle],
             pointtype  = config[:curve][:pointtype],
             pointsize  = config[:curve][:pointsize],
             fillcolor  = config[:curve][:fillcolor],
             fillstyle  = config[:curve][:fillstyle],
             grid       = config[:axes][:grid],
             boxwidth   = config[:axes][:boxwidth],
             keyoptions = config[:axes][:keyoptions],
             axis       = config[:axes][:axis],
             xrange     = config[:axes][:xrange],
             yrange     = config[:axes][:yrange],
             xzeroaxis  = config[:axes][:xzeroaxis],
             yzeroaxis  = config[:axes][:yzeroaxis],
             font       = config[:term][:font],
             size       = config[:term][:size],
             background = config[:term][:background],
             financial  = FinancialCoords(),
             err        = ErrorCoords(),
             handle::Handle     = gnuplot_state.current,
             gpcom::String      = ""
             )
    legend isa Vector{String} && (lg = legend)
    legend isa String && (lg = [legend])
    lgn = length(lg)
    plotstyle isa Vector{String} && (ps = plotstyle)
    plotstyle isa String && (ps = [plotstyle])
    psn = length(ps)
    linecolor isa Vector{String} && (lc = linecolor)
    linecolor isa String && (lc = [linecolor])
    lcn = length(lc)
    linewidth isa Vector{String} && (lw = linewidth)
    linewidth isa String && (lw = [linewidth])
    lwn = length(lw)
    linestyle isa Vector{String} && (ls = linestyle)
    linestyle isa String && (ls = [linestyle])
    lsn = length(ls)
    pointtype isa Vector{String} && (pt = pointtype)
    pointtype isa String && (pt = [pointtype])
    ptn = length(pt)
    pointsize isa Vector{String} && (pz = pointsize)
    pointsize isa String && (pz = [pointsize])
    pzn = length(pz)
    fillcolor isa Vector{String} && (fc = fillcolor)
    fillcolor isa String && (fc = [fillcolor])
    fcn = length(fc)
    fillstyle isa Vector{String} && (fs = fillstyle)
    fillstyle isa String && (fs = [fillstyle])
    fsn = length(fs)
    boxwidth isa Vector{String} && (bw = boxwidth)
    boxwidth isa String && (bw = [boxwidth])
    bwn = length(bw)
    financial isa Vector{FCuN} && (fn = financial)
    financial isa FCuN && (fn = [financial])
    fnn = length(fn)
    err isa Vector{ECuN} && (er = err)
    err isa ECuN && (er = [err])
    ern = length(er)

    ans = plot(x,M[:,1],
               legend = lg[1],
               plotstyle = ps[1],
               linecolor = lc[1],
               linewidth = lw[1],
               linestyle = ls[1],
               pointtype = pt[1],
               pointsize = pz[1],
               fillcolor = fc[1],
               fillstyle = fs[1],
               boxwidth = bw[1],
               financial = fn[1],
               err = er[1],
               title = title,
               xlabel = xlabel,
               ylabel = ylabel,
               grid = grid,
               keyoptions = keyoptions,
               axis = axis,
               xrange = xrange,
               yrange = yrange,
               xzeroaxis = xzeroaxis,
               yzeroaxis = yzeroaxis,
               font = font,
               size = size,
               background = background,
               handle = handle,
               gpcom = gpcom
              )

    for col in 2:Base.size(M)[2]
        ans = plot!(x,M[:,col],
                    legend = lg[(col-1)%lgn+1],
                    plotstyle = ps[(col-1)%psn+1],
                    linecolor = lc[(col-1)%lcn+1],
                    linewidth = lw[(col-1)%lwn+1],
                    linestyle = ls[(col-1)%lsn+1],
                    pointtype = pt[(col-1)%ptn+1],
                    pointsize = pz[(col-1)%pzn+1],
                    fillcolor = fc[(col-1)%fcn+1],
                    fillstyle = fs[(col-1)%fsn+1],
                    financial = fn[(col-1)%fnn+1],
                    err = er[(col-1)%ern+1],
                    handle = handle)
    end
    return ans
end

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord;
             legend::String    = "",
             plotstyle::String = config[:curve][:plotstyle],
             linecolor::String = config[:curve][:linecolor],
             linewidth::String = "1",
             linestyle::String = config[:curve][:linestyle],
             pointtype::String = config[:curve][:pointtype],
             pointsize::String = config[:curve][:pointsize],
             fillcolor::String  = config[:curve][:fillcolor],
             fillstyle::String  = config[:curve][:fillstyle],
             financial::FCuN = FinancialCoords(),
             err::ECuN       = ErrorCoords(),
             handle::Handle  = gnuplot_state.current
         )

    # validation
    valid_2Dplotstyle(plotstyle)
    valid_pointtype(pointtype)
    valid_linestyle(linestyle)
    valid_coords(x,y,err=err,fin=financial)

    # verify that handle exists
    handles =gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)
    cc = CurveConf(legend,plotstyle,linecolor,linewidth,linestyle,pointtype,
                   pointsize,fillstyle,fillcolor)
    c = Curve(x=x,y=y,F=financial,E=err,conf=cc)
    push_figure!(handle,c)
    return gnuplot_state.figs[findfigure(handle)]
end
plot!(y::Coord;args...) = plot!(1:length(y),y;args...)
plot!(x::Real,y::Real;args...) = plot!([x],[y];args...)
plot!(c::Complex;args...) = plot!(real(c),imag(c);args...)
plot!(c::ComplexCoord;args...) = plot!(real(c),imag(c);args...)

scatter(y::ComplexCoord;args...) = scatter(real(y),imag(y);args...)

function scatter(x::Coord,y::Coord;
                 handle::Handle = gnuplot_state.current,
                 args...)
    plot(x,y,plotstyle="points",handle=handle;args...)
end

scatter!(y::ComplexCoord;args...) = scatter!(real(y),imag(y);args...)
scatter!(x::Coord,y::Coord;handle::Handle = gnuplot_state.current,args...) =
    plot!(x,y,plotstyle="points";handle=handle,args...)

function stem(x::Coord,y::Coord;
              onlyimpulses = config[:axes][:onlyimpulses],
              handle::Handle = gnuplot_state.current, args...)
    p = plot(x,y;handle=handle,
             plotstyle="impulses", linecolor="blue",linewidth="1.25",args...)
    onlyimpulses || (p = plot!(x,y;plotstyle="points", linecolor="blue",
                               pointtype="ecircle", pointsize="1.5",args...))
    return p
end
function stem(y;handle=gnuplot_state.current,
              onlyimpulses=config[:axes][:onlyimpulses],args...)
    stem(1:length(y),y;handle=handle,onlyimpulses=onlyimpulses,args...)
end

function bar(x::Coord,y::Coord;
             handle::Handle = gnuplot_state.current, args...)
    plot(x,y; handle=handle,
         plotstyle="boxes",boxwidth="0.8 relative",fillstyle="solid 0.5",args...)
end
bar(y;handle=gnuplot_state.current,args...) = bar(1:length(y),y;handle=handle,args...)



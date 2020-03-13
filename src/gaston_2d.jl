# 2D plots
function plot(x::Coord, y::Coord;
              financial::FCuN = FinancialCoords(),
              err::ECuN = ErrorCoords(),
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
    valid_2Dplotstyle(PA.plotstyle)
    valid_linestyle(PA.linestyle)
    valid_pointtype(PA.pointtype)
    valid_axis(PA.axis)
    valid_range(PA.xrange)
    valid_range(PA.yrange)
    valid_coords(x,y,err=err,fin=financial)
    term = config[:term][:terminal]
    PA.font == "" && (PA.font = TerminalDefaults[term][:font])
    PA.size == "" && (PA.size = TerminalDefaults[term][:size])
    PA.linewidth == "" && (PA.linewidth = "1")
    PA.background == "" && (PA.background = TerminalDefaults[term][:background])

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create curve
    tc = TermConf(font       = PA.font,
                  size       = PA.size,
                  linewidth  = PA.linewidth,
                  background = PA.background)

    ac = AxesConf(title      = PA.title,
                  xlabel     = PA.xlabel,
                  ylabel     = PA.ylabel,
                  grid       = PA.grid,
                  boxwidth   = PA.boxwidth,
                  keyoptions = PA.keyoptions,
                  axis       = PA.axis,
                  xrange     = PA.xrange,
                  yrange     = PA.yrange,
                  xzeroaxis  = PA.xzeroaxis,
                  yzeroaxis  = PA.yzeroaxis,
                 )

    cc = CurveConf(legend    = PA.legend,
                   plotstyle = PA.plotstyle,
                   linecolor = PA.linecolor,
                   linewidth = PA.linewidth,
                   linestyle = PA.linestyle,
                   pointtype = PA.pointtype,
                   pointsize = PA.pointsize,
                   fillstyle = PA.fillstyle,
                   fillcolor = PA.fillcolor)

    c = Curve(x    = x,
              y    = y,
              F    = financial,
              E    = err,
              conf = cc)

    # push curve we just created to current figure
    push_figure!(handle,tc,ac,c,PA.gpcom)

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
              linewidth  = "1",
              plotstyle  = config[:curve][:plotstyle],
              linecolor  = config[:curve][:linecolor],
              linestyle  = config[:curve][:linestyle],
              pointtype  = config[:curve][:pointtype],
              pointsize  = config[:curve][:pointsize],
              fillcolor  = config[:curve][:fillcolor],
              fillstyle  = config[:curve][:fillstyle],
              financial  = FinancialCoords(),
              err        = ErrorCoords(),
              handle     = gnuplot_state.current,
              args...)

    # the following arguments need to be vectors
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
    financial isa Vector{FCuN} && (fn = financial)
    financial isa FCuN && (fn = [financial])
    fnn = length(fn)
    err isa Vector{ECuN} && (er = err)
    err isa ECuN && (er = [err])
    ern = length(er)

    # plot first columnt
    ans = plot(x,M[:,1],
               legend    = lg[1],
               plotstyle = ps[1],
               linecolor = lc[1],
               linewidth = lw[1],
               linestyle = ls[1],
               pointtype = pt[1],
               pointsize = pz[1],
               fillcolor = fc[1],
               fillstyle = fs[1],
               financial = fn[1],
               err       = er[1],
               handle    = handle;
               args...)
    # plot subsequent columns
    for col in 2:Base.size(M)[2]
        ans = plot!(x,M[:,col];
                    legend    = lg[(col-1)%lgn+1],
                    plotstyle = ps[(col-1)%psn+1],
                    linecolor = lc[(col-1)%lcn+1],
                    linewidth = lw[(col-1)%lwn+1],
                    linestyle = ls[(col-1)%lsn+1],
                    pointtype = pt[(col-1)%ptn+1],
                    pointsize = pz[(col-1)%pzn+1],
                    fillcolor = fc[(col-1)%fcn+1],
                    fillstyle = fs[(col-1)%fsn+1],
                    financial = fn[(col-1)%fnn+1],
                    err       = er[(col-1)%ern+1],
                    handle    = gnuplot_state.current)
    end
    return ans
end

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord;
             financial::FCuN = FinancialCoords(),
             err::ECuN       = ErrorCoords(),
             handle::Handle  = gnuplot_state.current,
             args...
         )

    # process arguments
    PA = Plot!Args()
    for k in keys(args)
        for f in fieldnames(PlotArgs)
            k == f && setfield!(PA, f, string(args[k]))
        end
    end
    # validation
    valid_2Dplotstyle(PA.plotstyle)
    valid_pointtype(PA.pointtype)
    valid_linestyle(PA.linestyle)
    valid_coords(x,y,err=err,fin=financial)
    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)

    # create new curve
    cc = CurveConf(legend    = PA.legend,
                   plotstyle = PA.plotstyle,
                   linecolor = PA.linecolor,
                   linewidth = PA.linewidth,
                   linestyle = PA.linestyle,
                   pointtype = PA.pointtype,
                   pointsize = PA.pointsize,
                   fillstyle = PA.fillstyle,
                   fillcolor = PA.fillcolor)

    c = Curve(x    = x,
              y    = y,
              F    = financial,
              E    = err,
              conf = cc)

    # push new curve to current figure
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

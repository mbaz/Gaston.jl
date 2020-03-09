## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# This file contains exported, high-level commands

""""Close one or more figures. Returns a handle to the active figure,
or `nothing` if all figures were closed."""
function closefigure(x::Vararg{Int})

    isempty(x) && (x = gnuplot_state.current)
    curr = 0

    for handle ∈ x
        handles = gethandles()
        # make sure handle is valid
        handle < 1 && throw(DomainError(handle, "handle must be a positive integer"))
        isempty(handles) && return nothing
        handle ∈ handles || continue

        curr = closesinglefigure(handle)
    end

    return curr
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

#=
Select a figure, creating it if it doesn't exist. When called with no
arguments or with h=0, create and select a new figure with next available
handle. Figure handles must be natural numbers.

When selecting a figure that must not be redrawn (e.g. because it will be
immediately overwritten), set redraw = false.

Returns the current figure handle.
=#
function figure(h::Handle = 0; redraw = true)
    global gnuplot_state

    # build vector of handles
    handles = gethandles()

    # make sure handle is valid
    h == nothing && (h = 0)
    if !isa(h,Int) || h < 0
        throw(DomainError(h,"handle must be a positive integer or 0"))
    end

    # determine figure handle
    h == 0 && (h = nexthandle())
    # set current figure to h
    gnuplot_state.current = h
    if !in(h, handles)
        # figure does not exist: create it and store it
        push!(gnuplot_state.figs, Figure(h))
    else
        # when selecting a pre-existing window, gnuplot requires that it be
        # redrawn in order to have mouse interactivity. Also, we want to
        # display the figure again if it was closed.
        i = findfigure(h)
        fig = gnuplot_state.figs[i]
        redraw && display(fig)
    end
    return h
end

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

function histogram(data::Coord;bins::Int=10,norm::Real=1.0,args...)
    # validation
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))

    x, y = hist(data,bins)
    y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm

    bar(x, y; boxwidth="0.9 relative", fillstyle="solid 0.5",args...)
end

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
    ndims(Z) == 2 || throw(DimensionMismatch("Z must have two dimensions."))
    length(x) == Base.size(Z)[1] || throw(DimensionMismatch("invalid coordinates."))
    length(y) == Base.size(Z)[2]  || throw(DimensionMismatch("Invalid coordinates."))
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


# print a figure to a file
function printfigure(;handle::Handle    = gnuplot_state.current,
                     term::String       = config[:print][:print_term],
                     font::String       = config[:print][:print_font],
                     size::String       = config[:print][:print_size],
                     linewidth::String  = config[:print][:print_linewidth],
                     background::String = config[:print][:print_background],
                     outputfile::String = config[:print][:print_outputfile]
                    )

    # disable this command in IJulia
    # TODO: see if it's desirable and/or possible to re-enable it
    IsJupyterOrJuno && error("printfigure command disabled in Jupyter notebook.")

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    isempty(outputfile) && throw(DomainError("Please specify an output filename."))

    # set figure's print parameters
    term == "pdf" && (term = "pdfcairo")
    term == "png" && (term = "pngcairo")
    term == "eps" && (term = "epscairo")
    valid_file_term(term)

    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    linewidth == "" && (linewidth = "1")
    background == "" && (background = TerminalDefaults[term][:background])

    fig = gnuplot_state.figs[h]
    pc = PrintConf(term,font,size,linewidth,background,outputfile)
    fig.print = pc
    llplot(fig,print=true)
    gnuplot_send("set output") # gnuplot needs this to close the output file

    return nothing
end


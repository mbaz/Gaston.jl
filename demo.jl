
function demo()
    closeall()

    t = -2:0.01:2
    st = sin(10pi*t)
    ct = cos(10pi*t)
    et = exp(abs(t/10))
    # simplest figure
    figure(1)
    addcurve(st)
    plot()

    # x coordinates
    figure(2)
    addcurve(t,st)
    plot()

    # plot configuration
    figure(3)
    c = Curve_conf()
    c.legend = "Sinusoidal"
    c. plotstyle = "points"
    c.color = "blue"
    c.marker = "fdmd"
    c.pointsize = 2
    c.linewidth = 1.5
    addcurve(t,st,c)
    plot()

    # figure configuration
    figure(4)
    a = Axes_conf()
    a.title = "Julia and Gnuplot demo"
    a.xlabel = "Time (s)"
    a.ylabel = "Amplitude"
    a.box = "bottom left"
    a.axis = "semilogx"
    c.plotstyle = "linespoints"
    addcurve(t,st,c)
    addconf(a)
    plot()

    # multiple plots
    figure(5)
    c = Curve_conf()
    c.legend = "Sin"
    c.color = "black"
    addcurve(t,st,c)
    c.legend = "Cos"
    c.color = "magenta"
    c.plotstyle = "impulses"
    c.linewidth = 0.4
    addcurve(t,ct,c)
    c.legend = "Exp"
    c.color = "red"
    c.plotstyle = "linespoints"
    addcurve(t,et,c)
    a = Axes_conf()
    a.xlabel = "Time (s)"
    a.ylabel = "Amplitude"
    a.title = "Multiple plots demo"
    a.box = "outside top horizontal box"
    addconf(a)
    plot()

    # error bars with ydelta
    figure(6)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    addcurve(1:40,exp(-(1:.1:4.9)),0.1*rand(40),c)
    a = Axes_conf()
    a.title = "Error bars (ydelta)"
    addconf(a)
    plot()

    # error bars with ylow, yhigh
    figure(7)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    y = exp(-(1:.1:4.9))
    ylow = y - 0.05*rand(40);
    yhigh = y + 0.05*rand(40);
    addcurve(1:40,y,ylow,yhigh,c)
    a = Axes_conf()
    a.title = "Error bars (ylow, yhigh)"
    addconf(a)
    plot()

    # error lines
    figure(8)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorlines"
    addcurve(1:40,exp(-(1:.1:4.9)),0.1*rand(40),c)
    a = Axes_conf()
    a.title = "Error lines (ydelta)"
    addconf(a)
    plot()

end

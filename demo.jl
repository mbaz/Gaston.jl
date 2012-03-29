
function demo()
    closeall()

    t = -2:0.01:2
    st = sin(10pi*t)
    ct = cos(10pi*t)
    et = exp(abs(t/10))
    # simplest figure
    figure(1)
    addcoords(st)
    plot()

    # x coordinates
    figure(2)
    addcoords(t,st)
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
    addcoords(t,st,c)
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
    addcoords(t,st,c)
    addconf(a)
    plot()

    # multiple plots
    figure(5)
    c = Curve_conf()
    c.legend = "Sin"
    c.color = "black"
    addcoords(t,st,c)
    c.legend = "Cos"
    c.color = "magenta"
    c.plotstyle = "impulses"
    c.linewidth = 0.4
    addcoords(t,ct,c)
    c.legend = "Exp"
    c.color = "red"
    c.plotstyle = "linespoints"
    addcoords(t,et,c)
    a = Axes_conf()
    a.xlabel = "Time (s)"
    a.ylabel = "Amplitude"
    a.title = "Multiple plots demo"
    a.box = "outside top horizontal box"
    addconf(a)
    plot()

    # error bars with ydelta
    y = exp(-(1:.1:4.9))
    figure(6)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    addcoords(1:40,y,c)
    adderror(0.1*rand(40))
    a = Axes_conf()
    a.title = "Error bars (ydelta)"
    addconf(a)
    plot()

    # error bars with ylow, yhigh
    figure(7)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    ylow = y - 0.05*rand(40);
    yhigh = y + 0.05*rand(40);
    addcoords(1:40,y,c)
    ylow = y - 0.05*rand(40);
    yhigh = y + 0.05*rand(40);
    adderror(ylow,yhigh)
    a = Axes_conf()
    a.title = "Error bars (ylow, yhigh)"
    addconf(a)
    plot()

    # error lines
    figure(8)
    c = Curve_conf()
    c.legend = "Random"
    c.plotstyle = "errorlines"
    addcoords(1:40,y,c)
    adderror(0.1*rand(40))
    a = Axes_conf()
    a.title = "Error lines (ydelta)"
    addconf(a)
    plot()

    # plotting columns of matrices
    figure(9)
    Y = hcat(st, ct, et)
    X = hcat(t, t, t)
    addcoords(X,Y)
    a = Axes_conf()
    a.title = "Plotting matrix columns"
    addconf(a)
    plot()

    # simple 3-D plot with default config
    figure(10)
    x=[0,1,2,3]
    y=[0,1,2]
    Z=[10 10 10; 10 5 10;10 1 10; 10 0 10]
    addcoords(x,y,Z)
    a = Axes_conf()
    a.title = "Valley of the Gnu from gnuplot manual"
    addconf(a)
    plot()

    # same plot with colored surfaces
    figure(11)
    c = Curve_conf()
    c.plotstyle = "pm3d"
    addcoords(x,y,Z,c)
    a = Axes_conf()
    a.title = "Valley of the Gnu with pm3d"
    addconf(a)
    plot()

    # sombrero
    figure(12)
    c = Curve_conf()
    c.plotstyle = "pm3d"
    x = -15:0.33:15
    y = -15:0.33:15
    Z = meshgrid(x,y,(x,y)->sin(sqrt(x.*x+y.*y))/sqrt(x.*x+y.*y))
    addcoords(x,y,Z,c)
    a = Axes_conf()
    a.title = "Sombrero"
    addconf(a)
    plot()

    # simple image
    figure(13)
    c = Curve_conf()
    c.plotstyle = "image"
    Z = [5 4 3 1 0; 2 2 0 0 1; 0 0 0 1 0; 0 1 2 4 3]
    addcoords([],[],Z,c)
    a = Axes_conf()
    a.title = "Image"
    addconf(a)
    plot()

end

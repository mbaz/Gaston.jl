## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

function gaston_demo()
    closeall()

    t = -2:0.01:2
    st = sin(10pi*t)
    ct = cos(10pi*t)
    et = exp(abs(t/10))

    # simplest figure
    figure(1)
    addcoords(st)
    llplot()

    # with x coordinates
    figure(2)
    addcoords(t,st)
    llplot()

    # plot configuration
    figure(3)
    c = CurveConf()
    c.legend = "Sinusoidal"
    c. plotstyle = "points"
    c.color = "blue"
    c.marker = "fdmd"
    c.pointsize = 2
    c.linewidth = 1.5
    addcoords(t,st,c)
    llplot()

    # figure configuration
    figure(4)
    a = AxesConf()
    a.title = "Example of figure configuration"
    a.xlabel = "Time (s)"
    a.ylabel = "Amplitude"
    a.box = "bottom left"
    a.axis = "semilogx"
    c.plotstyle = "linespoints"
    addcoords(t,st,c)
    addconf(a)
    llplot()

    # multiple plots
    figure(5)
    c = CurveConf()
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
    a = AxesConf()
    a.xlabel = "Time (s)"
    a.ylabel = "Amplitude"
    a.title = "Multiple plots in the same figure"
    a.box = "outside top horizontal box"
    addconf(a)
    llplot()

    # error bars with ydelta
    y = exp(-(1:.1:4.9))
    figure(6)
    c = CurveConf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    addcoords(1:40,y,c)
    adderror(0.1*rand(40))
    a = AxesConf()
    a.title = "Error bars (ydelta)"
    addconf(a)
    llplot()

    # error bars with ylow, yhigh
    figure(7)
    c = CurveConf()
    c.legend = "Random"
    c.plotstyle = "errorbars"
    ylow = y - 0.05*rand(40);
    yhigh = y + 0.05*rand(40);
    addcoords(1:40,y,c)
    ylow = y - 0.05*rand(40);
    yhigh = y + 0.05*rand(40);
    adderror(ylow,yhigh)
    a = AxesConf()
    a.title = "Error bars (ylow, yhigh)"
    addconf(a)
    llplot()

    # error lines
    figure(8)
    c = CurveConf()
    c.legend = "Random"
    c.plotstyle = "errorlines"
    addcoords(1:40,y,c)
    adderror(0.1*rand(40))
    a = AxesConf()
    a.title = "Error lines (ydelta)"
    addconf(a)
    llplot()

    # finance bars
    figure(9)
    c = CurveConf()
    c.legend = "Market"
    c.plotstyle = "financebars"
    addcoords(1:3,c)
    open=[10,20,30];
    close=[20,30,40];
    low=[5,15,25];
    high=[25,35,45];
    addfinancial(open,low,high,close)
    a = AxesConf()
    a.title = "Financial Bars"
    a.xrange = "[0:4]"  # gnuplot plots first and last bars against axis
    a.yrange = "[0:50]"
    addconf(a)
    llplot()

    # plotting columns of matrices
    figure(10)
    Y = hcat(st, ct, et)
    X = hcat(t, t, t)
    addcoords(X,Y)
    a = AxesConf()
    a.title = "Plotting matrix columns"
    addconf(a)
    llplot()

    # dots plotstyle
    figure(11)
    x = 1 + 0.1*randn(200)
    y = 1 + 0.1*randn(200)
    c = CurveConf()
    c.plotstyle = "points"
    c.marker = "*"
    c.pointsize = 3
    c.color = "red"
    addcoords([1],[1],c)
    c = CurveConf()
    c.plotstyle = "dots"
    c.color = "blue"
    addcoords(x,y,c)
    a = AxesConf()
    a.title = "dots demo"
    addconf(a)
    llplot()

    # simple 3-D plot with default config
    figure(12)
    x=[0,1,2,3]
    y=[0,1,2]
    Z=[10 10 10; 10 5 10;10 1 10; 10 0 10]
    addcoords(x,y,Z)
    a = AxesConf()
    a.title = "3D: Valley of the Gnu from gnuplot manual"
    addconf(a)
    llplot()

    # same plot with colored surfaces
    figure(13)
    c = CurveConf()
    c.plotstyle = "pm3d"
    addcoords(x,y,Z,c)
    a = AxesConf()
    a.title = "3D: Valley of the Gnu with pm3d"
    addconf(a)
    llplot()

    # sombrero
    figure(14)
    c = CurveConf()
    c.plotstyle = "pm3d"
    x = -15:0.33:15
    y = -15:0.33:15
    Z = meshgrid(x,y,(x,y)->sin(sqrt(x.*x+y.*y))/sqrt(x.*x+y.*y))
    addcoords(x,y,Z,c)
    a = AxesConf()
    a.title = "3D: Sombrero"
    addconf(a)
    llplot()

    # simple image
    figure(15)
    c = CurveConf()
    c.plotstyle = "image"
    Z = [5 4 3 1 0; 2 2 0 0 1; 0 0 0 1 0; 0 1 2 4 3]
    addcoords([],[],Z,c)
    a = AxesConf()
    a.title = "Image"
    addconf(a)
    llplot()

    # rgb image
    figure(16)
    c = CurveConf()
    c.plotstyle = "rgbimage"
    R = [ x+y for x=0:5:120, y=0:5:120]
    G = [ x+y for x=0:5:120, y=120:-5:0]
    B = [ x+y for x=120:-5:0, y=0:5:120]
    Z = zeros(25,25,3)
    Z[:,:,1] = R
    Z[:,:,2] = G
    Z[:,:,3] = B
    addcoords(Any[],Any[],Z,c)
    a = AxesConf()
    a.title = "RGB Image"
    addconf(a)
    llplot()

    # image with x,y coordinates
    figure(17)
    c = CurveConf()
    c.plotstyle = "rgbimage"
    addcoords(linspace(-2.0,5.0,25),linspace(4.0,6.0,25),Z,c)
    a = AxesConf()
    a.title = "RGB Image with explicit (x,y) coordinates"
    addconf(a)
    llplot()

    # histograms
    figure(18)
    c = CurveConf()
    c.plotstyle = "boxes"
    c.color = "blue"
    y = [1 2 3 4 5 6 7 8 9 10]
    (x,y) = histdata(y,10)
    addcoords(x,y,c)
    a = AxesConf()
    a.title = "Simple histogram test"
    addconf(a)
    llplot()

    figure(19)
    c = CurveConf()
    c.plotstyle = "boxes"
    c.color = "blue"
    c.legend = "1000 samples"
    (x,y) = histdata(randn(1000),25)
    delta = x[2]-x[1]
    y = y/(delta*sum(y))  # normalization
    addcoords(x,y,c)
    x = -5:0.05:5
    y = 1/sqrt(2pi)*exp((-x.^2)/2)
    c = CurveConf()
    c.plotstyle = "lines"
    c.color = "black"
    c.legend = "Theoretical"
    addcoords(x,y,c)
    a = AxesConf()
    a.title = "Histogram"
    addconf(a)
    llplot()

    # image and curve on the same figure
    figure(20)
    c = CurveConf()
    c.plotstyle = "image"
    Z = [5 4 3 1 0; 2 2 0 0 1; 0 0 0 1 0; 0 1 2 4 3]
    addcoords(Any[],Any[],Z,c)
    c = CurveConf()
    c.plotstyle = "lines"
    c.color = "blue"
    t = linspace(0,2pi,10)
    addcoords(3*sin(t)+3,c)
    a = AxesConf()
    a.title = "Image and curve on the same figure"
    addconf(a)
    llplot()

    # Two surfaces in one figure, plus low-level use of gnuplot_send
    # for final tweaking
    figure(21)
    gnuplot_send("set view 69,20")
    c = CurveConf()
    c.plotstyle = "pm3d"
    x = -15:0.33:15
    y = -15:0.33:15
    Z = meshgrid(x,y,(x,y)->sin(sqrt(x.*x+y.*y))/sqrt(x.*x+y.*y))
    addcoords(x,y,Z,c)
    Z = meshgrid(x,y,(x,y)->cos(x/2)*sin(y/2)+3)
    addcoords(x,y,Z,c)
    a = AxesConf()
    a.title = "3D: Two surfaces on the same figure"
    addconf(a)
    llplot()

end

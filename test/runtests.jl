## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Gaston test framework
#
# There are two kinds of tests:
#   - Tests that should error -- things that Gaston should not allow, such as
#     building a figure with an invalid p = plotstyle.
#   - Tests that should succeed -- things that should work without producing
#     an error.

using Gaston, Test

@testset "Figure and set commands" begin
    closeall()
    set(reset=true)
    set(mode="null")
    # figures
    @test figure() == 1
    @test figure() == 2
    @test figure(4) == 4
    @test figure() == 3
    @test closefigure(4) == 3
    @test closefigure() == 2
    @test closeall() == 2
    @test begin
        closeall()
        figure()
        figure()
        figure(4);
        closefigure(1,2)
    end == 4
    @test begin
        closeall()
        figure()
        figure()
        figure(4);
        closefigure(4)
    end == 2
    @test begin
        closeall()
        figure()
        figure()
        figure(4);
        closefigure(1,2,3,4,5)
    end == nothing
    @test begin
        closeall()
        figure(3)
        figure(3)
    end == 3
    if !Sys.iswindows()
        @test set(term="x11") === nothing # This test does not pass in Windows
    end
    @test set(termopts="noenhanced") === nothing
    @test set(debug=true) === nothing
    @test set(debug=false) === nothing
end

@testset "2-D plots" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test closeall() == 0
    @test begin
        plot(1:10)
    end isa Gaston.Figure
    @test begin
        plot(1:10,handle=2)
    end isa Gaston.Figure
    @test begin
        plot(1:10,handle=4)
    end isa Gaston.Figure
    @test closeall() == 3
    @test begin
        plot(1:10,cos)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot!(1:10,cos)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        stem(1:10,cos)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        set(termopts="feed noenhanced ansi")
        plot(sin.(-3:0.01:3),
             plotstyle = "linespoints",
             legend = :sine,
             linecolor = "'blue'",
             linewidth = 2,
             pointtype = "ecircle",
             pointsize = "1.1",
             fillstyle = "",
             Axes(
                  title = :test_plot_1,
                  style = "line 20 dt '-.-'",
                  xlabel = :x,
                  ylabel = :y,
                  key = "inside horizontal left top",
                  axis ="loglog",
                  xrange = "[2:3]",
                  yrange = "[2:3]",
                  xzeroaxis = :off,
                  yzeroaxis = :on,
                  font = "'Arial, 12'",
                  size = "79,24"
                 )
            )
    end isa Gaston.Figure
    @test begin
        plot(range(-10,10,length=100),sin,
             w = :lp,
             ls = 15,
             pi = -10,
             Axes(style = "line 15 dt '-...-' lc 'red' lw 3 pt 6"))
    end isa Gaston.Figure
    set(termopts="")
    @test begin
        plot!(cos.(-3:0.01:3),
              legend = "'cos'",
              plotstyle = "linespoints",
              linecolor = "'red'",
              linewidth = 2,
              dashtype = "'.'",
              pointtype = "fcircle",
              pointsize = "1"
             )
    end isa Gaston.Figure
    for ptype in ('λ', 'a', '%', "⋅", "plus")
        @test begin
            plot!(cos.(-3:0.01:3),
                  legend = :cos,
                  w = :linespoints,
                  lc = :red,
                  lw = 2,
                  dt = :.,
                  pt = ptype,
                  ps = 1
                 )
        end isa Gaston.Figure
    end
    @test plot(1:10,cos) isa Gaston.Figure
    @test plot!(1:10,cos) isa Gaston.Figure
    @test stem(1:10,cos) isa Gaston.Figure
    @test plot(1:10, Axes(xrange = "[:3.4]")) isa Gaston.Figure
    @test plot(1:10, Axes(xrange = "[3.4:*]")) isa Gaston.Figure
    @test begin
        plot(1:3, 4:6, plotstyle="points", pointsize=3,
             Axes(xrange="[2.95:3.05]", yrange="[3.95:4.045]"))
    end isa Gaston.Figure
    @test begin
        plot(rand(10) .+ im.*rand(10),
             w = :l,
             leg = :complex_vector,
             Axes(title = :complex_vector,
                  xtics = 1:2:10)
            )
    end isa Gaston.Figure
    @test begin
        y=rand(10)
        ylow=y.-rand(10)
        yhigh=y.+3rand(10)
        plot(y, supp=[ylow yhigh], ps=:errorlines)
    end isa Gaston.Figure
    @test begin
        x=6rand(10).-3
        y=6rand(10).-3
        xdelta=0.5rand(10)
        ydelta=rand(10).-1
        plot(x, y, supp=[xdelta ydelta], ps="vectors head filled", lt=2)
    end isa Gaston.Figure
    @test_skip begin
        x=250randn(10)
        y=10randn(10)
        c1=randn(10)
        c2=50randn(10)
        p = plot(x,y,supp=[c1 c2], ps=:parallelaxes)
    end isa Gaston.Figure
    @test_skip begin
        x=1:5
        y=1:5
        l=["1" "ss" "3" "yy" "x5"]
        p = plot(x, y, supp=l, ps=:labels)
    end isa Gaston.Figure
    @test begin
        stem(0:0.1:3pi,sin)
    end isa Gaston.Figure
    @test begin
        stem(0:0.1:3pi,sin,onlyimpulses=true)
    end isa Gaston.Figure
    @test begin
        t=0:0.05:3
        y1=exp.(-t)+0.1rand(length(t))
        y2=exp.(-t)-0.1rand(length(t))
        p = plot(t,y1,supp=y2,ps=:filledcurves,lc="brown")
        p = plot!(t,exp.(-t),lc="black")
    end isa Gaston.Figure
    # This test is cool, but it fails way too often due to slight
    # OS, configuration, and gnuplot version differences. Disabled for now.
    @test_skip begin
        set(reset=true)
        set(terminal="dumb", size="27,13")
        x="\f                           \n  11 +-----------------+   \n  10 |-+ + + + + + + +*|   \n   9 |-+          ****-|   \n   7 |-+        **   +-|   \n   6 |-+      **     +-|   \n   5 |-+    **       +-|   \n   4 |-+  **         +-|   \n   3 |****           +-|   \n   1 |-+ + + + + + + +-|   \n   0 +-----------------+   \n     1 2 3 4 5 6 7 8 9 10  \n                           \n"
        a=repr("text/plain", p = plot(1:10))
        a == x
    end == true
    @test begin
        set(reset=true)
        stem(rand(10))
    end isa Gaston.Figure
    @test begin
        stem(rand(10),onlyimpulses=true)
    end isa Gaston.Figure
    @test begin
        scatter(rand(10),rand(10))
    end isa Gaston.Figure
    @test begin
        scatter(randn(10), randn(10), pointtype="λ")
    end isa Gaston.Figure
    @test begin
        scatter(rand(10),rand(10), lc=:red)
    end isa Gaston.Figure
    @test begin
        scatter(rand(10),rand(10), lc=:red, Axes(title=:test))
    end isa Gaston.Figure
    @test begin
        scatter(complex.(rand(10), rand(10)), lc=:red)
    end isa Gaston.Figure
    @test begin
        scatter(complex.(rand(10), rand(10)), lc=:red, Axes(title="'test'"))
    end isa Gaston.Figure
    @test begin
        scatter(complex.(rand(10), rand(10)),
                linecolor="'green'",
                Axes(title = :test))
        scatter!(complex.(rand(10), rand(10)),linecolor="'blue'")
    end isa Gaston.Figure
    @test begin
        stem(exp.(0:0.01:1))
    end isa Gaston.Figure
    @test begin
        stem(exp.(0:0.01:1),onlyimpulses=true)
    end isa Gaston.Figure
    @test begin
        t=0:0.01:1
        stem(t,exp)
    end isa Gaston.Figure
    @test begin
        t=0:0.01:1
        stem(t,exp,Axes(xlabel=:x),lc=:red)
    end isa Gaston.Figure
    @test begin
        t=0:0.01:1
        stem(exp.(t),Axes(xlabel=:x))
    end isa Gaston.Figure
    @test begin
        bar(1:10)
    end isa Gaston.Figure
    @test begin
        bar(rand(10),Axes(xlabel=:x),lc=:red)
    end isa Gaston.Figure
    @test begin
        bar(11:20,rand(10),Axes(xlabel=:x),lc=:red)
    end isa Gaston.Figure
    if Gaston.gnuplot_state.gnuplot_available
        @test begin
            set(reset=true)
            s = MIME"image/svg+xml"()
            p = plot(1:10)
            a = repr(s, p)
            a[1:29] == "<?xml version=\"1.0\" encoding="
        end == true
        @test begin
            set(reset=true)
            s = MIME"image/svg+xml"()
            p = plot(1:10)
            a = repr(s, p)
            idx = 0
            while a[end-idx] == '\n' || a[end-idx] == '\r'
                idx = idx + 1
                idx > 20 && return false
            end
            a[end-5-idx:end-idx] == "</svg>"
        end == true
    end
end

@testset "Histograms" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test begin
        histogram(rand(1000))
    end isa Gaston.Figure
    @test begin
        histogram(randn(1000),
                  bins = 100,
                  norm = 1,
                  linecolor = :blue,
                  linewidth = 2,
                  Axes(
                       title = "'test histogram'",
                       xlabel = "'x'",
                       ylabel = "'y'",
                       style = "fill solid",
                       key = "inside horizontal left top",
                       xrange = "[*:*]",
                       yrange = "[*:*]",
                       font = "'Arial, 12'",
                       size = "0.9,0.9")
                 )
    end isa Gaston.Figure
end

@testset "Images" begin
    closeall()
    set(reset=true)
    set(mode="null")
    z = rand(5,6)
    @test begin
        imagesc(z,
                Axes(title = :test_imagesc_1,
                     xlabel = "'xx'",
                     ylabel = "'yy'",
                     font = "'Arial, 12'")
               )
    end isa Gaston.Figure
    @test begin
        imagesc(5:10, 21:25, z,
                Axes(title=:test_imagesc_2,
                     xlabel=:xx,
                     ylabel=:yy)
               )
    end isa Gaston.Figure
    @test begin
        R = [x+y for x=0:5:120, y=0:5:120]
        G = [x+y for x=0:5:120, y=120:-5:0]
        B = [x+y for x=120:-5:0, y=0:5:120]
        Z = zeros(3,25,25)
        Z[1,:,:] = R
        Z[2,:,:] = G
        Z[3,:,:] = B
        imagesc(Z, Axes(title="'RGB Image'"))
    end isa Gaston.Figure
end

@testset "3-D plots" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test begin
        surf(rand(10,10))
    end isa Gaston.Figure
    @test begin
        x=[0,1,2]; y=[0,1,2,3]; Z=[10 10 10; 10 5 10; 10 1 10; 10 0 10]
        surf(x, y, Z,
             legend = :test,
             w = :lines,
             lc = :black,
             Axes(
                  title = :test,
                  xlabel = :x,
                  ylabel = :y,
                  zlabel = :z,
                  key = "inside horizontal left top",
                  xzeroaxis = :on,
                  yzeroaxis = :on,
                  zzeroaxis = :on,
                  font = "'Arial, 12'",
                  size = "0.9,0.9",
                  view = (90,60))
            )
    end isa Gaston.Figure
    @test begin
        surf(0:9,2:11,(x,y)->x*y)
    end isa Gaston.Figure
    @test begin
        surf(0:9,2:11,(x,y)->x*y,
             legend = "'test'",
             plotstyle="pm3d",
             Axes(title="'test'")
            )
    end isa Gaston.Figure
    @test begin
        surf(0:9,2:11,(x,y)->x*y)
        surf!(0:9,2:11,(x,y)->x/y)
    end isa Gaston.Figure
    @test begin
        scatter3(rand(10),rand(10),rand(10),pointtype="fcircle",linecolor=:red)
    end isa Gaston.Figure
    @test begin
        scatter3(rand(10),rand(10),rand(10),
                 Axes(title=:Scatter3, xlabel=:x),
                 lc=:red)
        scatter3!(rand(8),rand(8),rand(8),lc=:black)
    end isa Gaston.Figure
    @test begin
        scatter3(0:0.1:10pi, cos, sin, pt=7, lc="palette",
                 Axes(title=:Spiral,xlabel=:x,ylabel=:y,zlabel=:z))
    end isa Gaston.Figure
    @test begin
        x = 0:0.1:10pi
        scatter3(x, cos, sin, pt=7, lc="palette", ps="variable",
                 supp = x./20,
                 Axes(title=:Spiral,xlabel=:x,ylabel=:y,zlabel=:z))
    end isa Gaston.Figure
    @test begin
        x = -1:0.05:1
        y = -1.5:0.05:2
        egg(x,y) = x^2 + y^2/(1.4 + y/5)^2
        segg = [egg(x,y) for x in x, y in y]
        a = Axes(auto="fix",
                 size="ratio -1",
                 cntrparam="levels incremental 0,0.02,1",
                 palette=:cool)
        contour(x,y,segg',a,w=:lines,lc="palette",labels=false)
    end isa Gaston.Figure
    @test begin
        x = y = -5:0.1:5
        heatmap(x,y,(x,y)->cos.(x/2).*sin.(y/2))
    end isa Gaston.Figure
    @test begin
        x = y = -5:0.1:5
        heatmap(x,y,(x,y)->cos.(x/2).*sin.(y/2), Axes(title=:heatmap))
    end isa Gaston.Figure
end

@testset "Multiplot" begin
    @test begin
        closeall()
        x = y = -15:0.33:15
        z = rand(5,6)
        p1 = scatter(rand(10), rand(10), Axes(title=:p1), handle=1);
        p2 = imagesc(z,Axes(title = :p2), handle=2);
        p3 = surf(x, y, (x,y)->sin.(sqrt.(x.*x+y.*y))./sqrt.(x.*x+y.*y),
                  Axes(title=:p3), plotstyle="pm3d",handle=3);
        plot([p1 p2 ; nothing p3])
    end isa Gaston.Figure
end

@testset "Saving plots" begin
    closeall()
    set(reset=true)
    set(mode="null")
    p = plot(1:10)
    filename = tempname()
    @test begin
        save(output=filename,term="pdf")
    end == nothing
    @test begin
        save(handle=1,term="png",output=filename)
    end == nothing
    @test begin
        save(term="eps",output=filename)
    end == nothing
    @test begin
        save(term="pdf",
             output=filename,
             font = "Arial, 12",
             size = "5,3",
             linewidth = 3)
    end == nothing
    @test begin
        save(term="svg",output=filename,linewidth=3)
    end == nothing
    @test begin
        save(term="gif",output=filename,size="640,480")
    end == nothing
end

@testset "Tests that should fail" begin
    closeall()
    set(reset=true)
    set(mode="null")
    # figure-related
    @test_throws MethodError figure("invalid")
    @test_throws MethodError figure(1.0)
    @test_throws MethodError figure(1:2)
    @test_throws DomainError closefigure(-1)
    @test_throws TypeError closefigure("invalid")
    @test_throws TypeError closefigure(1.0)
    @test_throws TypeError closefigure(1:2)
    # plot
    @test_throws ArgumentError p = plot(0:10,0:11)
    #@test_throws DimensionMismatch surf([1,2],[3,4],[5,6,7])
    #@test_throws DimensionMismatch surf([1,2,3],[3,4],[5,6,7])
    #plot!
    closeall()
    @test_throws ErrorException p = plot!(0:10)
    # imagesc
    z = rand(5,6)
    @test_throws ArgumentError imagesc(1:5,1:7,z)
    # histogram
    #@test_throws MethodError histogram(0:10+im*0:10)
    # save
    @test_throws DomainError begin
        save(handle=2,term="png",output="test")
        Gaston.gnup = plot_state.gp_error
    end
    @test_throws ErrorException p = plot!(rand(10),handle=10)
    # set
    @test_throws MethodError set(color=3)
    @test_throws TypeError set(debug="oo")
    closeall()
end

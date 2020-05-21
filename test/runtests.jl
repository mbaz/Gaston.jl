## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Gaston test framework
#
# There are two kinds of tests:
#   - Tests that should error -- things that Gaston should not allow, such as
#     building a figure with an invalid plotstyle.
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
    @test closefigure(4) == 2
    @test closefigure() == 1
    @test closeall() == 1
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
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,handle=2)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,handle=4) == 4
        Gaston.gnuplot_state.gp_error
    end == false
    @test closeall() == 3
    @test begin
        set(termopts="feed noenhanced ansi")
        plot(sin.(-3:0.01:3),
             legend = "sine",
             title = "test plot 1",
             xlabel = "x",
             ylabel = "y",
             plotstyle = "lines",
             linecolor = "blue",
             linewidth = "2",
             linestyle = "-.-",
             pointtype = "ecircle",
             pointsize = "1.1",
             fillstyle = "",
             keyoptions = "inside horizontal left top",
             axis ="loglog",
             xrange = "[2:3]",
             yrange = "[2:3]",
             xzeroaxis = "",
             yzeroaxis = "",
             font = "Arial, 12",
             size = "79,24",
             background = "",
             gpcom = ""
            )
        Gaston.gnuplot_state.gp_error
    end == false
    set(termopts="")
    @test begin
        plot!(cos.(-3:0.01:3),
              legend = "cos",
              plotstyle = "linespoints",
              linecolor = "red",
              linewidth = "2",
              linestyle = ".",
              pointtype = "fcircle",
              pointsize = "1"
             )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot!(cos.(-3:0.01:3),
              legend = "cos",
              ps = :linespoints,
              lc = :red,
              lw = 2,
              ls = :.,
              pt = :fcircle,
              pz = :1
             )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,xrange = "[:3.4]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,xrange = "[3.4:]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,xrange = "[3.4:*]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10,xrange = "[*:3.4]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(3,4,plotstyle="points",pointsize="3",xrange="[2.95:3.05]",yrange="[3.95:4.045]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(rand(10).+im.*rand(10))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(3+4im,plotstyle="points",pointsize="3",xrange="[2.95:3.05]",yrange="[3.95:4.045]")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        y=rand(10)
        ylow=y.-rand(10)
        yhigh=y.+3rand(10)
        plot(y,supp=[ylow yhigh],ps=:errorlines)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        x=6rand(10).-3
        y=6rand(10).-3
        xdelta=0.5rand(10)
        ydelta=rand(10).-1
        plot(x,y,supp=[xdelta ydelta],ps="vectors head filled",lt=2)
        Gaston.gnuplot_state.gp_error
    end == false
    @test_skip begin
        x=250randn(10)
        y=10randn(10)
        c1=randn(10)
        c2=50randn(10)
        plot(x,y,supp=[c1 c2],ps=:parallelaxes)
        Gaston.gnuplot_state.gp_error
    end == false
    @test_skip begin
        x=1:5
        y=1:5
        l=["1" "ss" "3" "yy" "x5"]
        plot(x,y,supp=l,ps=:labels)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        stem(0:0.1:3pi,sin)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        stem(0:0.1:3pi,sin,onlyimpulses=true)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        t=0:0.05:3
        y1=exp.(-t)+0.1rand(length(t))
        y2=exp.(-t)-0.1rand(length(t))
        plot(t,y1,supp=y2,ps=:filledcurves,lc="brown")
        plot!(t,exp.(-t),lc="black")
        Gaston.gnuplot_state.gp_error
    end == false
    # This test is cool, but it fails way too often due to slight
    # OS, configuration, and gnuplot version differences. Disabled for now.
    if false
    #if occursin("5.2",read(`gnuplot --version`, String))
        @test begin
            set(reset=true)
            set(terminal="dumb", size="27,13")
            x="\f                           \n  11 +-----------------+   \n  10 |-+ + + + + + + +*|   \n   9 |-+          ****-|   \n   7 |-+        **   +-|   \n   6 |-+      **     +-|   \n   5 |-+    **       +-|   \n   4 |-+  **         +-|   \n   3 |****           +-|   \n   1 |-+ + + + + + + +-|   \n   0 +-----------------+   \n     1 2 3 4 5 6 7 8 9 10  \n                           \n"
            a=repr("text/plain", plot(1:10))
            a == x
        end == true
    end
    @test begin
        set(reset=true)
        stem(rand(10))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        stem(rand(10),onlyimpulses=true)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter(rand(10),rand(10))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter(randn(10), randn(10), pointtype="λ")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter(complex.(rand(10), rand(10)))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter(complex.(rand(10), rand(10)),linecolor="green")
        scatter!(complex.(rand(10), rand(10)),linecolor="blue")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter(rand(10), rand(10),pointtype="ecircle")
        scatter!(rand(10), rand(10),pointtype="fcircle")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        t = -2:0.06:2
        plot(t, sin.(2π*t), plotstyle="fillsteps", fillstyle="solid 0.5", title="Fillsteps plot")
        Gaston.gnuplot_state.gp_error
    end == false
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
        a[end-7:end-2] == "</svg>"
    end == true
end

@testset "Histograms" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test begin
        histogram(rand(1000))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        histogram(randn(1000),
                  bins = 100,
                  norm = 1,
                  title = "test histogram",
                  xlabel = "x",
                  ylabel = "y",
                  linecolor = "blue",
                  linewidth = "2",
                  fillstyle = "solid",
                  keyoptions = "inside horizontal left top",
                  xrange = "[*:*]",
                  yrange = "[*:*]",
                  font = "Arial, 12",
                  size = "79,24",
                  background = "red"
                 )
        Gaston.gnuplot_state.gp_error
    end == false
end

@testset "Images" begin
    closeall()
    set(reset=true)
    set(mode="null")
    z = rand(5,6)
    @test begin
        imagesc(z,
                title = "test imagesc 1",
                xlabel = "xx",
                ylabel = "yy",
                font = "Arial, 12",
                size = "79,24"
               )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        imagesc(1:6,1:5,z,title="test imagesc 3",xlabel="xx",ylabel="yy")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        R = [x+y for x=0:5:120, y=0:5:120]
        G = [x+y for x=0:5:120, y=120:-5:0]
        B = [x+y for x=120:-5:0, y=0:5:120]
        Z = zeros(3,25,25)
        Z[1,:,:] = R
        Z[2,:,:] = G
        Z[3,:,:] = B
        imagesc(Z,title="RGB Image",clim=[10,200])
        Gaston.gnuplot_state.gp_error
    end == false
end

@testset "3-D plots" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test begin
        surf(rand(10,10))
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        x=[0,1,2]; y=[0,1,2,3]; Z=[10 10 10; 10 5 10; 10 1 10; 10 0 10]
        surf(x, y, Z,
             legend = :test,
             ps = :lines,
             lc = :black,
             title = :test,
             xlabel = :x,
             ylabel = :y,
             zlabel = :z,
             ko = "inside horizontal left top",
             xrange = "",
             yrange = "",
             zrange = "",
             xzeroaxis = :on,
             yzeroaxis = :on,
             zzeroaxis = :on,
             font = "Arial, 12",
             size = "79,24",
             view = (90,60)
            )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        x=[0,1,2]; y=[0,1,2,3]; Z=[10 10 10; 10 5 10; 10 1 10; 10 0 10]
        surf(x, y, Z,
             legend = "test",
             plotstyle = "lines",
             linecolor = "black",
             title = "test",
             xlabel = "x",
             ylabel = "y",
             zlabel = "z",
             keyoptions = "inside horizontal left top",
             xrange = "",
             yrange = "",
             zrange = "",
             xzeroaxis = "on",
             yzeroaxis = "on",
             zzeroaxis = "on",
             font = "Arial, 12",
             size = "79,24",
             gpcom = "set view 90,60"
            )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        surf(0:9,2:11,(x,y)->x*y)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        surf(0:9,2:11,(x,y)->x*y,
             legend = "test",
             plotstyle="pm3d",
             title="test",
            )
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        surf(0:9,2:11,(x,y)->x*y)
        surf!(0:9,2:11,(x,y)->x/y)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter3(rand(10),rand(10),rand(10),pointtype="fcircle",linecolor="red")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        scatter3(rand(10),rand(10),rand(10))
        scatter3(rand(8),rand(8),rand(8),lc=:black)
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        x = 0:0.1:10pi
        scatter3(x,sin.(x).*x,cos.(x).*x,supp=x./20,pt=7,pz=:variable,lc=:{palette})
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        x = -1:0.05:1
        y = -1.5:0.05:2
        egg(x,y) = x^2 + y^2/(1.4 + y/5)^2
        segg = [egg(x,y) for x in x, y in y]
        gp="""set auto fix
              set size ratio -1"""
        contour(x,y,segg',ps=:lines,lc="palette",palette=:cool,gpcom=gp,
                cntrparam="levels incremental 0,0.02,1",labels=false)
        Gaston.gnuplot_state.gp_error
    end == false
end

@testset "Saving plots" begin
    closeall()
    set(reset=true)
    set(mode="null")
    plot(1:10)
    @test begin
        save(output="test",term="pdf")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        save(handle=1,term="png",output="test")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        save(term="eps",output="test")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        save(term="pdf",
             output="test",
             font = "Arial, 12",
             size = "5,3",
             linewidth = "3")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        save(term="svg",output="test",linewidth="3")
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        save(term="gif",output="test",size="640,480")
        Gaston.gnuplot_state.gp_error
    end == false
end

@testset "Linestyle tests" begin
    closeall()
    set(reset=true)
    set(mode="null")
    @test begin
        plot(1:10) # solid
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10, linestyle="") # solid
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10, linestyle="-") # dashed
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10, linestyle=".") # dotted
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10, linestyle="_") # em-dashed
        Gaston.gnuplot_state.gp_error
    end == false
    @test begin
        plot(1:10, linestyle="- ._. ") # complex pattern
        Gaston.gnuplot_state.gp_error
    end == false
    closeall()
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
    @test_throws MethodError closefigure("invalid")
    @test_throws MethodError closefigure(1.0)
    @test_throws MethodError closefigure(1:2)
    # plot
    @test_throws DimensionMismatch plot(0:10,0:11)
    #@test_throws DimensionMismatch surf([1,2],[3,4],[5,6,7])
    #@test_throws DimensionMismatch surf([1,2,3],[3,4],[5,6,7])
    # plot!
    closeall()
    @test_throws ErrorException plot!(0:10)
    # imagesc
    z = rand(5,6)
    @test_throws ArgumentError imagesc(1:5,1:7,z)
    # histogram
    #@test_throws MethodError histogram(0:10+im*0:10)
    # save
    @test_throws DomainError begin
        save(handle=2,term="png",output="test")
        Gaston.gnuplot_state.gp_error
    end
    @test_throws ErrorException plot!(rand(10),handle=10)
    # set
    @test_throws MethodError set(color=3)
    @test_throws TypeError set(debug="oo")
    closeall()
end

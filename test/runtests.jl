## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

using Test, Gaston, Aqua, JET

gh = Gaston.gethandles
reset = Gaston.reset
null() = Gaston.config.output = :null

@testset "AQUA" begin
    Aqua.test_unbound_args(Gaston)
    Aqua.test_undefined_exports(Gaston)
    Aqua.test_piracy(Gaston)
    Aqua.test_project_toml_formatting(Gaston)
    Aqua.test_stale_deps(Gaston)
    Aqua.test_unbound_args(Gaston)
    Aqua.test_undefined_exports(Gaston)
end

@testset "JET" begin
    null()
    #JET.test_package("Gaston"; toplevel_logger=nothing)
    JET.@test_call target_modules=(Gaston,) Figure(1)
    JET.@test_call target_modules=(Gaston,) plot(rand(10), rand(10))
    JET.@test_call target_modules=(Gaston,) @options plot({grid, title = qs"test"}, rand(10), rand(10), {lc = "'red'"})
    f = Figure()
    x = 1:10; y = rand(10); z = rand(10,10)
    JET.@test_call target_modules=(Gaston,) plot(f, x, y, z)
    JET.@test_call target_modules=(Gaston,) plot(f[2], x, y, z)
    JET.@test_call target_modules=(Gaston,) plot!(f, x, y, z)
    closeall()
end

@testset "Options" begin
        w = 5.3
        x = @options {a = :summer, b, c = 3, d = qs"long title", e = w}
        @test x[1] == Pair("a", :summer)
        @test x[2] == Pair("b", true)
        @test x[3] == Pair("c", 3)
        @test x[4] == Pair("d", "'long title'")
        @test x[5] == Pair("e", 5.3)
end

@testset "Handles" begin
    closeall()
    reset()
    null()
    f1 = Figure(1);
    f2 = Figure("a");
    f3 = Figure(3.14);
    f4 = Figure(:a);
    @test Gaston.nexthandle() == 2
    @test Gaston.getidx(f1) == 1
    @test Gaston.getidx(f2) == 2
    @test Gaston.getidx(f3) == 3
    @test Gaston.getidx(f4) == 4
    closefigure("a")
    @test Gaston.getidx(f3) == 2
    closefigure(f4)
    @test Gaston.nexthandle() == 2
    closeall()
    @test Gaston.nexthandle() == 1
    # negative handles
    f1 = Figure(-5)
    f2 = Figure("a")
    f3 = Figure(0)
    @test Gaston.nexthandle() == 1
    closefigure(-5)
    @test Gaston.nexthandle() == 1
    f4 = Figure()
    @test f4.handle == 1
    closeall()
    p1 = plot(1:10, handle = :a);
    p2 = plot(1:10, handle = :b);
    p3 = plot(1:10, handle = :c);
    @test begin
        closefigure(:b)
        gh()
    end == [:a, :c]
    @test begin
        closefigure()
        gh()
    end == [:a]
    @test begin
        closefigure(:a)
        gh()
    end == Any[]
    Figure()
    Figure()
    @test Gaston.activefig() == 2
    @test Gaston.state.figures.figs[1].handle == 1
    @test Gaston.state.figures.figs[2].handle == 2
    closefigure(1)
    Figure()
    @test Gaston.state.figures.figs[1].handle == 2
    @test Gaston.state.figures.figs[2].handle == 1
    closeall()
    @test gh() == Any[]
    closeall()
    Figure(1)
    Figure(4)
    @test length(Gaston.state.figures.figs) == 2
    @test closefigure(1) == 4
    @test length(Gaston.state.figures.figs) == 1
    @test Gaston.activefig() == 4
    closefigure(4)
    @test isempty(Gaston.state.figures.figs)
    @test Gaston.activefig() === nothing
    closeall()
    Figure(1)
    Figure(10)
    f = figure()
    @test f.handle == 10
    f = figure(1)
    @test f.handle == 1
    f = figure(index = 1)
    @test f.handle == 1
    f = figure(index = 2)
    @test f.handle == 10
    @test_throws ErrorException figure(3)
    @test_throws ErrorException figure(index = 3)
end

@testset "Configuration commands" begin
    closeall()
    reset()
    @test Gaston.config.term == ""
    @test Gaston.config.embedhtml == false
    @test Gaston.config.output == :external
    @test Gaston.config.exec == `gnuplot`
    null()
    @test Gaston.config.output == :null
end

@testset "Plot" begin
    closeall()
    reset()
    null()
    @test_throws ArgumentError Plot()
    @test_throws ArgumentError Plot("w l")
    p = Plot(1:10, "w l")
    @test p.is3d == false
    @test p.plotline == "w l"
    p = Plot3(1:10, 1:10, 1:10, "w l")
    @test p.is3d == true
    @test p.plotline == "w l"
    p = Plot(1:10)
    @test p.plotline == ""
    p = @options Plot(1:10, {with="lines"})
    @test p.plotline == "with lines"
end

@testset "Axis" begin
    a = Axis()
    @test a.settings == ""
    @test a.plots == Plot[]
    @test isempty(a)
    p = Plot(1:10)
    push!(a, p)
    @test !isempty(a)
    @test length(a.plots) == 1
    push!(a, p)
    @test length(a.plots) == 2
    Gaston.set!(a, "s")
    @test a.settings == "s"
    Gaston.set!(a, ["title" => "1"])
    @test a.settings == "set title 1"
    Gaston.empty!(a)
    @test isempty(a)
    a = Axis(p)
    @test !isempty(a)
    @test length(a.plots) == 1
    Gaston.empty!(a)
    a = Axis("s")
    @test a.settings == "s"
    @test a.plots == Plot[]
    a = Axis("s", p)
    @test a.settings == "s"
    @test length(a.plots) == 1
    a = Axis(["title" => "1"], p)
    @test a.settings == "set title 1"
    @test a.plots == [p]
    a = Axis(["title" => "1"], p)
    @test a.settings == "set title 1"
    @test length(a.plots) == 1
    @options a = Axis({title = "1", grid})
    @test a.settings == "set title 1\nset grid"
end

@testset "Figure and figure" begin
    closeall()
    reset()
    null()
    @test Figure() isa Figure
    @test length(Gaston.state.figures) == 1
    @test Gaston.state.figures.figs[1].handle == 1
    @test_throws ErrorException Figure(1)
    @test_throws ErrorException figure(2)
    closeall()
    f = Figure(π)
    @test f.handle == π
    @test f.gp_proc isa Base.Process
    @test f.multiplot == ""
    @test f.axes == Axis[]
    @test isempty(f)
    @test length(f) == 0
    Figure("a")
    @test Gaston.activefig() == "a"
    f = figure(index = 2)
    @test f.handle == "a"
    @test f[1] isa Gaston.FigureAxis
    f = figure(π)
    @test f.handle == π
    @test length(f) == 0
    # test pushes
    f = Figure(1)
    p = Plot([1])
    push!(f(2), p)
    @test f[2] isa Gaston.FigureAxis
    @test f(2, 1) == p
end

@testset "Parsing settings" begin
    ps = Gaston.parse_settings
    @test ps("x") == "x"
    # booleans
    @test @options ps({g}) == "set g"
    @test @options ps({g=true}) == "set g"
    @test @options ps({g=false}) == "unset g"
    @test @options ps({g,g=false}) == "set g\nunset g"
    # tics
    @test @options ps({tics="axis border"}) == "set tics axis border"
    @test @options ps({xtics=1:2}) == "set xtics 1,1,2"
    @test @options ps({ytics=1:2}) == "set ytics 1,1,2"
    @test @options ps({ztics=1:2:7}) == "set ztics 1,2,7"
    @test @options ps({tics=1:2}) == "set tics 1,1,2"
    @test @options ps({tics,tics=1:5}) == "set tics\nset tics 1,1,5"
    @test @options ps({tics=(0,5)}) == "set tics (0, 5)"
    @test @options ps({tics=(labels=("one", "two"), positions=(0, 5))}) == "set tics ('one' 0, 'two' 5, )"
    # ranges
    #@test @options ps({})
    @test @options ps({xrange=(-5,5)}) == "set xrange [-5:5]"
    @test @options ps({xrange=(-5.1,5.6)}) == "set xrange [-5.1:5.6]"
    @test @options ps({xrange=[-Inf,0]}) == "set xrange [*:0.0]"
    @test @options ps({yrange=[0,Inf]}) == "set yrange [0.0:*]"
    @test @options ps({zrange=[-Inf,Inf]}) == "set zrange [*:*]"
    @test @options ps({cbrange=(1,2)}) == "set cbrange [1:2]"
    @test @options ps({cbrange=(0,Inf)}) == "set cbrange [0:*]"
    @test @options ps({zrange=(-Inf,Inf)}) == "set zrange [*:*]"
    @test @options ps({ranges=(-3,3)}) == "set xrange [-3:3]\nset yrange [-3:3]\nset zrange [-3:3]\nset cbrange [-3:3]"
    # palette
    @test @options ps({palette=:jet}) == "set palette defined (1 0.0 0.0 0.498, 2 0.0 0.0 1.0, 3 0.0 0.498 1.0, 4 0.0 1.0 1.0, 5 0.498 1.0 0.498, 6 1.0 1.0 0.0, 7 1.0 0.498 0.0, 8 1.0 0.0 0.0, 9 0.498 0.0 0.0)\nset palette maxcolors 9"
    @test @options ps({palette=(:jet,:reverse)}) == "set palette defined (1 0.498 0.0 0.0, 2 1.0 0.0 0.0, 3 1.0 0.498 0.0, 4 1.0 1.0 0.0, 5 0.498 1.0 0.498, 6 0.0 1.0 1.0, 7 0.0 0.498 1.0, 8 0.0 0.0 1.0, 9 0.0 0.0 0.498)\nset palette maxcolors 9"
    @test @options ps({palette="x"}) == "set palette x"
    # view
    @test @options ps({view=(50,60)}) == "set view 50, 60"
    @test @options ps({view=5}) == "set view 5"
    # linetype
    @test @options ps({linetype = 5}) == "set linetype 5"
    @test @options ps({lt = :jet}) == "set lt 1 lc rgb '#00007f'\nset lt 2 lc rgb '#0000ff'\nset lt 3 lc rgb '#007fff'\nset lt 4 lc rgb '#00ffff'\nset lt 5 lc rgb '#7fff7f'\nset lt 6 lc rgb '#ffff00'\nset lt 7 lc rgb '#ff7f00'\nset lt 8 lc rgb '#ff0000'\nset lt 9 lc rgb '#7f0000'\nset linetype cycle 9"
    # margins
    @test ps(@options {margins = (.2, .3, .4, .5)}) == "set lmargin at screen 0.2\nset rmargin at screen 0.3\nset bmargin at screen 0.4\nset tmargin at screen 0.5"
    @test ps(@options {margins = "1,2,3,4"}) == "set margins 1,2,3,4"
end

@testset "Parsing plotlines" begin
    pp = Gaston.parse_plotline
    @test @options pp({w=1,w=2}) == "w 2"
    @test @options pp({marker=:dot}) == "pointtype 0"
    @test @options pp({pointtype=:⋅}) == "pointtype 0"
    @test @options pp({pt=:+}) == "pointtype 1"
    @test @options pp({marker=qs"λ"}) == "pointtype 'λ'"
    @test @options pp({marker="'k'"}) == "pointtype 'k'"
    @test @options pp({plotstyle="lt"}) == "with lt"
    @test @options pp({markersize=8}) == "pointsize 8"
    @test @options pp({ms=5}) == "pointsize 5"
    @test @options pp({legend=qs"title"}) == "title 'title'"
end

@testset "convert_args" begin
    cc = Gaston.convert_args
    PO = Gaston.PlotObject
    ts(po::PO) = po.bundles[1].series[1].ts
    pl(po::PO) = po.bundles[1].series[1].pl

    po = cc(1)
    @test ts(po) == ([1], [1])
    @test pl(po) == ""

    po = cc(1, 2)
    @test ts(po) == ([1], [2])
    @test pl(po) == ""

    po = cc([1,3])
    @test ts(po) == ([1,2],[1,3])
    @test pl(po) == ""

    @test ts(cc(3:4)) == ([1,2],[3,4])
    @test ts(cc(ComplexF64.([1,2], [3,4]))) == ([1,2], [3,4])

    po = cc(t->1)
    @test ts(po)[1] == range(-10,9.99,100)
    @test ts(po)[2] == ones(Int, 100)
    po = cc((1,2),t->1)
    @test ts(po)[1] == range(1,2,100)
    @test ts(po)[2] == ones(Int, 100)
    po = cc((1,2,10),t->1)
    @test ts(po)[1] == range(1,2,10)
    @test ts(po)[2] == ones(Int,10)
    po = cc(1:10,t->1)
    @test ts(po)[1] == 1:10
    @test ts(po)[2] == ones(Int,10)
    po = cc([1 2; 3 4])
    @test ts(po)[1] == 1:2
    @test ts(po)[2] == 1:2
    @test ts(po)[3] == [1 2 ; 3 4]
    y = rand(3,4,5)
    po = cc(y)
    @test ts(po)[1] == 1:5
    @test ts(po)[2] == 1:4
    @test ts(po)[3] == y[1,:,:]
    @test ts(po)[4] == y[2,:,:]
    @test ts(po)[5] == y[3,:,:]

    cc3 = Gaston.convert_args3
    po = cc3(1,2,3)
    @test ts(po) == ([1], [2], [3])
    @test pl(po) == ""
    @test ts(cc3([1 2; 3 4])) == ([1, 2], [1, 2], [1 2; 3 4])
    @test ts(cc3([1 2 3; 3 4 5])) == ([1, 2, 3], [1, 2], [1 2 3; 3 4 5])
    @test ts(cc3(1:2, 1:3, [1 2 3; 3 4 5])) == ([1, 2], [1, 2, 3], [1 2 3; 3 4 5])
    # TODO: test histograms 
end

@testset "plot" begin
    closeall()
    reset()
    null()
    f = plot(1:10)
    @test f isa Figure
    @test f.handle == 1
    @test f(1).settings == ""
    @test f(1,1).plotline == ""
    f = @options plot({grid}, 1:10)
    @test f.handle == 1
    @test f(1).settings == "set grid"
    @test f(1,1).plotline == ""
    f = @options plot({grid}, 1:10, "w l")
    @test f(1,1).plotline == "w l"
    f = @options plot({grid}, 1:10, {w="l"})
    @test f(1,1).plotline == "w l"
    plot(f[2], (1:10).^2)
    @test length(f) == 2
    @test f(2).settings == ""
    @test f(2,1).plotline == ""
    plot(f[2], "set view", (1:10).^2, "w p")
    @test f(2).settings == "set view"
    @test f(2,1).plotline == "w p"
    plot!(f[2], 1:10, "w lp")
    @test f(2,2).plotline == "w lp"
    plot!(f[2], 1:10, "w lp pt 1")
    @test f(2,3).plotline == "w lp pt 1"
    @options plot!(f[2], 1:10, {w="p", marker=qs"λ"})
    @test f(2,4).plotline == "w p pointtype 'λ'"
    plot(1:10)
    @test length(f) == 1
    f = plot(1:10, handle="aa")
    @test f isa Figure
    @test f.handle == "aa"
end

@testset "plot with 'themes'" begin
    closeall()
    reset()
    null()
    f = @options plot({grid},{xtics}, 1:10)
    @test f(1).settings == "set grid\nset xtics"
    f = @options plot({grid},"set xtics", 1:10)
    @test f(1).settings == "set grid\nset xtics"
    f = @options plot("set grid",{xtics}, 1:10)
    @test f(1).settings == "set grid\nset xtics"
    f = @options plot("set grid",{xtics},"set view", 1:10)
    @test f(1).settings == "set grid\nset xtics\nset view"
    f = plot(1:10, "1", "2", "3")
    @test f(1,1).plotline == "1 2 3"
    plot!(f, 1:10, "1", "2", "3")
    @test f(1,2).plotline == "1 2 3"
    f = @options plot(1:10, "1", {2}, "3")
    @test f(1,1).plotline == "1 2 3"
    @options plot!(f, 1:10, "1", {2}, "3")
    @test f(1,2).plotline == "1 2 3"
    f = @options plot(1:10, {1}, {2}, {w="l"})
    @test f(1,1).plotline == "1 2 w l"
    @options plot!(f, 1:10, {1}, {2}, {w="l"})
    @test f(1,2).plotline == "1 2 w l"
    f = @options plot(1:10, {1}, {2}, :scatter)
    @test f(1,1).plotline == "1 2 with points pointtype 7 pointsize 1.5"
    @options plot!(f, 1:10, {1}, {2}, :scatter)
    @test f(1,2).plotline == "1 2 with points pointtype 7 pointsize 1.5"
    f = @options plot({grid}, :heatmap, 1:10)
    @test f(1).settings == "set grid\nset view map"
end

@testset "2d plot recipes" begin
    closeall()
    reset()
    null()
    f = @options scatter({grid}, rand(2), rand(2), {1}, "2")
    @test f isa Figure
    @test f(1).settings == "set grid"
    @test f(1,1).plotline == "with points pointtype 7 pointsize 1.5 1 2"
    @options scatter!(rand(2), rand(2), {3}, "4")
    @test f isa Figure
    @test f(1).settings == "set grid"
    @test f(1,2).plotline == "with points pointtype 7 pointsize 1.5 3 4"
    f = @options stem({grid}, rand(2), {1}, "2")
    @test f isa Figure
    @test f(1).settings == "set grid"
    @test f(1,1).plotline == "with impulses 1 2 linecolor 'blue'"
    @test f(1,2).plotline == "with points pointtype 6 pointsize 2 1 2 linecolor 'blue'"
    @options stem!(rand(2), rand(2), {3}, "4")
    @test f isa Figure
    @test f(1).settings == "set grid"
    @test f(1,3).plotline == "with impulses 3 4 linecolor 'blue'"
    @test f(1,4).plotline == "with points pointtype 6 pointsize 2 3 4 linecolor 'blue'"
    f = bar(1:10, rand(10))
    bar!(1.5:10.5, 0.5*rand(10), "lc 'green'")
    @test f(1).settings == "set boxwidth 0.8 relative\nset style fill solid 0.5"
    @test f(1,1).plotline == "with boxes"
    @test f(1,2).plotline == "with boxes lc 'green'"
    f = barerror(1:10, rand(10), rand(10))
    barerror!(1.5:10.5, 0.5*rand(10), rand(10), "lc 'green'")
    @test f(1).settings == "set boxwidth 0.8 relative\nset style fill solid 0.5"
    @test f(1,1).plotline == "with boxerrorbars"
    @test f(1,2).plotline == "with boxerrorbars lc 'green'"
    f = histogram(rand(10), nbins = 20, norm = true)
    @test f isa Figure
    @test f(1).settings == "set boxwidth 0.8 relative\nset style fill solid 0.5\nset yrange [0:*]"
    @test f(1,1).plotline == "with boxes"
    f = histogram(rand(10), edges = [-1, 0, 1])
    @test f isa Figure
    @test f(1).settings == "set boxwidth 0.8 relative\nset style fill solid 0.5\nset yrange [0:*]"
    @test f(1,1).plotline == "with boxes"
    f = histogram(rand(10), edges = -5:0.5:5)
    @test f isa Figure
    @test f(1).settings == "set boxwidth 0.8 relative\nset style fill solid 0.5\nset yrange [0:*]"
    @test f(1,1).plotline == "with boxes"
    f = histogram(rand(10), rand(10))
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    f = histogram(rand(10), rand(10), nbins = 20)
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    f = histogram(rand(10), rand(10), nbins = (20,10))
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    f = histogram(rand(10), rand(10), edges = [1,2,3])
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    f = histogram(rand(10), rand(10), edges = ([1,2,3],[1,2,3]))
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    f = histogram(rand(10), rand(10), nbins = 20, norm = true)
    @test f isa Figure
    @test f(1).settings == ""
    @test f(1,1).plotline == "with image"
    Z = [5 4 3 1 0 ;
     2 2 0 0 1 ;
     0 0 0 1 0 ;
     0 1 2 4 3]
    f = imagesc(Z)
    @test f isa Figure
    @test f(1,1).plotline == "with image"
    Z = 255*randn(3,10,10)
    f = imagesc(Z)
    @test f isa Figure
    @test f(1,1).plotline == "with rgbimage"
end

@testset "3d plot recipes" begin
    closeall()
    reset()
    null()
    x = y = -15:0.4:15
    f1 = (x,y) -> @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
    f = @options wireframe({title="'wireframe'"},x,y,f1,"lc 'turquoise'")
    @test f isa Figure
    @test f(1).settings == "set hidden3d\nset title 'wireframe'"
    @test f(1,1).plotline == "lc 'turquoise'"
    @options wireframe!({title="'wireframe'"},x.-5,y,f1,"lc 'orange'")
    @test length(f) == 1
    @test length(f(1)) == 2
    @test f(1,2).plotline == "lc 'orange'"
    plot(f[2], 1:10)
    @test length(f) == 2
    f = @options surf({title="'surf'"},x,y,f1,"lc 'turquoise'")
    @test f isa Figure
    @test f(1).settings == "set hidden3d\nset title 'surf'"
    @test f(1,1).plotline == "with pm3d lc 'turquoise'"
    @options surf!({title="'surf'"},x.-5,y,f1,"lc 'orange'")
    @test length(f) == 1
    @test length(f(1)) == 2
    @test f(1,2).plotline == "with pm3d lc 'orange'"
    f = @options surfcontour(x,y,f1,"lc 'turquoise'")
    @test f isa Figure
    @test f(1).settings == "set hidden3d\nunset key\nset contour base\nset cntrlabel font ',7'\nset cntrparam levels auto 10"
    @test f(1,1).plotline == "lc 'turquoise'"
    @test length(f) == 1
    @test length(f(1)) == 2
    @test f(1,2).plotline == "with labels lc 'turquoise'"
    f = @options surfcontour(x,y,f1,labels=false)
    @test length(f(1)) == 1
    f = wiresurf(x,y,f1)
    @test f isa Figure
    @test f(1).settings == "set hidden3d\nset pm3d implicit depthorder border lc 'black' lw 0.3"
    f = scatter3(rand(10),rand(10),rand(10))
    scatter3!(f,rand(10),rand(10),rand(10))
    @test f isa Figure
    @test length(f(1)) == 2
    f = contour(x,y,f1,labels=false)
    @test f isa Figure
    @test length(f(1)) == 1
    f = contour(x,y,f1)
    @test f isa Figure
    @test length(f(1)) == 2
    f = @options heatmap({palette=:summer},x,y,f1)
    @test f isa Figure
    @test f(1,1).plotline == "with pm3d"
end

@testset "Multiplot" begin
    closeall()
    reset()
    null()
    f = plot(1:10)
    plot(f[10], 1:10)
    @test f isa Figure
    @test length(f) == 10
end

@testset "Saving plots" begin
    closeall()
    null()
    reset()
    t = mktempdir()
    cd(t)
    f1 = plot(1:10)
    save()
    @test isfile("figure-1.pngcairo")
    rm("figure-1.pngcairo", force=true)
    save("test.png")
    @test isfile("test.png")
    rm("test.png", force=true)
    save(term="pdf enhanced")
    @test isfile("figure-1.pdf")
    rm("figure-1.pdf", force=true)
    Figure()
    f2 = plot(1:10)
    @test f2.handle == 2
    save(f2)
    @test isfile("figure-2.pngcairo")
    rm("figure-2.pngcairo", force=true)
    save(f2,"test2.png")
    @test isfile("test2.png")
    rm("test2.png", force=true)
    save(f2,term="pdf")
    @test isfile("figure-2.pdf")
    rm("figure-2.pdf", force=true)
    save(f2,"test.pdf",term="pdf")
    @test isfile("test.pdf")
    rm("test.pdf", force=true)
end

closeall()

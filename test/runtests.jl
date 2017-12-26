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

using Gaston
using Base.Test

@testset "Pass expected" begin
	closeall()
	@test figure() == 1
	@test figure() == 2
	@test figure(4) == 4
	@test closefigure(4) == 4
	@test closefigure() == 2
	@test closeall() == 1
	@test closeall() == 0
	@test plot(1:10) == 1
	@test plot(1:10,handle=2) == 2
	@test plot(1:10,handle=4) == 4
	@test closeall() == 3
	@test begin
		plot(sin.(-3:0.01:3),
		legend = "sine",
		plotstyle = "lines",
		color = "blue",
		marker = "ecircle",
		linewidth = 2,
		pointsize = 1.1,
		title = "test plot 1",
		xlabel = "x",
		ylabel = "y",
		box = "inside horizontal left top",
		axis ="loglog") == 1
	end
	@test histogram(rand(1000)) == 1
	@test begin
		histogram(randn(1000),
        bins=100,
        norm=1,
        color="blue",
        linewidth=2,
        title="test histogram",
        xlabel="x",
        ylabel="y",
        box="inside horizontal left top")
	end == 1
	z = rand(5,6)
	@test imagesc(z,title="test imagesc 1",xlabel="xx",ylabel="yy") == 1
	@test imagesc(1:6,1:5,z,title="test imagesc 3",xlabel="xx",ylabel="yy") == 1
	@test surf(rand(10,10)) == 1
	@test surf(rand(10,10)) == 1
	@test surf(0:9,2:11,rand(10,10)) == 1
    @test surf(0:9,2:11,(x,y)->x*y) == 1
	@test surf(0:9,2:11,(x,y)->x*y,title="test",plotstyle="pm3d") == 1
	@test begin
		plot(1:10)
		printfigure()
	end == 1
	@test begin
		plot(1:10,handle=2)
		printfigure(2,"png")
		closefigure()
	end == 2
	@test begin
		plot(1:10)
		printfigure("eps")
	end == 1
	@test printfigure("pdf") == 1
	@test begin
		set(print_size="640,480")
		printfigure("svg")
	end == 1
	@test printfigure("gif") == 1
	@test plot(1:10,xrange = "[2:3]") == 1
	@test plot(1:10,xrange = "[-1.1:3.4]") == 1
	@test plot(1:10,xrange = "[:3.4]") == 1
	@test plot(1:10,xrange = "[3.4:]") == 1
	@test plot(1:10,xrange = "[3.4:*]") == 1
	@test plot(1:10,xrange = "[*:3.4]") == 1
	@test begin
		# build a multiple-plot figure manually
		ac = Gaston.AxesConf(title="T")
		x1, exp_pdf = Gaston.hist(randn(10000),25)
		exp_pdf .= exp_pdf./(step(x1)*sum(exp_pdf))
		exp_cconf = Gaston.CurveConf(plotstyle="boxes",
									 color="blue",
									 legend="E")
		exp_curve = Gaston.Curve(x1,exp_pdf,exp_cconf)
		x2 = -5:0.05:5
		theo_pdf = @. 1/sqrt(2π)*exp((-x2^2)/2)
		theo_cconf = Gaston.CurveConf(color="black",legend="T")
		theo_curve = Gaston.Curve(x2,theo_pdf,theo_cconf)
		figure(1)
		Gaston.push_figure!(1,ac,exp_curve,theo_curve)
		Gaston.llplot()
	end == nothing
	# test `set`
	@test set(legend="A") == nothing
	@test set(plotstyle="linespoints") == nothing
	@test set(color="red") == nothing
	@test set(marker="ecircle") == nothing
	@test set(linewidth=3) == nothing
	@test set(pointsize=3) == nothing
	@test set(title="A") == nothing
	@test set(xlabel="A") == nothing
	@test set(ylabel="A") == nothing
	@test set(zlabel="A") == nothing
	@test set(fill="solid") == nothing
	@test set(grid="on") == nothing
	@test set(terminal="x11") == nothing
	@test set(outputfile="A") == nothing
	@test set(print_color="red") == nothing
	@test set(print_fontface="A") == nothing
	@test set(print_fontscale=1) == nothing
	@test set(print_linewidth=3) == nothing
	@test set(print_size="10,10") == nothing
	closeall()
end

@testset "Failure expected" begin
	closeall()
	@test_throws ErrorException figure("invalid")
	@test_throws ErrorException figure(1.0)
    @test_throws ErrorException figure(1:2)
	@test_throws ErrorException closefigure(-1)
	@test_throws ErrorException closefigure("invalid")
	@test_throws ErrorException closefigure(1.0)
	@test_throws ErrorException closefigure(1:2)
	@test_throws ErrorException plot(0:10,0:11)
	z = rand(5,6)
	@test_throws ErrorException imagesc(1:5,1:7,z)
	for op = (:plot, :histogram)
		@test_throws MethodError op(0:10+im*0:10)
		@test_throws ErrorException op(0:10,legend=0)
		@test_throws ErrorException op(0:10,plotstyle="invalid")
		@test_throws ErrorException op(0:10,marker="invalid")
		@test_throws ErrorException op(0:10,marker=0)
		@test_throws ErrorException op(0:10,linewidth="b")
		@test_throws ErrorException op(0:10,linewidth=im)
		@test_throws ErrorException op(0:10,pointsize="b")
		@test_throws ErrorException op(0:10,pointsize=im)
		@test_throws ErrorException op(0:10,title=0)
		@test_throws ErrorException op(0:10,xlabel=0)
		@test_throws ErrorException op(0:10,ylabel=0)
		@test_throws ErrorException op(0:10,axis="invalid")
	end
	@test_throws ErrorException plot(1:10,xrange = "2:3")
	@test_throws ErrorException plot(1:10,xrange = "ab")
	# test `set`
	@test_throws ErrorException set(legend=3)
	@test_throws ErrorException set(plotstyle="A")
	@test_throws ErrorException set(color=3)
	@test_throws ErrorException set(marker="xyz")
	@test_throws ErrorException set(linewidth="A")
	@test_throws ErrorException set(pointsize="A")
	@test_throws ErrorException set(title=3)
	@test_throws ErrorException set(xlabel=3)
	@test_throws ErrorException set(ylabel=3)
	@test_throws ErrorException set(zlabel=3)
	@test_throws ErrorException set(fill="red")
	@test_throws ErrorException set(grid="xyz")
	@test_throws ErrorException set(terminal="x12")
	@test_throws ErrorException set(outputfile=3)
	@test_throws ErrorException set(print_color=3)
	@test_throws ErrorException set(print_fontface=3)
	@test_throws ErrorException set(print_fontscale="1")
	@test_throws ErrorException set(print_linewidth="3")
	@test_throws ErrorException set(print_size=10)
	closeall()
end

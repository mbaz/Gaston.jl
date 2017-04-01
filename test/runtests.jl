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
	@test plot(2,1:10) == 2
	@test plot(4,1:10) == 4
	@test closeall() == 3
	@test begin
		plot(sin(-3:0.01:3),
		"legend", "sine",
		"plotstyle", "lines",
		"color","blue",
		"marker","ecircle",
		"linewidth",2,
		"pointsize",1.1,
		"title","test plot 1",
		"xlabel","x",
		"ylabel","y",
		"box","inside horizontal left top",
		"axis","loglog") == 1
	end
	@test histogram(rand(1000)) == 1
	@test begin
		histogram(randn(1000),
        "bins",100,
        "norm",1,
        "color","blue",
        "linewidth",2,
        "title","test histogram",
        "xlabel","x",
        "ylabel","y",
        "box","inside horizontal left top")
	end == 1
	z = rand(5,6)
	@test imagesc(z,"title","test imagesc 1","xlabel","xx","ylabel","yy") == 1
	@test imagesc(1:5,z,"title","test imagesc 2","xlabel","xx","ylabel","yy") == 1
	@test imagesc(1:5,1:6,z,"title","test imagesc 3","xlabel","xx","ylabel","yy") == 1
	@test surf(rand(10,10)) == 1
	@test surf(2:11,rand(10,10)) == 1
	@test surf(0:9,2:11,rand(10,10)) == 1
    @test surf(0:9,2:11,(x,y)->x*y) == 1
	@test surf(0:9,2:11,(x,y)->x*y,"title","test","plotstyle","pm3d") == 1
	@test begin
		plot(1:10)
		printfigure()
	end == 1
	@test begin
		plot(2,1:10)
		printfigure(2,"png")
		closefigure()
	end == 2
	@test begin
		plot(1:10)
		printfigure("eps")
	end == 1
	@test printfigure("pdf") == 1
	@test begin
		set_print_size("640,480")
		printfigure("svg")
	end == 1
	@test printfigure("gif") == 1
	@test plot(1:10,"xrange","[2:3]") == 1
	@test plot(1:10,"xrange","[-1.1:3.4]") == 1
	@test plot(1:10,"xrange","[:3.4]") == 1
	@test plot(1:10,"xrange","[3.4:]") == 1
	@test plot(1:10,"xrange","[3.4:*]") == 1
	@test plot(1:10,"xrange","[*:3.4]") == 1
	closeall()
end

@testset "Failure expected" begin
	closeall()
	@test_throws MethodError figure("invalid")
	@test_throws MethodError figure(1.0)
    @test_throws MethodError figure(1:2)
	@test_throws ErrorException closefigure(-1)
	@test_throws ErrorException closefigure("invalid")
	@test_throws ErrorException closefigure(1.0)
	@test_throws ErrorException closefigure(1:2)
	for op = (:plot, :histogram)
		@test_throws MethodError op("linewidth")
		@test_throws MethodError op(0:10,0:11)
		@test_throws MethodError op(0:10+im*0:10)
		@test_throws MethodError op(0:10,"legend",0)
		@test_throws MethodError op(0:10,"plotstyle","invalid")
		@test_throws MethodError op(0:10,"marker","invalid")
		@test_throws MethodError op(0:10,"marker",0)
		@test_throws MethodError op(0:10,"linewidth","b")
		@test_throws MethodError op(0:10,"linewidth",im)
		@test_throws MethodError op(0:10,"pointsize","b")
		@test_throws MethodError op(0:10,"pointsize",im)
		@test_throws MethodError op(0:10,"title",0)
		@test_throws MethodError op(0:10,"xlabel",0)
		@test_throws MethodError op(0:10,"ylabel",0)
		@test_throws MethodError op(0:10,"zlabel","z")
		@test_throws MethodError op(0:10,"axis","invalid")
	end
	@test_throws AssertionError plot(1:10,"xrange","2:3")
	@test_throws AssertionError plot(1:10,"xrange","ab")
	closeall()
end

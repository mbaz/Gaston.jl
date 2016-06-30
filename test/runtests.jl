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

test_success_expected(r::Test.Success) = println("Success expected; test passed.")
test_success_expected(r) = println("Success expected; test failed: $(r.expr).")
test_failure_expected(r::Test.Success) = println("Error expected; test failed: $(r.expr)")
test_failure_expected(r) = println("Error expected; test passed.")

function run_tests_success_expected()
	set_filename(tempname())
	closeall()
	Test.with_handler(test_success_expected) do
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
            "box","inside horizontal left top") == 1
		end
		z = rand(5,6)
		@test imagesc(z,"title","test imagesc 1","xlabel","xx","ylabel","yy") == 1
		@test imagesc(1:5,z,"title","test imagesc 2","xlabel","xx","ylabel","yy") == 1
		@test imagesc(1:5,1:6,z,"title","test imagesc 3","xlabel","xx","ylabel","yy") == 1
		@test surf(rand(10,10)) == 1
		@test surf(2:11,rand(10,10)) == 1
		@test surf(0:9,2:11,rand(10,10)) == 1
	    @test surf(0:9,2:11,(x,y)->x*y) == 1
		@test surf(0:9,2:11,(x,y)->x*y,"title","test","plotstyle","pm3d") == 1
		@test printfigure() == 1
		@test begin
			plot(2,1:10)
			printfigure(2,"png")
			closefigure() == 2
		end
		@test printfigure("eps") == 1
		@test printfigure("pdf") == 1
		@test begin
			set_print_size("640,480")
			printfigure("svg") == 1
		end
		@test printfigure("gif") == 1
		@test plot(1:10,"xrange","[2:3]") == 1
		@test plot(1:10,"xrange","[-1.1:3.4]") == 1
		@test plot(1:10,"xrange","[:3.4]") == 1
		@test plot(1:10,"xrange","[3.4:]") == 1
		@test plot(1:10,"xrange","[3.4:*]") == 1
		@test plot(1:10,"xrange","[*:3.4]") == 1
		closeall()
	end
end

function run_tests_failure_expected()
	closeall()
	Test.with_handler(test_failure_expected) do
		# high-level functions: figure
		@test figure("invalid")
    	@test figure(1.0)
	    @test figure(1:2)
		# high-level functions: closefigure
		@test closefigure(-1)
		@test closefigure("invalid")
		@test closefigure(1.0)
		@test closefigure(1:2)
		# high-level functions: plot and histogram
		for op = (:plot, :histogram)
			@test op("linewidth")
			@test op(0:10,0:11)
			@test op(0:10+im*0:10)
			@test op(0:10,"legend",0)
			@test op(0:10,"plotstyle","invalid")
			@test op(0:10,"marker","invalid")
			@test op(0:10,"marker",0)
			@test op(0:10,"linewidth","b")
			@test op(0:10,"linewidth",im)
			@test op(0:10,"pointsize","b")
			@test op(0:10,"pointsize",im)
			@test op(0:10,"title",0)
			@test op(0:10,"xlabel",0)
			@test op(0:10,"ylabel",0)
			@test op(0:10,"zlabel","z")
			@test op(0:10,"axis","invalid")
		end
		@test plot(1:10,"xrange","2:3")
		@test plot(1:10,"xrange","ab")
	end
end

println("Running Gaston tests.")
run_tests_success_expected()
run_tests_failure_expected()

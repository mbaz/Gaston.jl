## Copyright (c) 2012 Miguel Bazdresch
##
## Permission is hereby granted, free of charge, to any person obtaining a
## copy of this software and associated documentation files (the "Software"),
## to deal in the Software without restriction, including without limitation
## the rights to use, copy, modify, merge, publish, distribute, sublicense,
## and/or sell copies of the Software, and to permit persons to whom the
## Software is furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
## DEALINGS IN THE SOFTWARE.


# Gaston test framework
#
# Note: once julia has its own test framework, we might want to migrate to it.
#
# There are three kinds of tests:
#   - Tests that should error -- things that Gaston should not allow, such as
#     building a figure with an invalid plotstyle. In these cases, Gaston
#     should issue an error().
#     For these tests, we use the test_error macro.
#   - Tests that should succeed -- things that should work without producing
#     an error.
#     For these tests, we use the test_success macro.
#   - Test that certain functions return certain values. These tests help to
#     verify the functions are working correctly, not just erroring or
#     succeeding.
#     For these tests, we use the test_success macro in combination with
#     @assert.
#
# In all cases, when a test fails, the expression under test is echoed to
# the screen to help identify it.

macro test_error(ex)
    quote
        testnumber = testnumber + 1
        testsrun = testsrun + 1
        s = strcat("Test number ", string(testnumber), ". Error expected. Result: ")
        try
            eval($ex)
            println(strcat(s, "Success (Test failed.)"))
            println($string(ex))
        catch
            println(strcat(s, "Error (Test passed.)"))
            testspassed = testspassed + 1
        end
    end
end

macro test_success(ex)
    quote
        testnumber = testnumber + 1
        testsrun = testsrun + 1
        s = strcat("Test number ", string(testnumber), ". Success expected. Result: ")
        try
            eval($ex)
            println(strcat(s, "Success (Test passed.)"))
            testspassed = testspassed + 1
        catch
            println(strcat(s, "Error (Test failed.)"))
            println($string(ex))
        end
    end
end

function run_tests_error(ini)
    testnumber = ini
    testspassed = 0
    testsrun = 0

    # high-level functions: figure
    @test_error figure(-1)
    @test_error figure("invalid")
    @test_error figure(1.0)
    @test_error figure(1:2)
    # high-level functions: closefigure
    @test_error closefigure(-1)
    @test_error closefigure("invalid")
    @test_error closefigure(1.0)
    @test_error closefigure(1:2)
    # high-level functions: plot and histogram
    for op = (:plot, :histogram)
        @test_error op("linewidth")
        @test_error op(0:10,0:11)
        @test_error op(0:10+im*0:10)
        @test_error op(0:10,"legend",0)
        @test_error op(0:10,"plotstyle","invalid")
        @test_error op(0:10,"marker","invalid")
        @test_error op(0:10,"marker",0)
        @test_error op(0:10,"linewidth","b")
        @test_error op(0:10,"linewidth",im)
        @test_error op(0:10,"pointsize","b")
        @test_error op(0:10,"pointsize",im)
        @test_error op(0:10,"title",0)
        @test_error op(0:10,"xlabel",0)
        @test_error op(0:10,"ylabel",0)
        @test_error op(0:10,"zlabel","z")
        @test_error op(0:10,"axis","invalid")
    end
    @test_error histogram(0:10,"plotstyle","lines")
    @test_error histogram(0:10,"bins")
    @test_error histogram(0:10,"bins","invalid")
    @test_error histogram(0:10,"bins",-1)
    @test_error histogram(0:10,"bins",3.1)
    @test_error histogram(0:10,"norm","invalid")
    @test_error histogram(0:10,"norm",-1)
    @test_error histogram(0:10,"marker","ecircle")
    @test_error histogram(0:10,"pointsize",1)
    @test_error histogram(0:10,"axis","loglog")
    ## tests that should fail, but (still) don't
    ## commented out because gnuplot barfs all over the screen
    #@test_error plot(0:10,"color","nonexistant")
    #@test_error plot(0:10,"box","invalid")

    return testsrun, testspassed
end

function run_tests_success(ini)
    testnumber = ini
    testspassed = 0
    testsrun = 0

    closeall()
    # high-level functions: closefigure
    @test_success closefigure()
    @test_success @assert 0 == closefigure()
    @test_success @assert 0 == closefigure(10)
    # high-level functions: figure
    @test_success @assert 1 == figure()
    @test_success @assert 1 == figure(1)
    @test_success @assert 3 == figure(3)
    @test_success begin
        closeall()
        @assert 1 == figure(1)
        @assert 2 == figure()
        @assert 5 == figure(5)
        closefigure(2)
        @assert 2 == figure()
        closeall()
    end
    closeall()
    # high-level functions: plot
    @test_success begin
        plot(0:10)
        closeall()
    end
    @test_success begin
        plot(sin(-3:0.01:3),
            "legend", "test",
            "plotstyle", "lines",
            "color","blue",
            "marker","ecircle",
            "linewidth",2,
            "pointsize",1.1,
            "title","test",
            "xlabel","x",
            "ylabel","y",
            "box","inside horizontal left top",
            "axis","loglog")
        closeall()
    end
    # high-level functions: histogram
    @test_success begin
        histogram(rand(1000))
        closeall()
    end
    @test_success begin
        histogram(randn(1000),
            "bins",100,
            "norm",1,
            "color","blue",
            "linewidth",2,
            "title","test",
            "xlabel","x",
            "ylabel","y",
            "box","inside horizontal left top")
        closeall()
    end
    @test_success figure(10)
    # type instantiation
    @test_success CurveConf()

    return testsrun, testspassed
end

function run_tests()
    println("Running tests...")
    (total,passed) = run_tests_error(0)
    (total1,passed1) = run_tests_success(total)
    s = println(strcat("Tests run: ", string(total+total1)))
    s = println(strcat("Tests passed: ", string(passed+passed1)))
end

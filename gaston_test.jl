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

macro test_error(ex)
    quote
        tn = tn + 1
        s = strcat("Test number ", string(tn), ". Error expected. Result: ")
        try
            eval($ex)
            println(strcat(s, "Success (Test failed.)"))
        catch
            println(strcat(s, "Error (Test passed.)"))
            tp = tp + 1
        end
    end
end

macro test_success(ex)
    quote
        tn = tn + 1
        s = strcat("Test number ", string(tn), ". Success expected. Result: ")
        try
            eval($ex)
            println(strcat(s, "Success (Test passed.)"))
            tp = tp + 1
        catch
            println(strcat(s, "Error (Test failed.)"))
        end
    end
end

function run_tests_error()
    tn = 0
    tp = 0
    # high-level functions: figure
    @test_error figure(-1)
    @test_error figure("invalid")
    @test_error figure(1.0)
    @test_error figure(1:2)
    # high-level functions: closefigure
    @test_error closefigure(-1)  # TODO: should fail
    @test_error closefigure("invalid")  # TODO: should fail
    @test_error closefigure(1.0)  # TODO: should fail
    @test_error closefigure(1:2)  # TODO: should fail
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
    return tn, tp
end

function run_tests_success()
    tn = 0
    tp = 0
    closeall()
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
    # type instantiation
    @test_success CurveConf()
    return tn, tp
end

function run_tests()
    println("Running tests...")
    (tn_e,tp_e) = run_tests_error()
    (tn_s,tp_s) = run_tests_success()
    s = println(strcat("Tests run: ", string(tn_e+tn_s)))
    s = println(strcat("Tests passed: ", string(tp_e+tp_s)))
end

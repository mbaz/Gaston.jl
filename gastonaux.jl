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

# write commands to gnuplot's pipe
function gnuplot_send(s::String)
    fid = gnuplot_state.fid
    err = ccall(:fputs, Int, (Ptr{Uint8},Ptr), strcat(s,"\n"), fid)
    # fputs returns a positive number if everything worked all right
    if err < 0
        println("Something went wrong writing to the gnuplot pipe.")
        return
    end
    err = ccall(:fflush, Int, (Ptr,), fid)
    ## fflush returns 0 if everything worked all right
    if err != 0
        println("Something went wrong writing to the gnuplot pipe.")
        return
    end
end

# initialize
# The way to interface to gnuplot is by setting up a pipe that gnuplot
# reads commands from. I don't see how to create such a 'persistent'
# pipe from Julia, so we have to use libc's 'popen' call.
function gnuplot_init()
    global gnuplot_state
    f = ccall(:popen, Ptr, (Ptr{Uint8},Ptr{Uint8}), "gnuplot" ,"w")
    if f == 0
        println("There was a problem starting up gnuplot.")
        return
    else
        gnuplot_state.running = true
        gnuplot_state.fid = f
    end
end

# close gnuplot pipe
function gnuplot_exit(x...)
    global gnuplot_state
    if gnuplot_state.running
        # close pipe
        err = ccall(:pclose, Int, (Ptr,), gnuplot_state.fid)
        # err should be zero
        if err != 0
            println("Gnuplot may not have closed correctly.");
        end
    end
    # reset gnuplot_state
    gnuplot_state.running = false
    gnuplot_state.current = 0
    gnuplot_state.fid = 0
end
# when gnuplot_state goes out of scope, close the pipe
finalizer(gnuplot_state,gnuplot_exit)

# convert marker string description to gnuplot's expected number
function pointtype(x::ASCIIString)
    if x == "+"
        return 1
    elseif x == "x"
        return 2
    elseif x == "*"
        return 3
    elseif x == "esquare"
        return 4
    elseif x == "fsquare"
        return 5
    elseif x == "ecircle"
        return 6
    elseif x == "fcircle"
        return 7
    elseif x == "etrianup"
        return 8
    elseif x == "ftrianup"
        return 9
    elseif x == "etriandn"
        return 10
    elseif x == "ftriandn"
        return 11
    elseif x == "edmd"
        return 12
    elseif x == "fdmd"
        return 13
    end
    return 1
end

# return configuration string for a single plot
function linestr_single(conf::Curve_conf)
    s = ""
    if conf.legend != ""
        s = strcat(s, " title '", conf.legend, "' ")
    else
        s = strcat(s, "notitle ")
    end
    s = strcat(s, " with ", conf.plotstyle, " ")
    if conf.color != ""
        s = strcat(s, "linecolor rgb '", conf.color, "' ")
    end
    s = strcat(s, "lw ", string(conf.linewidth), " ")
    # some plotstyles don't allow point specifiers
    cp = conf.plotstyle
    if cp != "lines" && cp != "impulses" && cp != "pm3d" && cp != "image" && cp != "rgbimage"
        if conf.marker != ""
            s = strcat(s, "pt ", string(pointtype(conf.marker)), " ")
        end
        s = strcat(s, "ps ", string(conf.pointsize), " ")
    end
    return s
end

# build a string with plot commands according to configuration
function linestr(curves::Vector{Curve_data},cmd::ASCIIString, file::ASCIIString,postcmd::ASCIIString)
    # We have to insert "," between plot commands. One easy way to do this
    # is create the first plot command, then the rest
    # We also need to keep track of the current index (starts at zero)
    index = 0
    s = strcat(cmd," '",file,"' ",postcmd," i 0 ",linestr_single(curves[1].conf))
    if length(curves) > 1
        for i in curves[2:end]
            index += 1
            s = strcat(s,", '",file,"' ",postcmd," i ",string(index)," ",linestr_single(i.conf))
        end
    end
    return s
end

# create a Z-coordinate matrix from x, y coordinates and a function
function meshgrid(x,y,f)
    Z = zeros(length(x),length(y))
    for k = 1:length(x)
        Z[k,:] = [ f(i,j) | i=x[k], j=y ]
    end
    return Z
end

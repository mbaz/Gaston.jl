## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Asynchronously reads the specified IO.
# In case of timeout sends :timeout; in case of end of file, sends :eof.
function async_reader(io::IO, timeout_sec)::Channel
    ch = Channel(1)
    task = @async begin
        reader_task = current_task()
        function timeout_cb(timer)
            put!(ch, :timeout)
            Base.throwto(reader_task, InterruptException())
        end
        timeout = Timer(timeout_cb, timeout_sec)
        data = String(readavailable(io))
        if data == ""; put!(ch, :eof); return; end
        timeout_sec > 0 && close(timeout) # Cancel the timeout
        put!(ch, data)
    end
    bind(ch, task)
    return ch
end

# Write plotting data to file.
# `curve` is a Curve.
# `file` is the file to write to.
# If `append` is true, data is appended at the end of the file (for `plot!`)
# TODO: generalize to more formats
function write_data(curve, file; append = false)
    mode = "w"
    append && (mode = "a")
    open(file, mode) do io
        ps = curve.conf.plotstyle
        # 2-d plot: z is empty
        if isempty(curve.z)
            # error bars
            if ps == "errorbars" || ps == "errorlines"
                if isempty(curve.E.yhigh)
                    # ydelta (single error coordinate)
                    writedlm(io,[curve.x curve.y curve.E.ylow])
                else
                    # ylow, yhigh (double error coordinate)
                    writedlm(io,[curve.x curve.y curve.E.ylow curve.E.yhigh])
                end
            # financial bars
            elseif ps == "financebars"
                writedlm(io,[curve.x curve.F.open curve.F.low curve.F.high curve.F.close])
            # regular plot; format is "x y"
            else
                writedlm(io,[curve.x curve.y])
            end
        # image; format is "x y z" with reversed "y"
        elseif length(ps)>4 && ps[1:5] == "image"
            x = repeat(curve.x,inner=length(curve.y))
            y = repeat(reverse(curve.y),length(curve.x))
            z = vec(curve.z)
            writedlm(io,[x y z])
        # rgbimage; format is "x y r g b" with reversed "y"
        elseif ps == "rgbimage"
            x = repeat(curve.x,inner=length(curve.y))
            y = repeat(reverse(curve.y),length(curve.x))
            r = vec(curve.z[1,:,:])
            g = vec(curve.z[2,:,:])
            b = vec(curve.z[3,:,:])
            writedlm(io,[x y r g b])
        # 3-D image
        else
            # surface plot; format is in "triplets" (gnuplot manual, p. 197)
            if isa(curve.z, Matrix)
                ly = length(curve.y)
                tmparr = zeros(ly, 3)
                for (xi,x) in enumerate(curve.x)
                    tmparr[:,1] .= x
                    tmparr[:,2] = curve.y
                    tmparr[:,3] = curve.z[:,xi]
                    writedlm(io, tmparr)
                    write(io,'\n')
                end
            # scatter plot: format is in "triplets"
            else
                tmparr = zeros(3)
                for k in 1:length(curve.x)
                    tmparr[1] = curve.x[k]
                    tmparr[2] = curve.y[k]
                    tmparr[3] = curve.z[k]
                    writedlm(io,tmparr')
                end
                write(io,"\n")
            end
        end
        write(io,"\n\n")
    end
end

# llplot() is our workhorse plotting function
function llplot(fig::Figure;print=false)
    global gnuplot_state

    # if figure has no data, stop here
    if isempty(fig)
        return
    end

    gnuplot_send("\nreset session\n")

    # Send all commands to gnuplot
    # Build terminal setup string
    gnuplot_send(termstring(fig,print))
    # Build figure configuration string
    gnuplot_send(figurestring(fig))
    # Set output file if necessary
    print && gnuplot_send("set output '$(fig.print.output)'")
    # Send user command to gnuplot
    gnuplot_send(fig.gpcom)
    # send plot command to gnuplot
    gnuplot_send(plotstring(fig))
    # Close output files, if any
    gnuplot_send("set output")

    # Make sure gnuplot is done.
    err = ""
    gnuplot_state.gp_lasterror = err
    gnuplot_state.gp_error = false

    gnuplot_send("""set print '-'
                    print 'GastonDone'""")

    # Start reading gnuplot's streams in "background"
    ch_out = async_reader(P.gstdout, config[:timeouts][:stdout_timeout])
    out = take!(ch_out)
    out === :timeout && @warn("Gnuplot is taking too long to respond.")
    out === :eof     && error("Gnuplot crashed")

    # check for errors while plotting
    if bytesavailable(P.gstderr) > 0
        err = String(readavailable(P.gstderr))
        gnuplot_state.gp_lasterror = err
        gnuplot_state.gp_error = true
        @warn("Gnuplot returned an error message:\n  $err")
    end

    return nothing

end

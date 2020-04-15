## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Asynchronously reads the IO and buffers the read content. When end marker
# (GastonDone, which is stored in `gmarker` to account for Unix/Windows
# variability in line endings) is found in the content, sends everything
# between start (GastonBegin) and end markers to the returned channel.
# In case of timeout sends :timeout; in case of end of file, sends :eof.

function async_reader(io::IO, timeout_sec)::Channel
    ch = Channel(1)
    task = @async begin
        reader_task = current_task()
        function timeout_cb(timer)
            put!(ch, :timeout)
            Base.throwto(reader_task, InterruptException())
        end

        buf = ""
        while (match_done = findfirst(gmarker_done, buf)) == nothing
            timeout = Timer(timeout_cb, timeout_sec)
            data = String(readavailable(io))
            if data == ""; put!(ch, :eof); return; end
            timeout_sec > 0 && close(timeout) # Cancel the timeout
            buf *= data
        end
        match_begin = findfirst(gmarker_start, buf)
        start = (match_begin != nothing) ? last(match_begin)+1 : 1
        put!(ch, buf[start:first(match_done)-1])
    end
    bind(ch, task)
    return ch
end

# llplot() is our workhorse plotting function
function llplot(fig::Figure;print=false)
    global gnuplot_state

    # if figure has no data, stop here
    if isempty(fig)
        return
    end

    # In order to capture all output produced by our plotting commands
    # (error messages and figure text in case of text terminals), we
    # send "marks" to the stdout and stderr streams before the first
    # and after the last command. Everything between these marks will
    # be returned by our async_readers.
    gnuplot_send("\nreset session\n")
    gnuplot_send("set print \"-\"") # Redirect print to stdout
    gnuplot_send("print \"GastonBegin\"")
    gnuplot_send("printerr \"GastonBegin\"")

    # Build terminal setup string and send it to gnuplot
    gnuplot_send(termstring(fig,print))

    # Datafile filename. This is where we store the coordinates to plot.
    # This file is then read by gnuplot to do the actual plotting. One file
    # per figure handle is used; this avoids polutting /tmp with too many files.
    filename = joinpath(tempdir(),"gaston-$(tmpprefix)-$(fig.handle)")
    f = open(filename,"w")

    # Send appropriate coordinates and data to gnuplot, depending on
    # whether we are doing 2-d, 3-d or image plots.
    for curve in fig.curves
        ps = curve.conf.plotstyle
        # 2-d plot: z is empty
        if isempty(curve.z)
            # error bars
            if ps == "errorbars" || ps == "errorlines"
                if isempty(curve.E.yhigh)
                    # ydelta (single error coordinate)
                    writedlm(f,[curve.x curve.y curve.E.ylow])
                else
                    # ylow, yhigh (double error coordinate)
                    writedlm(f,[curve.x curve.y curve.E.ylow curve.E.yhigh])
                end
            # financial bars
            elseif ps == "financebars"
                writedlm(f,[curve.x curve.F.open curve.F.low curve.F.high curve.F.close])
            # regular plot; format is "x y"
            else
                writedlm(f,[curve.x curve.y])
            end
        # image; format is "x y z" with reversed "y"
        elseif length(ps)>4 && ps[1:5] == "image"
            x = repeat(curve.x,inner=length(curve.y))
            y = repeat(reverse(curve.y),length(curve.x))
            z = vec(curve.z)
            writedlm(f,[x y z])
        # rgbimage; format is "x y r g b" with reversed "y"
        elseif ps == "rgbimage"
            x = repeat(curve.x,inner=length(curve.y))
            y = repeat(reverse(curve.y),length(curve.x))
            r = vec(curve.z[1,:,:])
            g = vec(curve.z[2,:,:])
            b = vec(curve.z[3,:,:])
            writedlm(f,[x y r g b])
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
                    writedlm(f, tmparr)
                    write(f,'\n')
                end
            # scatter plot: format is in "triplets"
            else
                tmparr = zeros(3)
                for k in 1:length(curve.x)
                    tmparr[1] = curve.x[k]
                    tmparr[2] = curve.y[k]
                    tmparr[3] = curve.z[k]
                    writedlm(f,tmparr')
                end
                write(f,"\n")
            end
        end
        write(f,"\n\n")
    end
    close(f)

    # Send gnuplot commands.
    # Build figure configuration to send to gnuplot
    gnuplot_send_fig_config(fig.axes)
    # Send user command to gnuplot
    !isempty(fig.gpcom) && gnuplot_send(fig.gpcom)
    # send plot command to gnuplot
    if isempty(fig.curves[1].z) || occursin("image",fig.curves[1].conf.plotstyle)
        pcom = "plot"
    else
        pcom = "splot"
    end
    gnuplot_send(linestr(fig.curves, pcom, filename))

    # Close output files, if any
    gnuplot_send("set output")

    # Make sure gnuplot is done; if terminal is text, read data
    # reset error handling
    err = ""
    gnuplot_state.gp_lasterror = err
    gnuplot_state.gp_error = false

    gnuplot_send("print \"GastonDone\"")
    gnuplot_send("printerr \"GastonDone\"")

    # Start reading gnuplot's streams in "background"
    ch_out = async_reader(P.gstdout, config[:timeouts][:stdout_timeout])
    ch_err = async_reader(P.gstderr, config[:timeouts][:stderr_timeout])

    out = take!(ch_out)
    err = take!(ch_err)

    out === :timeout && error("Gnuplot is taking too long to respond.")
    out === :eof     && error("Gnuplot crashed")

    # We don't care about stderr timeouts.
    err === :timeout && (err = "")
    err === :eof     && (err = "")

    # check for errors while plotting
    if err != ""
        gnuplot_state.gp_lasterror = err
        gnuplot_state.gp_error = true
        @warn("Gnuplot returned an error message:\n  $err)")
    end

    # if there was no error and text terminal, read all data from stdout
    if err == ""
        if (config[:term][:terminal] ∈ term_text) || (config[:mode] == "ijulia")
            fig.svg = out
        end
    end

    return nothing

end

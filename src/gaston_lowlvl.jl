## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# write commands to gnuplot's pipe
function gnuplot_send(s::AbstractString)
    gin = gnuplot_state.fid[1] # gnuplot STDIN
    w = write(gin, string(s,"\n"))
    # check that data was accepted by the pipe
    if !(w > 0)
        println("Something went wrong writing to gnuplot STDIN.")
        return
    end
    flush(gin)
end

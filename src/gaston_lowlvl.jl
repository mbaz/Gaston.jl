## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# write commands to gnuplot's pipe
function gnuplot_send(s::String)
    fid = gnuplot_state.fid
    err = ccall(:fputs, Int, (Ptr{Uint8},Ptr{Int}), string(s,"\n"), fid)
    # fputs returns a positive number if everything worked all right
    if err < 0
        println("Something went wrong writing to the gnuplot pipe.")
        return
    end
    err = ccall(:fflush, Int, (Ptr{Int},), fid)
    ## fflush returns 0 if everything worked all right
    if err != 0
        println("Something went wrong writing to the gnuplot pipe.")
        return
    end
end

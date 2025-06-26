## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Write plot data to a file.
# 
# Valid arguments:
#
# Case 1: n×1...
# In this format, there are N n×1 vectors. Data is written as one block,
# with N coordinates per line.
#
# Case 2: n×1 m×1 n×m...
# In this format, there are N n×m matrices. Data is written as n blocks,
# each block made up of triplets, with the first coordinate constant in
# each block.
#
function writedata(file, args... ; append=false)
    @debug "writedata()" size.(args)
    @debug "writedata()" args
    mode = "w"
    append && (mode = "a")
    nl = "\n"
    iob = IOBuffer()
    # Case 1: all args are 1-D: mx1 mx1 mx1...
    if all(ndims.(args) .== 1)
        if minimum(length.(args)) == maximum(length.(args))
            d = hcat(args...)
            writedlm(iob, d)
            write(iob, nl*nl)
        else
            error("Incompatible vector lengths")
        end
    # Case 2: n×1 m×1 n×m...
    elseif (length(args) >= 3) && (ndims(args[1]) == 1) && (ndims(args[2]) == 1) && (ndims(args[3]) == 2)
        n::Int = size(args[2])[1]
        m::Int = size(args[1])[1]
        al::Int = length(args)
        if size(args[3]) == (n, m)
            block = zeros(n, al)
            for xi in eachindex(args[1])
                block[:,1] .= args[1][xi]
                block[:,2] .= args[2]
                for k in 3:al
                    block[:,k] .= args[k][:,xi]
                end
                writedlm(iob, block)
                write(iob, nl)
            end
            write(iob, nl*nl)
        else
            @debug "writedata()" n m size(args[3])
            error("Incompatible array lengths")
        end
    # Case 3: n×m n×m n×m...
    elseif (ndims(args[1]) == 2) && (ndims(args[2]) == 2) && (ndims(args[3]) == 2)
        (n, m) = size(args[1])
        al = length(args)
        if (size(args[2]) == (n, m)) || size(args[3] == (n, m))
            block = zeros(n, al)
            for xi in axes(args[1], 2)
                block[:,1] .= args[1][:,xi]
                block[:,2] .= args[2][:,xi]
                block[:,3] .= args[3][:,xi]
                for k in 4:al
                    block[:,k] .= args[k][:,xi]
                end
                writedlm(iob, block)
                write(iob, nl)
            end
        else
            @debug "writedata()" n m size(args[3])
            error("Incompatible array lengths")
        end
    end
    open(file, mode, lock = false) do io
        seekstart(iob)
        write(io, iob)
    end
    nothing
end

"Handle data stored in a DataBlock"
function writedata(file, table::DataBlock)
    seekstart(table.data)
    write(file, table.data)
end

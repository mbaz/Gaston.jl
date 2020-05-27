## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Save a figure to a file.
function save(;handle::Int = gnuplot_state.current,
               term       = "",
               termopts   = "",
               font       = "",
               size       = "",
               linewidth  = 0,
               background = "",
               output     = "",
               args...)

    # process arguments
    isempty(output) && throw(DomainError("Please specify an output filename."))
    isempty(term) && throw(DomainError("Please specify a file format"))

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    fig = gnuplot_state.figs[h]

    for k in keys(args)
        k == :bg && (background = args[k])
        k == :lw && (linewidth = args[k])
    end
    (term == "pdf" || term == :pdf) && (term = "pdfcairo")
    (term == "png" || term == :png) && (term = "pngcairo")
    (term == "eps" || term == :eps) && (term = "epscairo")

    # create print configuration
    pc = "set term $term "
    !isempty(font) && (pc *= "font '$font' ")
    !isempty(size) && (pc *= "size $size ")
    linewidth > 0 && (pc *= "linewidth $linewidth ")
    !isempty(background) && (pc *= "background '$background' ")
    !isempty(termopts) && (pc *= termopts)

    # send gnuplot commands
    llplot(fig, printstring=(pc,output))

    return nothing
end

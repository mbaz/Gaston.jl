## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

"""
    save(term, output, [termopts,] [font,] [size,] [linewidth,] [background,] [handle]) -> nothing

Save current figure (or figure specified by `handle`) using the specified `term`. Optionally,
the font, size, linewidth, and background may be specified as arguments.
"""
function save(; term::String,
                output::String,
                handle::Int = gnuplot_state.current,
                font        = "",
                size        = "",
                linewidth   = 0,
                background  = "",
                saveopts    = config[:saveopts])

    debug("term = $term, output = $output, saveopts = $saveopts", "save")

    # process arguments
    isempty(output) && throw(DomainError("Please specify an output filename."))
    isempty(term) && throw(DomainError("Please specify a file format"))

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    fig = gnuplot_state.figs[h]

    (term == "pdf" || term == :pdf) && (term = "pdfcairo")
    (term == "png" || term == :png) && (term = "pngcairo")
    (term == "eps" || term == :eps) && (term = "epscairo")

    # create print configuration
    pc = "set term $term "
    if isempty(saveopts)
        !isempty(font) && (pc *= "font '$font' ")
        !isempty(size) && (pc *= "size $size ")
        linewidth > 0 && (pc *= "linewidth $linewidth ")
        !isempty(background) && (pc *= "background '$background' ")
    else
        pc *= saveopts
    end

    # send gnuplot commands
    llplot(fig, printstring=(pc,output))

    return nothing
end

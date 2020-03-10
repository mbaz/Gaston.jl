## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# print a figure to a file
function printfigure(;handle::Handle    = gnuplot_state.current,
                     term::String       = config[:print][:print_term],
                     font::String       = config[:print][:print_font],
                     size::String       = config[:print][:print_size],
                     linewidth::String  = config[:print][:print_linewidth],
                     background::String = config[:print][:print_background],
                     outputfile::String = config[:print][:print_outputfile]
                    )

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    isempty(outputfile) && throw(DomainError("Please specify an output filename."))

    # set figure's print parameters
    term == "pdf" && (term = "pdfcairo")
    term == "png" && (term = "pngcairo")
    term == "eps" && (term = "epscairo")
    valid_file_term(term)

    font == "" && (font = TerminalDefaults[term][:font])
    size == "" && (size = TerminalDefaults[term][:size])
    linewidth == "" && (linewidth = "1")
    background == "" && (background = TerminalDefaults[term][:background])

    fig = gnuplot_state.figs[h]
    pc = PrintConf(term,font,size,linewidth,background,outputfile)
    fig.print = pc
    llplot(fig,print=true)
    gnuplot_send("set output") # gnuplot needs this to close the output file

    return nothing
end

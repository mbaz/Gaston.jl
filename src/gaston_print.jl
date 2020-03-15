## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# print a figure to a file
function printfigure(;handle::Handle    = gnuplot_state.current,
                     term::String       = config[:print][:print_term],
                     args...)

    # process arguments
    PA = PlotArgs()
    for k in keys(args)
        # substitute synonyms
        key = k
        for s in syn
            key ∈ s && (key = s[1]; break)
        end
        # substitute print arguments
        key == :font && (key = :printfont)
        key == :size && (key = :printsize)
        key == :linewidth && (key = :printlinewidth)
        key == :background && (key = :printbackground)
        # store arguments
        for f in fieldnames(PlotArgs)
            f == key && (setfield!(PA, f, string(args[k])); break)
        end
    end

    h = findfigure(handle)
    h == 0 && throw(DomainError(h, "requested figure does not exist."))
    isempty(PA.outputfile) && throw(DomainError("Please specify an output filename."))

    # set figure's print parameters
    term == "pdf" && (term = "pdfcairo")
    term == "png" && (term = "pngcairo")
    term == "eps" && (term = "epscairo")
    valid_file_term(term)

    PA.printfont == "" && (printfont = TerminalDefaults[term][:font])
    PA.printsize == "" && (printsize = TerminalDefaults[term][:size])
    PA.printlinewidth == "" && (printlinewidth = "1")
    PA.printbackground == "" && (printbackground = TerminalDefaults[term][:background])

    fig = gnuplot_state.figs[h]
    pc = PrintConf(print_term       = term,
                   print_font       = PA.printfont,
                   print_size       = PA.printsize,
                   print_linewidth  = PA.printlinewidth,
                   print_background = PA.printbackground,
                   print_outputfile = PA.outputfile)
    fig.print = pc
    llplot(fig,print=true)

    return nothing
end

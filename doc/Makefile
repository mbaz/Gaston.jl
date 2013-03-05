examples = plotex.pdf imagescex.pdf histoex.pdf surfex.pdf

gastondoc.pdf : $(examples) gastondoc.tex examples.jl
	xelatex -shell-escape gastondoc
	while grep -q 'Rerun to get' gastondoc.log ; \
		do xelatex -shell-escape gastondoc ; \
	done

$(examples) : examples.jl
	julia examples.jl

.PHONY : clean
clean :
	rm $(examples) gastondoc.pdf *aux *log *toc

.PHONY : help
help :
	$(help_text)

define help_text
# Make sure of the following:
#
#   * julia is in your path
#   * you have package Gaston installed
#   * you have xelatex installed
#   * you have Linux Libertine fonts installed
#   	(inspect output of 'fc-list|grep Libertine')
#   * you have the development version of pygments
#     (see http://pygments.org/docs/installation/)
#
# If those conditions are not met, then modify
# this Makefile/gastondoc.tex/examples.jl accordingly.
#
# To build the documentation, simply type 'make'.
#
# If you don't meet all requirements, you can download
# PDF documentation from http://bitbucket.org/mbaz/gaston/downloads
endef

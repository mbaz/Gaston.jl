## Copyright (c) 2019 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD license.

# Set up pipes and start gnuplot process

# initialize pipes and run gnuplot
gstdin = Pipe()
gstdout = Pipe()
gstderr = Pipe()
gproc = run(pipeline(`gnuplot`,
                     stdin = gstdin, stdout = gstdout, stderr = gstderr),
                     wait = false)
process_running(gproc) || error("There was a problem starting up gnuplot.")
close(gstdout.in)
close(gstderr.in)
close(gstdin.out)

## Copyright (c) 2019 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD license.

# Set up pipes and start gnuplot process

# Async tasks to read/write to gnuplot's pipes.
const StartTasks = Condition()  # signal to start reading pipes

const ChanStdOut = Channel(10)
const ChanStdErr = Channel(10)

# This task reads all characters available from gnuplot's stdout.
@async begin
    wait(StartTasks)
    while true
        stdoutstr = String(readavailable(gstdout))
        process_running(gproc) || break
        put!(ChanStdOut, stdoutstr)
    end
end

# This task reads all characters available from gnuplot's stderr.
@async begin
    wait(StartTasks)
    while true
        stderrstr = String(readavailable(gstderr))
        process_running(gproc) || break
        put!(ChanStdErr, stderrstr)
    end
end

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

# Start tasks to read and write gnuplot's pipes
NTasks = notify(StartTasks)

Inter-process Communication
===========================

An example Ruby program that traps the USR1 signal and read to a named pipe, to be used as a proof of concept for inter-process commnication.

Idea
----

A program, let's call it _main_, emits the USR1 signal, creates a named pipe (*hook_pipe*) then pauses.
Another program traps that USR1 signal, performs some task, and write the result to the *hook_pipe*.
The main program reads the result from the *hook_pipe* and resumes.

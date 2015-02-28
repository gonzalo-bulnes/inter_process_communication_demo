Demo: Inter-process Communication
=================================

An example Ruby program that traps the USR1 signal and read to a named pipe, to be used as a proof of concept for inter-process commnication.

Idea
----

A program, let's call it _main_, emits the USR1 signal, creates a named pipe (*hook_pipe*) then pauses.
Another program traps that USR1 signal, performs some task, and write the result to the *hook_pipe*.
The main program reads the result from the *hook_pipe* and resumes.

Usage
-----

_Note: for now, there are no signals involved._

Install dependencies, using [RVM][rvm] is optional but strongly recommended:

```bash
# trigger the RVM hooks so the gems get installed in an dedicated gemset
cd inter_process_communication_demo

# install dependencies
bundle install
```

  [rvm]: https://rvm.io

### Basic named pipes

Create the _named pipes_ that will be used by `main.rb` and `worker.rb` to communicate:

```bash
cd lib/01_basic_named_pipes

# create a named pipe for the main program to notify
# the worker about a hook to be performed
mkfifo main_to_worker

# create another named pipe for the worker to reply
# to the main program
mkfifo worker_to_main

# once you're done using them, remove both pipes:
#rm main_to_worker worker_to_main
```

In the fist scenario, the worker is waiting for hook requests:

```bash
# Scenario 1

# start the worker
ruby worker.rb # will wait until there is a hook to perform

# in a distinct terminal, start the main program
ruby main.rb # since the worker is available, the hook is performed immediately
```

In the second scenario, the main program is waiting for workers to be available:

```bash
# Scenario 2

# start the main program
ruby main.rb # will wait until a wroker preforms the hook

# in a distinct terminal, start the worker
ruby worker.rb # since a hook request was performed, performs the hook immediately
```

References
----------

- [Using Named Pipes in Ruby for Inter-process Communication][dix]

  [dix]: http://www.pauldix.net/2009/07/using-named-pipes-in-ruby-for-interprocess-communication.html

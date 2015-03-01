Demo: Inter-process Communication
=================================

An example Ruby program that traps the USR1 signal and read to a named pipe, to be used as a proof of concept for inter-process commnication.

Idea
----

A program, let's call it _main_, is called from another which provides a _worker_ to perform hook that the main program requests.

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

### Signals

**Note**: Signals don't seem to be the way to go, see these [signals limitations][signals].

The idea was having a `worker_on_demand`, which would start the `main` program (provinding its own PID to it).
The main program would sent a signal each time a hook would need to be performed.

```bash
cd lib/02_signals

# start
ruby worker_on_demand.rb # multiple hook requests are handled by the worker
```

### Named pipes and fork

The first example has two limitations:
- only one hook request can be handled by the worker
- the main program and the worker must agree on two named pipes to communicate

To be able to handle any number of hook requests, the worker must be able to loop while the main program is running. Of course, it should exit once the main program has exited.

In order to do so, let's introduce the `worker_provider` program. It will start a looping worker, then start the main program, and make sure the worker exits when the main program does. It will also provide both named pipes to both the worker and the main program.

```bash
cd lib/02_named_pipes_and_fork

# start the worker provider program
ruby worker_provider.rb # will start a worker and a main program with several hooks to perform
```

References
----------

- [Using Named Pipes in Ruby for Inter-process Communication][dix]
- [Ruby 2.2.0 documentation: Process][doc]
- [Forking and IPC in Ruby, Part II][fk]

  [dix]: http://www.pauldix.net/2009/07/using-named-pipes-in-ruby-for-interprocess-communication.html
  [fk]: http://www.sitepoint.com/forking-ipc-ruby-part-ii
  [signals]: https://github.com/gonzalo-bulnes/inter_process_communication_demo/blob/add-signal-handling-to-handle-multiple-hooks/lib/02_signals/on_demand_worker.rb#L48-L56
  [doc]: http://ruby-doc.org/core-2.2.0/Process.html

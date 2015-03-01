require 'active_support'
require 'multi_json'

puts 'Worker provider program.'

# In order to send hook requests and receive the corresponding response,
# the main program needs to have access to two named pipes.
# One way to do that is providing them to the main program
# as command-line aguments when starting it.

# The worker will need those methods.

# Both named pipes:

def main_to_worker
  "main_to_worker" # the pipes are created in the current working directory
end

def worker_to_main
  "worker_to_main"
end

# The method to format the message:

def format_message(body, options={})
  formatted_message = "\n"
  options.each do |key, value|
    formatted_message += key.capitalize + ': ' + value + "\n" unless value.empty?
  end
  formatted_message += "----\n" + body
end

# And all operations that are required to handle a hook (including
# reading and writing to the named pipes):

def handle_hook_request
  input = open(main_to_worker, "r+") # the r+ means we don't block
  json_hook_request = input.gets # will block if there's nothing in the pipe
  hook_request = MultiJson.load(json_hook_request)

  puts 'hook_request: ' + hook_request.inspect

  method = ActiveSupport::Inflector.underscore(hook_request['hook']['name'])
  args = hook_request['hook']['args']

  payload = send(method, args.slice(0), args.slice(1))

  response = { exitStatus: 0, payload: payload }
  json_response = MultiJson.dump(response)

  # notify success or failure to the main program
  output = open(worker_to_main, "w+") # the w+ means we don't block
  output.puts json_response
  output.flush
end

# The following will a worker which will loop until the main program exits.
#
# Since the main program is not yet running, hence has emitted
# no hook requests, the worker will wait. But the worker provider continues...

worker_pid = fork do
  puts "Worker program. (PID: #{$$})"
  loop do
    handle_hook_request
  end
end

# and starts the main program.
#
# Contrary to the worker, which should not block the worker provider,
# there is nothing more to do for the worker provider before
# the main program exits. It will then wait for it.

# here are the named pipes as command-line arguments
command = "ruby main.rb #{main_to_worker} #{worker_to_main}"
# running ruby from system can look silly,
# but the main program could not be a Ruby program.
exit_status = system(command)

puts "\nMain program #{exit_status ? 'exited successfully.' : 'failed.'}"

Process.kill('TERM', worker_pid) # make sure the worker exited before exiting
puts 'Worker exited.'

# Both the main program and the worker exited, it's save to exit.

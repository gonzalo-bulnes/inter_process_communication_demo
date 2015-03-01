require 'active_support'
require 'multi_json'

puts 'On-demand worker program.'

# In order to play with signals, the main program needs to have access
# to the worker PID. One way to do that is providing the worker PID to
# the main program when starting it.

# TPerforming the worker tasks will require these methods.

def format_message(body, options={})
  formatted_message = "\n"
  options.each do |key, value|
    formatted_message += key.capitalize + ': ' + value + "\n" unless value.empty?
  end
  formatted_message += "----\n" + body
end

def handle_hook_request
  input = open("main_to_worker", "r+") # the r+ means we don't block
  json_hook_request = input.gets # will block if there's nothing in the pipe
  hook_request = MultiJson.load(json_hook_request)

  puts 'hook_request: ' + hook_request.inspect

  method = ActiveSupport::Inflector.underscore(hook_request['hook']['name'])
  args = hook_request['hook']['args']

  payload = send(method, args.slice(0), args.slice(1))

  response = { exitStatus: 0, payload: payload }
  json_response = MultiJson.dump(response)

  # notify success or failure to the main program
  output = open("worker_to_main", "w+") # the w+ means we don't block
  output.puts json_response
  output.flush
end

def say_hello
  puts MultiJson.dump({'hello!' => 'world'})
end

# Listen to the main program signals

if Signal.list.include? 'USR1'
  trap 'USR1' do
    puts 'USR1 signal received!'
    #handle_hook_request # fails because of a deadlock risk that Ruby 2.0 prevents
    # /home/gonzalo/.rvm/rubies/ruby-2.2.0/lib/ruby/2.2.0/monitor.rb:185:in
    # `lock': can't be called from trap context (ThreadError)
    #
    # See also: http://ruby-doc.org/core-2.2.0/Mutex.html#method-i-lock
    # and https://github.com/eventmachine/eventmachine/issues/418#issuecomment-72972381
    # and https://bugs.ruby-lang.org/issues/6416
  end
end

# Start the main program.
#
# Contrary to the worker, which should not block the worker provider,
# there is nothing more to do for the worker provider before
# the main program exits. It will then wait for it.

worker_pid = Process.pid
command = "ruby main.rb #{worker_pid}"
# running ruby from system can look silly,
# but the main program could not be a Ruby program.
exit_status = system(command)

puts exit_status
puts "\nMain program #{exit_status ? 'exited successfully.' : 'failed.'}"

# Both the main program and the worker exited, it's save to exit.

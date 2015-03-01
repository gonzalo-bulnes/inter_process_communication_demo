require 'multi_json'

puts 'Main program.'

def main_to_worker
  ARGV[0]
end

def worker_to_main
  ARGV[1]
end

puts "There is an available worker reading at #{main_to_worker} and writing at #{worker_to_main}."

def delegate_hook_to_worker
  message = [
              "I'm peeping at you!",
              {
                subject: 'Guess what...',
                to: 'Bob',
                from: 'Eve',
                cc: 'Alice',
              }
            ]

  json_message = MultiJson.dump(message)
  puts "\nHere is a message to be sent:\n" + json_message + "\n"


  puts "\nLet's delegate the message formatting to the `formatMessage` hook..."

  hook_request = { hook: {
                     name: 'formatMessage',
                     args: message
                   }
                 }
  json_hook_request = MultiJson.dump(hook_request)


  # connect to the main_to_worker named pipe
  output = open(main_to_worker, "w+") # the w+ means we don't block
  # write to the named pipe
  output.puts json_hook_request
  output.flush

  # ... the worker should be processing the hook

  # read from the worker_to_main named pipe
  input = open(worker_to_main, "r+") # the r+ means we don't block

  # if the pipe is empty, `input.gets` will block,
  # that's to say will wait for the hook to send a response
  json_hook_response = input.gets
  hook_response = MultiJson.load(json_hook_response)

  if hook_response['exitStatus'].to_i == 0
    puts 'Hook exited successfully!'
    puts hook_response['payload']
  else
    puts 'Hook failed.'
  end
end

2.times do
  delegate_hook_to_worker
end

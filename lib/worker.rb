require 'active_support'
require 'multi_json'

puts 'Worker program.'

def format_message(body, options={})
  formatted_message = "\n"
  options.each do |key, value|
    formatted_message += key.capitalize + ': ' + value + "\n" unless value.empty?
  end
  formatted_message += "----\n" + body
end

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

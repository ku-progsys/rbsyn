require 'bundler/setup'

def clean_output(content)
  lines = content.lines

  # Find the index after the 'Synthetic' line
  start_index = nil
  lines.each_with_index do |line, i|
    next_line = lines[i + 1]
    if line.strip.empty? && next_line&.strip == 'Synthetic'
      start_index = i + 2  # Start after the 'Synthetic' line
      break
    end
  end

  # Return empty string if pattern not found
  return '' unless start_index

  # Extract lines after 'Synthetic'
  result_lines = lines[start_index..-1]

  if result_lines.length >= 4
    result_lines = result_lines[0..-5]
  else
    result_lines = []
  end

  result_lines.join
end

def synthesized_code(script_path, output_path)
  # Set environment variables
  ENV['CONSOLE_LOG'] = '1'

  # Set up load paths, similar to the Rake task
  # __dir__ is the directory of the current script (/root/rbsyn/api)
  $LOAD_PATH.unshift File.expand_path("../lib", __dir__)
  $LOAD_PATH.unshift File.expand_path("../test", __dir__)
  $LOAD_PATH.unshift File.expand_path("../models", __dir__)

  # The test helper is crucial for setting up the DSL and other dependencies
  require 'test_helper'

  # Load and run the script.
  # `load` will execute the script in the current context.
  # Since `test_helper` requires `minitest/autorun`, the tests in the script
  # will be executed automatically.
  # The SynthesisStatsReporter will print the output because CONSOLE_LOG is set.

  puts "Loading and running #{script_path}..."
  puts "Running '#{script_path}'..."
  output = `ruby #{script_path}`

  output.gsub!(/\e\[([;\d]+)?m/, '')
  output = clean_output(output)

  File.write(output_path, output)
  puts "Finished running #{script_path}."

  puts "Synthesized code saved to #{output_path}."
end

if __FILE__ == $0
  if ARGV.length < 1 || ARGV.length > 2
    puts "Usage: #{$0} <path_to_script> [output_file]"
    exit 1
  end

  script_path = ARGV[0]
  output_path = ARGV[1] || './synthesized_code.rb'

  unless File.exist?(script_path)
    puts "Error: File not found - #{script_path}"
    exit 1
  end

  synthesized_code(script_path, output_path)
end
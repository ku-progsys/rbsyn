require 'bundler/setup'

def synthesized_code(rb_src)
  # Set up load paths, similar to the Rake task
  # __dir__ is the directory of the current script (/root/rbsyn/api)
  $LOAD_PATH.unshift File.expand_path("../lib", __dir__)
  $LOAD_PATH.unshift File.expand_path("../test", __dir__)
  $LOAD_PATH.unshift File.expand_path("../models", __dir__)

  b = binding
  b.eval(rb_src)
  return b.instance_eval do
    task = RbSynGlobal.syn_task.shift
    task.reset_ctx
    task.generate_program
  end
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

  puts synthesized_code(File.read(script_path))
end

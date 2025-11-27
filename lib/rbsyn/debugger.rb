require 'pry'
require 'pry-byebug'


def debug(var, *conds, message: "") 
  
  if ENV['DEBUG'] == 'PRY' || ENV['DEBUG'] == 'PRINT'
    
    if conds.all? {|m| var.include?(m)}
      puts "DEBUG # #{ENV['COUNTER']} in file: #{__FILE__}\n#{message}\n"
      ENV['COUNTER'] = (ENV['COUNTER'].to_i + 1).to_s
      puts var
      puts "-----------------------\n"
      if ENV['DEBUG'] == 'PRY'
        binding.pry
      end
    end
  end
end
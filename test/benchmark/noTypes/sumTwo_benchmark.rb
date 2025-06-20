# augmented: true
require "test_helper"
include RDL::Annotate
#require_relative "../../../lib/rbsyn/helpermodule"
#include Helpermod

describe "noTypes" do
  it "sums two numbers together" do

    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :Integer, :==, "(Integer) -> %bool"
    

    #RDL::Globals.module_eval.types[:object].each {|i| puts i}

    


    define :sumTwo, "(Integer, Integer) -> Integer", [], consts: :true do

      if ENV.key? 'SETTYPE'
        puts "nokey"
        type = ENV['SETTYPE']
      else
        puts "key"
        type = "(%dyn) -> Integer"
      end
      RDL.type :BasicObject, :+, type # providing Ruby with as little information as possible. 

      spec "Should Sum Results but will throw error" do

        setup {
          sumTwo(2, 3)
        }

        post { |result|
        
          assert {result == 5 }

        }
      end
      generate_program
    end
    
  end
end



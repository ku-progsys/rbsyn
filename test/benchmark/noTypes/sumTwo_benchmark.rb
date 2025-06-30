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
    RDL.type :BasicObject, :+, "(%dyn) -> Integer" # providing Ruby with as little information as possible, honestly I shouldn't
    # even provide it with the return type if I'm being honest. 
    

    #RDL::Globals.module_eval.types[:object].each {|i| puts i}

    
    define :sumTwo, "(Integer, Integer) -> Integer", [], consts: :true do
      

      spec "Should Sum Results but will throw error" do

        setup {
          sumTwo(2, 3)
        }

        post { |result|
        
          assert {result ==  7}

        }
      end
      generate_program
    end
    
  end
end



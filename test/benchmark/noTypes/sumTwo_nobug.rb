# augmented: true
require "test_helper"
include RDL::Annotate
#require_relative "../../../lib/rbsyn/helpermodule"
#include Helpermod

describe "noTypes" do
  it "sums two numbers together but not buggy" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :+, "(%dyn) -> Integer" # for some reason it won't work if I don't provide the output type
    # it can synthesize the solution branch but it can't find the solution when attempting to integrate them in the 
    # second step. 
    

    #RDL::Globals.module_eval.types[:object].each {|i| puts i}

    
    define :sumTwoWorking, "(Integer, Integer) -> Integer", [], consts: :true do
      

      spec "Should Sum Results but will throw error" do

        setup {
          sumTwoWorking(2, 3)
        }

        post { |result|

          assert {result ==  8}
        }
      end
      generate_program
    end
    
  end
end



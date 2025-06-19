# augmented: true
require "test_helper"
include RDL::Annotate
require_relative "../../../lib/rbsyn/helpermodule"


describe "noTypes" do
  it "sums two numbers together" do

    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :Integer, :==, "(Integer) -> %bool"
    RDL.type :BasicObject, :+,  "(%dyn) -> %dyn" # providing Ruby with as little information as possible. 
    
    define :sumTwo, "(Integer, Integer) -> Integer", [], consts: :true do

  
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



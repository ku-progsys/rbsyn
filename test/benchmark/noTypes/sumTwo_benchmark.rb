# augmented: true
require "test_helper"
include RDL::Annotate



describe "noTypes" do
  load_typedefs :stdlib

  RDL.type Integer, :+, "(Integer) -> Integer", wrap: false
  it "sum_two" do

    

    define :sumTwo, "(Integer, Integer) -> Integer", [], consts: false do

  
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



# augmented: true
require "test_helper"
include RDL::Annotate



describe "noTypes" do
  it "sums first two numbers and multiplies result by third" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :"==", '() -> %bool'
    RDL.type :Integer , :+, "(Integer) -> Integer "
    RDL.type :Integer, :*, "(Integer) -> Integer "

    
    define :sumMult, "(Integer, Integer, Integer) -> Integer", [], consts: :true do
      

      spec "spec1" do

        setup {
          sumMult(2,4,3)
        }

        post { |result|
          assert {result == 18}
        }
      end
      
      
      spec "spec2" do
      
        setup {
          sumMult(3,2,4)
        }

        post {|result|
          assert {result == 20}
        }

      end

      spec "spec3" do
      
        setup {
          sumMult(2,3,4)
        }

        post {|result|
          assert {result == 20}
        }

      end

      spec "spec4" do
      
        setup {
          sumMult(4,2,3)
        }

        post {|result|
          assert {result == 18}
        }

      end

      generate_program
    end
    
  end
end



# augmented: true
require "test_helper"
include RDL::Annotate



describe "noTypes" do
  it "sums first two numbers and multiplies result by third" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :">=", '() -> %bool'
    RDL.type :BasicObject, :"<=", '() -> %bool'
    RDL.type :Integer , :+, "(%dyn) -> %dyn "
    RDL.type :Integer, :*, "(%dyn) -> %dyn "

    
    define :sumMult, "(Integer, Integer, Integer) -> Integer", [], consts: :true, moi: [:*, :+] do
      
      
      spec "spec1" do

        setup {
          sumMult(3,4,10)
        }

        post { |result|
          assert {result == 22}
        }
      end
      
      
      spec "spec2" do
      
        setup {
          sumMult(3,4,15)
        }

        post {|result|
          assert {result == 12+15}
        }

      end

      spec "spec3" do
      
        setup {
          sumMult(5,3,18)
        }

        post {|result|
          assert {result == 5*3 + 18}
        }

      end

      spec "spec4" do
      
        setup {
          sumMult(4,3,14)
        }

        post {|result|
          assert {result == 12 + 14}
        }

      end

      generate_program
    end
    
  end
end



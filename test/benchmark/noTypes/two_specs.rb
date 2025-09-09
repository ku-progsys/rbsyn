# augmented: true
require "test_helper"
include RDL::Annotate
#require_relative "../../../lib/rbsyn/helpermodule"
#include Helpermod

describe "noTypes" do
  it "sums first two numbers and multiplies result by third" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :Integer , :+, "(Integer) -> Integer " # for some reason it won't work if I don't provide the output type
    # it can synthesize the solution branch but it can't find the solution when attempting to integrate them in the 
    # second step. 
    RDL.type :Integer, :*, "(Integer) -> Integer "

    #RDL::Globals.module_eval.types[:object].each {|i| puts i}

    
    define :sumMult, "(Integer, Integer, Integer) -> Integer", [], consts: :true do
      

      spec "Might multiply by first or third" do

        setup {
          sumMult(2, 3, 2)
        }

        post { |result|

          assert {result ==  10}
        }
      end

      spec "might be multiplying by the second or third number " do
      
        setup {
          sumMult(3,2,2)
        }

        post {|result|
          assert {result == 10}
        }

      end


      generate_program
    end
    
  end
end



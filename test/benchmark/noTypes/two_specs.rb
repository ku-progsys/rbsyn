# augmented: true
require "test_helper"
include RDL::Annotate
#require_relative "../../../lib/rbsyn/helpermodule"
#include Helpermod

class Helper 
  
  attr_accessor :l

  def initialize()
    @l = []
  end
end

describe "noTypes" do
  it "sums first two numbers and multiplies result by third" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :Integer , :+, "(Integer) -> Integer "
    RDL.type :Integer, :*, "(Integer) -> Integer "

    #RDL::Globals.module_eval.types[:object].each {|i| puts i}

    
    define :sumMult, "(Integer, Integer, Integer) -> Integer", [], consts: :true do
      

      spec "Might multiply by first or third" do

        setup {
          temp = Helper.new()
          temp.l.append(sumMult(2,4,3))
          temp.l.append(sumMult(3,2,4))
          temp.l.append(sumMult(2,3,4))
          temp.l.append(sumMult(4,2,3))
          temp
        }

        post { |h|

          assert {h.l[0] ==  18}
          assert {h.l[1] ==  20}
          assert {h.l[2] ==  20}
          assert {h.l[3] ==  18}
        }
      end
=begin
      spec "might be multiplying by the second or third number " do
      
        setup {
          sumMult(3,2,4)
        }

        post {|result|
          assert {result == 20}
        }

      end

      spec "must be multiplying by 3rd" do
      
        setup {
          sumMult(2,3,4)
        }

        post {|result|
          assert {result == 20}
        }

      end

      spec "might be multiplying by asdfasdfthe second or third number " do
      
        setup {
          sumMult(4,2,3)
        }

        post {|result|
          assert {result == 18}
        }

      end
=end

      generate_program
    end
    
  end
end



def clamp1(x, min_val, max_val)
  result = x

  if result < min_val
    result = min_val
  elsif result > max_val
    result = max_val
  end

  result
end



# augmented: true
require "test_helper"
include RDL::Annotate
#require_relative "../../../lib/rbsyn/helpermodule"
#include Helpermod

describe "noTypes" do
  it "clamp function" do


    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :Integer, :>, "(Integer) -> %bool"
    RDL.type :Integer, :==, '(Integer) -> %bool'
    RDL.type :Integer, :<, "(Integer) -> %bool"
    #RDL.type :BasicObject , :+, "(%dyn) -> %dyn "

    
    define :clamp, "(Integer, Integer, Integer) -> Integer", [], consts: :true, moi: [] do
      

      spec "Lower range const returned" do

        setup {
          clamp(2,5,8)
        }

        post { |result|

          assert {result ==  5}
        }
      end


      spec "Value Returned When Inside" do

        setup {
          clamp(7,5,8)
        }

        post { |result|

          assert {result ==  7}
        }
      end
      

      spec "Upper Range Const Returned" do

        setup {
          clamp(250,5,8)
        }

        post { |result|

          assert {result ==  8}
        }
      end







      generate_program
    end
    
  end
end



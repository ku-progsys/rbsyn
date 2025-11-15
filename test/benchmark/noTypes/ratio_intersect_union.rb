# return sublist with indices between first two occurrences of elements, if one doesn't exist return a default value. 
# 
# insert after first occurence of element
# 
# flatten list 
# 
#



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'

describe "ratio_intersect" do
  it "how much intersection" do

    ParentsHelper.init_list()
    

    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :Array
    RDL.nowrap :Float
    RDL.type_params Array, [:t], :all?
    RDL.type :BasicObject, :!, '() -> %bool' 
    # RDL.type :Array, :&, "(Array) -> Array"
    # RDL.type :Array, :|, "(Array) -> Array"
    # RDL.type :Array, :size, "() -> Integer"
    # RDL.type :Integer, :fdiv, "(Integer)-> Float"
    RDL.type :BasicObject, :&, "(%dyn) -> %dyn"
    RDL.type :BasicObject, :|, "(%dyn) -> %dyn"
    RDL.type :BasicObject, :size, "() -> %dyn"
    RDL.type :BasicObject, :fdiv, "(%dyn)-> %dyn"


    ParentsHelper.subtract()
    #binding.pry

    define :ratio_intersect, "(Array, Array) -> Float", [], consts: :true, moi: [:&, :|, :size, :fdiv] do
      

      spec "should return 9" do

        setup {
          list = [1, 2, 3, 4, 5, 6, 7]
          list2 = [5, 5, 5, 4, 7, 12, 15]
          ratio_intersect(list, list2)

        }
#1/3.0
        post { |result|
          assert {result == 1/3.0}
        }
      end

      
      spec "should return 1" do

        setup {
          list = [1,2,3,4,5,6]
          list2 = [1,2,3,4,5,6]
          ratio_intersect(list, list2)

        }
#1.0
        post { |result|
          assert {result == 1.0}
      }
      end

      spec "should return 1" do

        setup {
          list = [7,7]
          list2 = [1,2,3,4,5,6]
          ratio_intersect(list2, list)

        }

        post { |result|
          assert {result == 0.0}
        }
      end

      spec "enforcing symmetry" do

        setup {
          list = [7,7]
          list2 = [1,2,3,4,5,6]
          ratio_intersect(list, list2)

        }

        post { |result|
          assert {result == 0.0}
        }
      end


      
      generate_program
    end
    
  end
end



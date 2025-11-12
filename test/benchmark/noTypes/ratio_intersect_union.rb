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
    RDL.type :Array, :&, "(Array) -> Array"
    RDL.type :Array, :|, "(Array) -> Array"
    RDL.type :Array, :size, "() -> Integer"
    RDL.type :Integer, :fdiv, "(Integer)-> Float"


    ParentsHelper.subtract()
    #binding.pry

    define :ratio_intersect, "(Array, Array) -> Integer", [], consts: :true, moi: [] do
      

      spec "should return 9" do

        setup {
          list = [1, 2, 3, 4, 5, 6, 7]
          list2 = [5, 5, 5, 4, 7, 12, 15]
          ratio_intersect(list, list2)

        }

        post { |result|
          assert (result == (list & list2).size/(list | list2).size)
        }
      end

      
      spec "should return 1" do

        setup {
          list = [1,2,3,4,5,6]
          list2 = [1,2,3,4,5,6]
          intersect_size(list, list2)

        }

        post { |result|
          assert (result == 1)
        }
      end

      spec "should return 1" do

        setup {
          list = [7,7]
          list2 = [1,2,3,4,5,6]
          intersect_size(list2, list)

        }

        post { |result|
          assert (result == 0)
        }
      end

      spec "enforcing symmetry" do

        setup {
          list = [7,7]
          list2 = [1,2,3,4,5,6]
          intersect_size(list, list2)

        }

        post { |result|
          assert (result == 0)
        }
      end


      
      generate_program
    end
    
  end
end



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

describe "notypes" do
  it "how much intersection" do

    ParentsHelper.init_list()
    

    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :Array
    RDL.type_params Array, [:t], :all?
    RDL.nowrap :String
    RDL.type :BasicObject, :!, '() -> %bool' 
    RDL.type :Array, :&, "(Array) -> Array"
    RDL.type :Array, :|, "(Array) -> Array"
    RDL.type :Array, :size, "() -> Integer"


    ParentsHelper.subtract()
    #binding.pry

    define :intersect_size, "(Array, Array) -> Integer", [], consts: :true, moi: [] do
      

      spec "3 intersect" do

        setup {
          list = [1, 2, 3, 4, 5, 6, 7]
          list2 = [5, 5, 5, 4, 7, 12, 15]
          intersect_size(list, list2)

        }

        post { |result|
          assert {result == 3}
        }
      end

      
      spec "all intersect" do

        setup {
          list = [1,2,3,4,5,6]
          list2 = [1,2,3,4,5,6]
          intersect_size(list, list2)

        }

        post { |result|
          assert {result == 6}
        }
      end


      
      generate_program
    end
    
  end
end



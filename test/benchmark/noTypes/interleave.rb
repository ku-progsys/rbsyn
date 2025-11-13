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
  it "interleaves two lists" do

    ParentsHelper.init_list()
    

    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :Array
    RDL.type_params Array, [:t], :all?
    RDL.nowrap :String
    RDL.type :BasicObject, :!, '() -> %bool' 
    RDL.type :Array, :zip, '(Array) -> Array'
    RDL.type :Array, :flatten, '() -> Array'


    ParentsHelper.subtract()
    #binding.pry

    define :interleave, "(Array, Array) -> Array", [], consts: :true, moi: [] do
      

      spec "Interleaves the array" do

        setup {
          list = [1, 2, 3, 4, 5]
          list2 = [5, 4, 3, 2, 1]
          interleave(list, list2)

        }

        post { |result|
          assert {result == [1, 5, 2, 4, 3, 3, 4, 2, 5, 1]}
        }
      end

      


      
      generate_program
    end
    
  end
end



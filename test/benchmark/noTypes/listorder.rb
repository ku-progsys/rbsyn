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
  it "check if order of elements is correct" do

    #binding.pry

    # we will need this for building the slice Range.new(start, end, exclude_end = false)
    # and this for the indexing:  RDL.type :Array, "[]", "(Range) -> Array<T>" I don't think I should allow the polymorphism for now. 
    #RDL.type :Range, :new, '(Integer, Integer, ?Bool) -> Range<Integer>'


    ParentsHelper.init_list()

    
    RDL.nowrap :Node
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :Array
    RDL.type_params Array, [:t], :all?
    RDL.nowrap :String
    RDL.type :BasicObject, :!, '() -> %bool' 

    RDL.type :BasicObject, :find_index, "(%dyn) -> %dyn"
    RDL.type :BasicObject, :nil?, '() -> %dyn'
    RDL.type :BasicObject, :<=, "(%dyn) -> %dyn"
    


    ParentsHelper.subtract()
    #binding.pry

    define :elementorder, "(Array, Integer, Integer) -> %bool", [], consts: :true, moi: [:find_index] do
      

      spec "If first param before second param return true" do

        setup {
          list = ['6', '5', '4', '7', '2', '2', '3', '12']
          elementorder(list, '2', '3')

        }

        post { |result|
          assert {result == true}
        }
      end

      spec "If second param before first param return false" do

        setup {
          list = ['6', '5', '4', '7', '3', '12']
          elementorder(list, '3', '4')

        }

        post { |result|
          assert {result == false}
        }
      end



      
      generate_program
    end
    
  end
end



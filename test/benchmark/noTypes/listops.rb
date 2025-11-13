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
  it "sublist between elements" do

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
    RDL.type :BasicObject, :+, "(%dyn) -> Integer" 
    RDL.type :Array, :find_index, "(Integer) -> Integer or nil"
    RDL.type :Array, "[]", "(Integer, Integer) -> Array"
    RDL.type :BasicObject, :nil?, '() -> %bool'
    RDL.type :Integer, :<=, "(Integer) -> %bool"
    RDL.type :Array, "self.new", "() -> Array" # just need to be able to construct the empty list. 


    ParentsHelper.subtract()
    #binding.pry

    define :subList, "(Array, Integer, Integer, Integer) -> Array", [], consts: :true, moi: [] do
      

      spec "Should return list between a and c inclusive" do

        setup {
          list = ['6', '5', '4', '7', '2', '2', '3', '12']
          sublist(list, '2', '3')

        }

        post { |result|
          assert {result == ['2', '2', '3']}
        }
      end

      spec "If first reference is missing return empty list" do

        setup {
          list = ['6', '5', '4', '7', '3', '12']
          sublist(list, '2', '12')

        }

        post { |result|
          assert {result == []}
        }
      end


      spec "If first second reference is missing return empty list" do

        setup {
          list = ['6', '5', '4', '7', '2', '2', '12']
          sublist(list, '2', '3')

        }

        post { |result|
          assert {result == []}
        }
      end

      spec "If references are out of order return empty list" do

        setup {
          list = ['6', '5', '3', '7', '2', '2', '12']
          sublist(list, '2', '3')

        }

        post { |result|
          assert {result == []}
        }
      end


      
      generate_program
    end
    
  end
end



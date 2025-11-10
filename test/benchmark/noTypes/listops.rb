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
    RDL.nowrap :Range
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :+, "(%dyn) -> Integer" 
    RDL.type :Range, :initialize, '(Integer, Integer, %bool) -> Range'
    RDL.type :Array, "[]", "(Range) -> Array<str>"
    RDL.type :Array, :initialize, "() -> Array" # just need to be able to construct the empty list. 


    ParentsHelper.subtract()
    #binding.pry

    define :subList, "(Array<str>, str, str, str) -> str", [], consts: :true, moi: [] do
      

      spec "Should return list between a and c inclusive" do

        setup {
          list = ["a", 'b', 'c', 'd', 'e', 'f']
          sublist(list, 'a', 'c')

        }

        post { |result|
          assert (result == ['a', 'b', 'c'])
        }
      end

      spec "If first reference is missing return empty list" do

        setup {
          list = [ 'b', 'c', 'd', 'e', 'f']
          sublist(list, 'a', 'c')

        }

        post { |result|
          assert (result == [])
        }
      end


      spec "If first second reference is missing return empty list" do

        setup {
          list = ['a', 'b', 'd', 'e', 'f']
          sublist(list, 'a', 'c')

        }

        post { |result|
          assert (result == [])
        }
      end

      spec "If references are out of order return empty list" do

        setup {
          list = ['c', 'b', 'a', 'd', 'e', 'f']
          sublist(list, 'a', 'c')

        }

        post { |result|
          assert (result == [])
        }
      end


      
      generate_program
    end
    
  end
end



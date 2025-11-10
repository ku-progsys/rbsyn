# return sublist with indices between first two occurrences of elements, if one doesn't exist return a default value. 
# 
# insert after first occurence of element
# 
# flatten list 
# 
#



require_relative "../../../test/test_helper"
include RDL::Annotate
require_relative "trees"
#require type_helper 
require 'pry'
require 'pry-byebug'

describe "notypes" do
  it "sublist between elements" do

    #binding.pry

    # we will need this for building the slice Range.new(start, end, exclude_end = false)
    # and this for the indexing:  RDL.type :Array, "[]", "(Range) -> Array<T>" I don't think I should allow the polymorphism for now. 
    
    ParentsHelper.init_list()

    RDL.nowrap :Node
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :State
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :+, "(%dyn) -> Integer" 
    RDL.type :BasicObject, :id, "() -> %dyn"
    #RDL.type :TreeHelper, :test_count, "(Integer) -> None"
    RDL.type :State, :children, "() -> Integer"
    RDL.type :State, :parents, "() -> %dyn"
    RDL.type :BasicObject, :size, "() -> %dyn"

    ParentsHelper.subtract()
    #binding.pry

    define :subList, "(Array<str>, str, str) -> str", [], consts: :true, moi: [???] do
      

      spec "Should just emit the number of nodes seen so far" do

        setup {
          list = ["a", 'b', 'c', 'd', 'e', 'f']
          sublist(list, 'a', 'c')

        }

        post { |result|
          assert (result == ['a', 'b', 'c'])
        }
      end

      
      generate_program
    end
    
  end
end



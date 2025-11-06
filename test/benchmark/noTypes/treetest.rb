# augmented: true
require "test_helper"
include RDL::Annotate
require_relative "trees"
#include Helpermod
#
def stub(n)
  n.id
end

describe "treeTraverse" do
  it "returns the current node value seen. " do
    # this one presents some interesting errors, in that it will work some of the time, some of the time it will attempt something like 
    # expr == true == true
    # and some of the time it will say comparison after <=. and then fail. 
    
    ParentsHelper.init_list()
    RDL.nowrap :Node
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :+, "(%dyn) -> %dyn" 
    RDL.type :BasicObject, :id, "() -> %dyn"
    RDL.type :BasicObject, :children, "() -> %dyn"
    RDL.type :BasicObject, :size, "() -> %dyn"
    ParentsHelper.subtract()
    define :counter, "(Node) -> Integer", [], consts: :true, moi: [:id, :+, :children, :size] do
      


      spec "Another test for third child" do

        setup {
          root = lexer("./test/benchmark/noTypes/smalltree.cm")
          counter(root.children.first.children.first.children.first)

        }

        post { |result|
          assert {result ==  2}
        }
      end

      spec "returns number of children see in this set so far" do

        setup {
          root = lexer("./test/benchmark/noTypes/smalltree.cm")
          counter(root)

        }

        post { |result|
          assert {result ==  1}
        }
      end

      


      generate_program
    end
    
  end
end



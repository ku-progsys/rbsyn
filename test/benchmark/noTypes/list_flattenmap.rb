# augmented: true
require "test_helper"
include RDL::Annotate
require_relative "trees"

class TreeHelper
  
  def initialize()
    @count = 0
  end

  def test_count(count)
    if count > @count
      @count = count
    end
  end

end

def stub(n)
  n.id
end



describe "treeTraverse" do
  it "returns the current node value seen. " do

    RDL.nowrap :Node
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    RDL.type :BasicObject, :+, "(%dyn) -> %dyn" 
    RDL.type :BasicObject, :id, "() -> %dyn"
    RDL.type :BasicObject, :test_count, "(%dyn) -> %dyn"
    RDL.type :Tree

    define :counter, "(Node) -> Integer", [], consts: :true, moi: [:id] do
      

      spec "Should just emit the number of nodes seen so far" do

        setup {
          root = lexer("./test/benchmark/noTypes/smalltree.cm")
          counter(root.children.first.children.first.children.first)

        }

        post { |result|
          assert {result ==  3}
        }
      end

      spec "Should just emit the number of nodes seen so far" do

        setup {
          root = lexer("./test/benchmark/noTypes/smalltree.cm")
          counter(root.children.first)

        }

        post { |result|
          assert {result ==  1}
        }
      end

      generate_program
    end
    
  end
end



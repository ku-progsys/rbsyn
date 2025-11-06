
require_relative "../../../test/test_helper"
include RDL::Annotate
require_relative "trees"
#require type_helper 
require 'pry'
require 'pry-byebug'

describe "notypes" do
  it "get_num_connections" do

    #binding.pry

    ENV["DYNPARENTS"] = 'TRUE'
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

    define :maxEdges, "(State) -> Integer", [], consts: :true, moi: [:id, :parents, :size] do
      

      spec "Should just emit the number of nodes seen so far" do

        setup {
          root = lexer("./test/benchmark/noTypes/smalltree.cm")
          maxEdges(root.states.first)

        }

        post { |result|
          assert {result ==  8}
        }
      end

      
      generate_program
    end
    
  end
end



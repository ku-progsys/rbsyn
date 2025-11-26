
require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hamster_stub.rb"
L = Hamster::List_1
describe "Hamster" do
  it "" do

  helperList =     [
      [[], [], []],
      [[1], [1], []],
      [[1, 2], [1, 2], []],
      [[1, 2, 3], [1, 2], [3]],
      [[1, 2, 3, 4], [1, 2], [3, 4]],
      [[2, 3, 4], [2], [3, 4]],
      [[3, 4], [], [3, 4]],
      [[4], [], [4]],
    ]

    ParentsHelper.init_list()

    RDL.nowrap :"Hamster::List_1"
    RDL.nowrap :"%bool"
    RDL.type_params Hamster::List_1, [:E], :all?
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.nowrap :"Hamster::Splitter"
    RDL.nowrap :"Hamster::Left"
    RDL.nowrap :"Hamster::Right"
    RDL.nowrap :Mutex
    RDL.nowrap :Array
    RDL.type_params Array, [:A], :all?
    RDL.nowrap :Proc

    #BOOLEAN METHODS
    RDL.type :"Hamster::List_1", :eql?, "(Hamster::List_1) -> %bool"
    RDL.type :"Integer", :eql?, "(Integer) -> %bool"
    RDL.type :BasicObject, :!, '() -> %bool' 

    ## METHODS TO DECLARE AS UNKNOWNS
    RDL.type :Array, :<<, '(Hamster::List_1) -> Array', effect: [:-, :+]
    RDL.type :"Hamster::List_1", :take, "(Integer) -> Hamster::List_1"
    RDL.type :"Hamster::List_1", :drop, "(Integer) -> Hamster::List_1"

    ParentsHelper.subtract()

    #solution
    # def span(&block)
    #   return [self, EmptyList_1] unless block_given?
    #   splitter = Splitter.new(self, block)
    #   mutex = Mutex.new
    #   [Splitter::Left.new(splitter, splitter.left, mutex),
    #    Splitter::Right.new(splitter, mutex)].freeze
    # end

    lst = L[*[1,2,3,4]]
    define :span, "(Hamster::List_1, Array, Hamster::Splitter, Hamster::Left, Hamster::Right, Proc)-> Array", [], consts: :true, moi: [:take, :drop, :<<] do
      
      spec "checks that prefix and remainder is correct" do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {ret[0].eql?(L[*[1,2]])}
          assert {ret[1].eql?(L[*[3,4]])}

        }
      end

      spec "checks that it returns an array of size 2" do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {ret.size == 2}

        }
      end

      spec "checks that original_list is unafeccted " do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {lst.eql?(L[*[1,2,3,4]])}

        }
      end

      generate_program
    end
    
  end
end




require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hamster_stub.rb"

L = Hamster::List_1
S = Hamster::Splitter
Left = Hamster::Splitter::Left
Right = Hamster::Splitter::Right
EL = Hamster::EmptyList_1
M = Mutex.new
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


    RDL::Globals.types[:"L"]          = RDL::Type::NominalType.new('Hamster::List_1')
    RDL::Globals.types[:"EL"]     = RDL::Type::NominalType.new('Hamster::EmptyList_1')
    RDL::Globals.types[:"S"]        = RDL::Type::NominalType.new('Hamster::Splitter')
    RDL::Globals.types[:"Left"]  = RDL::Type::NominalType.new('Hamster::Splitter::Left')
    RDL::Globals.types[:"Right"] = RDL::Type::NominalType.new('Hamster::Splitter::Right')


    RDL.nowrap :L
    RDL.nowrap :EL
    RDL.nowrap :"%bool"
    RDL.type_params Hamster::List_1, [:E], :all?
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.nowrap :S
    RDL.nowrap :Left
    RDL.nowrap :Right
    RDL.nowrap :Mutex
    RDL.nowrap :Array
    RDL.type_params Array, [:A], :all?
    RDL.nowrap :Proc
    RDL.nowrap :Ham
    #Aliases

    #BOOLEAN METHODS
    RDL.type :"Hamster::List_1", :eql?, "(Hamster::List_1) -> %bool"
    RDL.type :"Integer", :eql?, "(Integer) -> %bool"
    RDL.type :BasicObject, :!, '() -> %bool' 

    ## METHODS TO DECLARE AS UNKNOWNS
    RDL.type :Array, :<<, '(Hamster::List_1) -> Array', effect: [:-, :+]
    RDL.type :S, :"self.new", "(L, Proc) -> S"
    RDL.type :Left, :"self.new", "(S, L, Mutex) -> L"
    RDL.type :Right, :"self.new", "(S, Mutex) -> R"
    


    ParentsHelper.subtract()

    #solution
    # def span(&block)
    #   return [self, EmptyList_1] unless block_given? #not sure how to do the RDL for Block_given? so I will probably skip this for now and only pass procs???
    #   splitter = Splitter.new(self, block)
    #   mutex = Mutex.new
    #   [Splitter::Left.new(splitter, splitter.left, mutex),
    #    Splitter::Right.new(splitter, mutex)].freeze
    # end
    # 
    # if 
    proc = Proc.new() {|item| item <= 2}
    define :span, "(L, Array, S, Left, Right, Mutex, Proc)-> Array", [], consts: :true, moi: [] do
      
      spec "splits the list correctly v1" do
        
        
        setup {
          lst = [1, 2, 3, 4]
          span(lst, [], S, L, R, Mutex.new, proc )
          
        }

        post { |ret|

          prefix = [1, 2]
          remainder = [3, 4]

          assert {ret[0].eql?(L[*prefix]) }
          assert {ret[1].eql?(L[*remainder])}

        }
      end

      

      generate_program
    end
    
  end
end



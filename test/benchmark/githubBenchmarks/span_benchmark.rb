
require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hamster_stub.rb"



module List_1


  def make_splitter(l, p)
    Hamster::Splitter.new(l, p) 
  end
  
  def make_right(s, m)
    Hamster::Splitter::Right.new(s,m)

  end

  def make_left(s, l, m)
    Hamster::Splitter::Left.new(s,l,m)
  end

end

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




    RDL.nowrap :"%bool"
    RDL.type_params Hamster::List_1, [:E], :all?
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.nowrap :Mutex
    RDL.nowrap :Array
    RDL.type_params Array, [:A], :all?
    RDL.nowrap :Proc
    RDL.nowrap :"Hamster::List_1"
    RDL.nowrap :"Hamster::Splitter"
    RDL.nowrap :"Hamster::Splitter::Right"
    RDL.nowrap :"Hamster::Splitter::Left"
    #Aliases

    #BOOLEAN METHODS
    RDL.type :"Hamster::List_1", :eql?, "(Hamster::List_1) -> %bool"
    RDL.type :"Integer", :eql?, "(Integer) -> %bool"
    RDL.type :BasicObject, :!, '() -> %bool' 
    RDL.type :Integer, :<=, "(Integer) -> %bool"

    ## METHODS TO DECLARE AS UNKNOWNS
    RDL.type :Array, :<<, '(Hamster::Splitter::Left or Hamster::Splitter::Right) -> Array', effect: [:-, :+]
    RDL.type :"Hamster::List_1", :"make_splitter", "(Hamster::List_1, Proc) -> Hamster::Splitter"
    RDL.type :"Hamster::List_1", :"make_left", "(Hamster::Splitter, Hamster::List_1, Mutex) -> Hamster::Splitter::Left"
    RDL.type :"Hamster::List_1", :"make_right", "(Hamster::Splitter, Mutex) -> Hamster::Splitter::Right"
    RDL.type :"Hamster::Splitter", :left, "() -> Hamster::List_1"

    
    # binding.pry

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
    define :span, "(Hamster::List_1, Array, Mutex, Proc)-> Array", [], consts: :true, moi: [] do
      
      spec "splits the list correctly v1" do
        
        
        setup {
          lst = [1, 2, 3, 4]
          span(lst, [], Mutex.new, proc )
          
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







require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"
H = Hamster::Hash_1

class Hamster::Hash_1
    def helper1(other)
    other.instance_variable_get(:@trie)
    end
end

module BooleanHelpers

  def and_then(other)
    self && other
  end
end

class TrueClass
  include BooleanHelpers
end

class FalseClass
  include BooleanHelpers
end

describe "Hamster" do
  it "" do

  helperList = [
      [[], [], []],
      [[1], [1], []],
      [[1, 2], [1, 2], []],
      [[1, 2, 3], [1, 2], [3]],
      [[1, 2, 3, 4], [1, 2], [3, 4]],
    ]

    ParentsHelper.init_list()
    RDL::Type::NominalType.new("Hamster::Hash_1")
    RDL.nowrap :"Hamster::Hash_1"
    RDL.type_params Hamster::Hash_1, [:A], :all?
    RDL.nowrap :"%bool"
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.nowrap :Trie

    #METHODS
    RDL.type :BasicObject, :!, '() -> %bool' 
    RDL.type :"Hamster::Hash_1", :instance_of?, "(%dyn) -> %bool"
    RDL.type :BasicObject, :equal?, "(Hamster::Hash_1) -> %bool"
    RDL.type :Trie, :eql?, "(%dyn) -> %bool"
    RDL.type :"Hamster::Hash_1", :helper1, "(%dyn) -> %dyn"
    RDL.type :"%bool", :and_then, "(%bool) -> %bool"

    #Solution
    # def eql?(other)
    #   return true if other.equal?(self)
    #   instance_of?(other.class) && @trie.eql?(other.instance_variable_get(:@trie))
    # end
    # 
    #
    ParentsHelper.subtract()

    define :eql? , "(Hamster::Hash_1, Hamster::Hash_1)-> %bool", [], consts: :true, moi: [] do
      


        spec "returns true 1" do 
            setup {
                one= H["A" => "aye", "B" => "bee", "C" => "see"]
                two = H["A" => "aye", "B" => "bee", "C" => "see"]

                eql?(one, two)

            }
            post {|ret|
                assert {ret}
            }    
        end

        spec "returns true unaffected by order" do 
            setup {
                one= H["C" => "see", "B" => "bee", "A" => "aye"]
                two = H["A" => "aye", "B" => "bee", "C" => "see"]

                eql?(one, two)

            }
            post {|ret|
                assert {ret}
            }    
        end
    
      
        spec "returns false wehn comparing with a standard hash" do

            setup {
                hash = H["A" => "aye", "B" => "bee", "C" => "see"]
                normal_hash = {"A" => "aye", "B" => "bee", "C" => "see"}
                eql?(hash, normal_hash)
            
            }

            post { |ret|

                assert {!ret}

            }
        end

        spec "returns false when compared to arbitrary objects" do

            setup {
            
                hash = H["A" => "aye", "B" => "bee", "C" => "see"]
                
                eql?(hash, Object.new)
            
            }

            post { |ret|

                assert {!ret}

            }
        end

        spec "returns false when comparing with a subclass of Hamster::Hash_1"  do

            setup {
            
                hash = H["A" => "aye", "B" => "bee", "C" => "see"]
                subclass = Class.new(Hamster::Hash_1)
                instance = subclass.new("A" => "aye", "B" => "bee", "C" => "see")
                eql?(hash, instance)
                
            }

            post { |ret|

                assert {!ret}

            }
        end



        generate_program
    end
    
  end
end



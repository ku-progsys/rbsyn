



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"


class BasicObject
  def truthy?
    !(self.nil? || self == false)
  end
end

H = Hamster::Hash_1

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
    RDL.nowrap :"Hamster::Trie"
    RDL.nowrap :"Object"
    RDL.nowrap :Proc
    RDL.nowrap :Class

    #METHODS
    RDL.type :TrueClass, :!, '() -> %bool'
    RDL.type :FalseClass, :!, '() -> %bool' 
    # RDL.type :"Hamster::Hash_1", :instance_of?, "(%dyn) -> %bool"
    # RDL.type :Object, :equal?, "(Hamster::Hash_1) -> %bool"
    #RDL.type :"Hamster::Trie", :eql?, "(Hamster::Trie) -> %bool"
    RDL.type :"BasicObject", :truthy?, "() -> %bool"
    #RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    RDL.type :"Hamster::Hash_1", :default, "() -> Proc"
    RDL.type :"Object", :class, "() -> Class"
    RDL.type :"Class", :alloc, "(Hamster::Trie, Proc) -> Hamster::Hash_1"
    RDL.type :"Class", :empty, "() -> Hamster::Hash_1"


    #Solution
# def clear
#       if arg0.default.truthy?
#         arg0.class.alloc(arg1, arg0.default)
#       else
#         arg0.class.empty
#       end
#     end
#     
#
#
    ParentsHelper.subtract()
    hash = H["A" => "aye", "B" => "bee", "C" => "see"]
    hash2 = H.new(a: 1) { 1 }
    empty = Hamster::Trie.new(0)
    define :clear , "(Hamster::Hash_1, Hamster::Trie)-> Hamster::Hash_1", [], consts: :true, moi: [] do
      


        
        spec "maintains the default proc" do 
            setup {
            
                clear(hash2, empty)

            }
            post {|ret|
                assert {ret[:q] == 1}
            }    
        end

        spec "returns an empty hash" do 
            setup {
                
                clear(hash, empty)

            }
            post {|ret|
                assert {ret.eql?(H.empty)}
            }    
        end


       



        generate_program
    end
    
  end
end



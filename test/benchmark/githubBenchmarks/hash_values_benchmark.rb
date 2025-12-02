

    



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"


# class BasicObject
#   def truthy?
#     !(self.nil? || self == false)
#   end
# end

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
    RDL.nowrap :Array
    RDL.type_params Array, [:B], :all?
    RDL.nowrap :Enumerator

    #METHODS
    RDL.type :TrueClass, :!, '() -> %bool'
    RDL.type :FalseClass, :!, '() -> %bool' 
    RDL.type :BasicObject, :!, "() -> %bool"
    # RDL.type :"Hamster::Hash_1", :instance_of?, "(%dyn) -> %bool"
    # RDL.type :Object, :equal?, "(Hamster::Hash_1) -> %bool"
    #RDL.type :"Hamster::Trie", :eql?, "(Hamster::Trie) -> %bool"
    # RDL.type :"BasicObject", :truthy?, "() -> %bool"
    # #RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    # RDL.type :"Hamster::Hash_1", :default, "() -> Proc"
    # RDL.type :"Object", :class, "() -> Class"
    # RDL.type :"Class", :alloc, "(Hamster::Trie, Proc) -> Hamster::Hash_1"
    # RDL.type :"Class", :empty, "() -> Hamster::Hash_1"
    RDL.type :"BasicObject", :"to_a", "() -> Array"
    RDL.type :"Hamster::Hash_1", :"each_value", "() -> Enumerator"
    RDL.type :"Hamster::Hash_1", :"makeNewVector", "(Array) -> Hamster::Vector"


    #Solution
    # def values
    #   Vector.new(each_value.to_a)
    # end

    ParentsHelper.subtract()
    # hash = H["A" => "aye", "B" => "bee", "C" => "see"]
    # hash2 = H.new(a: 1) { 1 }
    # empty = Hamster::Trie.new(0)
    
    define :values , "(Hamster::Hash_1) -> Hamster::Vector", [], consts: :true, moi: [] do
      
      spec "maintains the default proc" do 
          setup {

            values(H["A" => "aye", "B" => "bee", "C" => "see"])
          }
          post {|ret|
            assert {ret.instance_of?(Hamster::Vector)}
            assert {ret.to_a.sort == %w(aye bee see)}
          }    

      end

      spec "allows duplicate targets" do 
          setup {
            
            values(H[:A => 15, :B => 19, :C => 15])
          }
          post {|ret|
            assert {ret.to_a.sort == [15, 15, 19]}
          }    
      end

      generate_program
    end
    
  end
end



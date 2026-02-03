

    



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

    # MAKE DYNAMIC
    # RDL.type :"BasicObject", :"to_a", "() -> Array"
    # RDL.type :"Hamster::Hash_1", :"each_value", "() -> Enumerator"
    # RDL.type :"Hamster::Hash_1", :"makeNewVector", "(Array) -> Hamster::Vector"
    RDL.type :"DynamicType", :"to_a", "() -> %dyn"
    RDL.type :"DynamicType", :"each_value", "() -> %dyn"
    RDL.type :"DynamicType", :"makeNewVector", "(%dyn) -> %dyn"

    # SOLUTION
    # def values(arg0)
    #   arg0.makeNewVector(arg0.each_value.to_a)
    # end

    ParentsHelper.subtract()
    # hash = H["A" => "aye", "B" => "bee", "C" => "see"]
    # hash2 = H.new(a: 1) { 1 }
    # empty = Hamster::Trie.new(0)
    
    define :values , "(Hamster::Hash_1) -> Hamster::Vector", [], consts: :true, moi: [:to_a, :each_value, :makeNewVector], exclude: [[:String, :"%all"], [:Array, :"%all"]]  do
      
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



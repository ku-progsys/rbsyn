



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"
H = Hamster::Hash_1

class Hamster::Hash_1
  def helper1(t)
    self.derive_new_hash(t)
  end
end



describe "Hamster" do
  it "delete" do


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
    RDL.nowrap :Class

    #METHODS
    RDL.type :BasicObject, :!, '()-> %bool'
    RDL.type :"TrueClass", :!, '() -> %bool' 
    RDL.type :"FalseClass", :!, '() -> %bool' 
    # RDL.type :"Hamster::Hash_1", :instance_of?, "(Class) -> %bool"
    # RDL.type :Object, :equal?, "(Hamster::Hash_1) -> %bool"
    # RDL.type :"Hamster::Trie", :eql?, "(Hamster::Trie) -> %bool"
    # RDL.type :"Object", :helper1, "() -> Hamster::Trie"
    RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    #RDL.type :Object, :class, "() -> Class"
    RDL.type :"Hamster::Hash_1", :helper1, "(Hamster::Trie) -> Hamster::Hash_1"
    RDL.type :"Hamster::Trie", :delete, "(Object) -> Hamster::Trie"


    #Solution
    # def delete(key)
    #   derive_new_hash(@trie.delete(key))
    # end
    ParentsHelper.subtract()
    hash =  H["A" => "aye", "B" => "bee", "C" => "see"]
    define :delete , "(Hamster::Hash_1, Object)-> Hamster::Hash_1", [], consts: :true, moi: [] do
      


        spec "only one spec needed " do 
          setup {
           
            delete(hash, "B")

          }
          post {|ret|
            assert {H["A" => "aye", "C" => "see"].eql?(ret)} # returns pruned copy
          }    
        end

        spec "with non-existing key" do 
          setup {
            
            delete(hash, "D")

          }
          post {|ret|
            assert {hash.equal?(ret)} #returns self
          }    
        end





        generate_program
    end
    
  end
end



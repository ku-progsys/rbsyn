



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

    #MAKE DYNAMIC
    # RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    # RDL.type :"Hamster::Hash_1", :helper1, "(Hamster::Trie) -> Hamster::Hash_1"
    # RDL.type :"Hamster::Trie", :delete, "(Object) -> Hamster::Trie"
    
    RDL.type :"DynamicType", :trie, "() -> %dyn"
    RDL.type :"DynamicType", :helper1, "(%dyn) -> %dyn"
    RDL.type :"DynamicType", :delete, "(%dyn) -> %dyn"


    #Solution
    # def delete(arg0, arg1)
    #   arg0.helper1(arg0.trie.delete(arg1))
    # end
    ParentsHelper.subtract()
    hash =  H["A" => "aye", "B" => "bee", "C" => "see"]
    define :delete , "(Hamster::Hash_1, Object)-> Hamster::Hash_1", [], consts: :true, moi: [:trie, :helper1, :delete], 
    exclude: [[:"Hamster::Hash_1", :delete]]  do
      


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



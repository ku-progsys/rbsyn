# return sublist with indices between first two occurrences of elements, if one doesn't exist return a default value. 
# 
# insert after first occurence of element
# 
# flatten list 
# 
#



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hamster_set_deps.rb"


describe "Hamster" do
  it "set_delete" do

    S = Hamster::Set_1
    helperSet = S["A", "B", "C"]

    ParentsHelper.init_list()
    RDL::Type::NominalType.new(:"Hamster::Set_1")
    RDL.nowrap :"Hamster::Set_1"
    RDL.nowrap :"%bool"
    RDL.nowrap :Integer
    RDL.type_params Hamster::Set_1, [:E], :all?
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL::Type::NominalType.new(:"Hamster::Trie")
    RDL.nowrap :"Hamster::Trie"
    RDL.type :"Hamster::Set_1", :eql?, "(Hamster::Set_1) -> %bool"
    RDL.type :Integer, :eql?, "(Integer) -> %bool"
    RDL.type :BasicObject, :!, '() -> %bool' 


    ## METHODS TO DECLARE AS UNKNOWNS
    # RDL.type :"Hamster::Trie", :delete, "(String) -> Hamster::Trie"
    # RDL.type :"Hamster::Set_1", :new_trie, "(Hamster::Trie) -> Hamster::Set_1"
    # RDL.type :"Hamster::Set_1", :trie, "() -> Hamster::Trie"

    RDL.type :"DynamicType", :delete, "(%dyn) -> %dyn"
    RDL.type :"DynamicType", :new_trie, "(%dyn) -> %dyn"
    RDL.type :"DynamicType", :trie, "() -> %dyn"


    #SOLUTION
    # def delete(item)
    #   trie = @trie.delete(item)
    #   new_trie(trie)
    # end
    # which translates to 
    # arg0.new_trie(arg0.trie.delete(arg1)) depth 6

    ParentsHelper.subtract()


    helperSet = S["A", "B", "C"]
    define :delete_item, "(Hamster::Set_1, String)-> Hamster::Set_1", [], consts: :true, moi: [:delete, :new_trie, :trie], exclude: [[:String, :delete]] do
      
      

      spec "returns copy with element deleted" do

        setup {
          
          delete_item(helperSet, "B")
          
        }

        post { |ret|

          assert {ret.eql?(S["A", "C"])}

        }
      end

      spec "preserves the original" do

        setup {
          
          delete_item(helperSet, "B")
          
        }

        post { |ret|

          assert {helperSet.eql?(S["A", "B", "C"])}

        }
      end

      spec "doesn't fail when deleting non-existent" do

        setup {
          
          delete_item(helperSet, "D")
          
        }

        post { |ret|

          assert {ret.eql?(S["A", "B", "C"])}

        }
      end

      
      spec "returns cannonical empty" do

        setup {
          
          h = S["D"]
          delete_item(h, "D")
          
        }

        post { |ret|

          assert {ret.eql?(Hamster::EmptySet_1)}

        }
      end

      generate_program
    end
    
  end
end



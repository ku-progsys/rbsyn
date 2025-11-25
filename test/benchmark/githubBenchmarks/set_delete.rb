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
    RDL.nowrap :Set_1
    RDL.nowrap :"%bool"
    RDL.type_params Hamster::Set_1, [:E], :all?
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.nowrap :Trie
    RDL.type :"Set_1", :eql?, "(Hamster::List_1) -> %bool"
    RDL.type :"Integer", :==, "(Integer) -> %bool"
    RDL.type :BasicObject, :!, '() -> %bool' 


    ## METHODS TO DECLARE AS UNKNOWNS
    RDL.type :Trie, :delete, "(String) -> Trie"
    RDL.type :Set_1, :new_trie, "(Trie) -> Set_1"



    ParentsHelper.subtract()

    #solution: 
    # def split_at(arr, number)
    #  arr << take(number)
    #  arr << drop(number)
    #  arr.freeze # not sure how to implement assignment in rbsyn yet so not sure how to do freeze
    # end
    S = Hamster::Set_1
    helperSet = S["A", "B", "C"]
    define :delete, "(Set_1, String)-> Set_1", [], consts: :true, moi: [:take, :drop, :<<] do
      
      spec "preserves the original" do

        setup {
          
          delete(helperSet, "B")
          
        }

        post { |ret|

          assert {helperSet.eql?(S["A", "B", "C"])}

        }
      end

      spec "returns copy with element deleted" do

        setup {
          
          delete(helperSet, "B")
          
        }

        post { |ret|

          assert {ret.eql(S["A", "C"])}

        }
      end

      spec "doesn't fail when deleting non-existent" do

        setup {
          
          delete(helperSet, "D")
          
        }

        post { |ret|

          assert {ret.eql(S["A", "B", "C"])}

        }
      end

      
      spec "returns cannonical empty" do

        setup {
          
          h = S["D"]
          delete(h, "D")
          
        }

        post { |ret|

          assert {ret.eql?(Hamster::EmptySet_1)}

        }
      end

      generate_program
    end
    
  end
end



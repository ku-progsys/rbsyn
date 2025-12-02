



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"
H = Hamster::Hash_1

class Object
  def helper1
    instance_variable_get(:@trie) # did this because I don't want to have to augment the list of symbol constants. 
  end
end



describe "Hamster" do
  it "" do


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
    RDL.type :"TrueClass", :!, '() -> %bool' 
    RDL.type :"FalseClass", :!, '() -> %bool' 
    RDL.type :"Hamster::Hash_1", :instance_of?, "(Class) -> %bool"
    RDL.type :Object, :equal?, "(Hamster::Hash_1) -> %bool"
    RDL.type :"Hamster::Trie", :eql?, "(Hamster::Trie) -> %bool"
    RDL.type :"Object", :helper1, "() -> Hamster::Trie"
    RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    RDL.type :Object, :class, "() -> Class"


    #Solution
    # def eql?(other)
    #   return true if other.equal?(self)
    #   instance_of?(other.class) && @trie.eql?(other.instance_variable_get(:@trie))
    # end
    # 
    # if arg1.equal?(arg0)
    #   true
    # if arg0.instance_of?(arg1)
    #   if arg0.trie.eql?(arg1.helper1())
    #       true
    #   else
    #       false
    #   end
    # end
    ParentsHelper.subtract()

    define :eql? , "(Hamster::Hash_1, Object)-> %bool", [], consts: :true, moi: [] do
      


        # spec "returns true 1" do 
        #     setup {
        #         one= H["A" => "aye", "B" => "bee", "C" => "see"]
        #         two = H["A" => "aye", "B" => "bee", "C" => "see"]

        #         eql?(one, two)

        #     }
        #     post {|ret|
        #         assert {ret}
        #     }    
        # end



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

        spec "returns false when not same hash" do 
            setup {
                one= H["C" => "see", "B" => "bee", "A" => "aye"]
                two = H["A" => "aye", "J" => "eeek", "C" => "see"]

                eql?(one, two)

            }
            post {|ret|
                assert {ret == false}
            }    
        end
    
        spec "returns false when comparing with a standard hash" do

            setup {
                hash = H["A" => "aye", "B" => "bee", "C" => "see"]
                normal_hash = {"A" => "aye", "B" => "bee", "C" => "see"}
                eql?(hash, normal_hash)
            
                }

            post { |ret|

                assert {ret == false}

            }
        end
      


        # spec "returns false when compared to arbitrary objects" do

        #     setup {
            
        #         hash = H["A" => "aye", "B" => "bee", "C" => "see"]
                
        #         eql?(hash, Object.new)
            
        #     }

        #     post { |ret|

        #         assert {ret == false}

        #     }
        # end

        # spec "returns false when comparing with a subclass of Hamster::Hash_1"  do

        #     setup {
            
        #         hash = H["A" => "aye", "B" => "bee", "C" => "see"]
        #         subclass = Class.new(Hamster::Hash_1)
        #         instance = subclass.new("A" => "aye", "B" => "bee", "C" => "see")
        #         eql?(hash, instance)
                
        #     }

        #     post { |ret|

        #         assert {ret == false}

        #     }
        # end



        generate_program
    end
    
  end
end



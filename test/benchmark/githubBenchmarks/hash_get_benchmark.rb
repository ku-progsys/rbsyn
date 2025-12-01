


    



require_relative "../../../test/test_helper"
include RDL::Annotate
require 'pry'
require 'pry-byebug'
require_relative "./HamsterDeps/hash_deps"
require "bigdecimal"
H = Hamster::Hash_1



class Object
  def truthy?
    !(self.nil? || self == false)
  end
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
    RDL.nowrap :"Hamster::Trie"
    RDL.nowrap :"Object"
    RDL.nowrap :"String"
    RDL.nowrap :"Array"
    RDL.nowrap :"Proc"
    RDL.type_params Array, [:Q], :all?


    #METHODS
    RDL.type :"%bool", :!, '() -> %bool' 

    RDL.type :"Hamster::Hash_1", :trie, "() -> Hamster::Trie"
    RDL.type :"Hamster::Trie", :get, "(Object) -> Array"
    RDL.type :"Hamster::Hash_1", :default, "() -> Proc"
    RDL.type :"Proc", :"call", "(Object) -> String"
    RDL.type :"Array", :"[]", "(Integer) -> String"
    RDL.type :"Array", :truthy?, "() -> %bool"


    # def get(key)
    #   entry = @trie.get(key)
    #   if entry.truthy?
    #     entry[1]
    #   elsif @default
    #     @default.call(key)
    #   end
    # end
    # alias :[] :get
    
    
    ParentsHelper.subtract()

    define :get , "(Hamster::Hash_1, Object)-> String", [], consts: :true, moi: [] do
      

        spec "if key exists" do 
            setup {
                hash = H.new("A" => "aye") { |key| fail }
                get(hash, "A")

            }
            post {|ret|
                assert {ret == "aye"}
            }    
        end

        spec "returns default block value when doesn't exist" do 
            setup {
                hash = H.new("A" => "aye") do |key|
                                        if key == "J"
                                            "bee" 
                                        else 
                                            "FAIL"
                                        end
                                    end
                get(hash, "J")
            }
            post {|ret|
                assert {ret == "bee"}
            }    
        end
    
      
        spec "doesn't call default if key is nill, that is fine" do

                setup {
                    hash = H.new(nil => 'something') { |i| "FAILS" }.send(method, nil)
                    get(hash, nil)
                }

            post { |ret|

                assert {ret == 'something'}

            }
        end



        generate_program
    end
    
  end
end




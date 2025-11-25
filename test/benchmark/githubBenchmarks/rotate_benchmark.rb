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
require_relative "./HamsterDeps/hamster_stub.rb"
L = Hamster::List_1
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

    RDL.nowrap :"Hamster::List_1"
    RDL.nowrap :Array
    RDL.nowrap :"%bool"
    RDL.type_params Array, [:A], :all?
    RDL.type_params Hamster::List_1, [:E], :all?
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    RDL.type :Array, :size, "() -> Integer"
    RDL.type :"Hamster::List_1", :eql?, "(Hamster::List_1) -> %bool"
    RDL.type :"Integer", :==, "(Integer) -> %bool"
    RDL.type :"Integer", :>=, "(Integer) -> %bool"
    RDL.type :"Integer", :"-", "(Integer) -> Integer"
    RDL.type :"Integer", :~, "() -> Integer"
    RDL.type :BasicObject, :!, '() -> %bool' 
    RDL.type :Integer, :%, "(Integer) -> Integer"
    
  

    ## METHODS TO DECLARE AS UNKNOWNS
    #
    RDL.type :"Hamster::List_1", :take, "(Integer) -> Hamster::List_1"
    RDL.type :"Hamster::List_1", :drop, "(Integer) -> Hamster::List_1"
    RDL.type :"Hamster::List_1", :append, "(Hamster::List_1) -> Hamster::List_1"
    RDL.type :"Hamster::List_1", :empty?, "() -> %bool"
    RDL.type :"Hamster::List_1", :size, "() -> Integer"


    ParentsHelper.subtract()

    #solution original: 
    # def rotate(count = 1)
    #   raise TypeError, "expected Integer" if not count.is_a?(Integer)
    #   return self if empty? || (count % size) == 0
    #   count = (count >= 0) ? count % size : (size - (~count % size) - 1)
    #   drop(count).append(take(count))
    # end
    # 
    #solution rewritten: 
    # def rotate(list, count = 1)
    #   if list.empty? || (count % list.size) == 0
    #     return self
    #   if (count >= 0)
    #     count = count % size 
    #   else
    #     count = (size - (~count % size) - 1)
    #     
    #   drop(count).append(take(count))
    # end
    lst = L[1,2,3,4,5]
    define :rotate, "(Hamster::List_1, Integer)-> Hamster::List_1", [], consts: :true, moi: [] do
      
      spec "when passed 1 as argument rotates list by 1" do

        setup {
          
          rotate(lst, 1)
          
        }

        post { |ret|

          assert {ret.eql?(L[2,3,4,5,1])}


        }
      end

      
      spec "rotate by 3" do

        setup {
          
          rotate(lst, 3)
          
        }

        post { |ret|

          assert {ret.eql?(L[2,3,4,5,1])}

        }
      end


      spec "rotate by % 5" do

        setup {
          
          rotate(lst, 5)
          
        }

        post { |ret|

          assert {ret.eql?(L[1,2,3,4,5])}

        }
      end

      spec "rotate by % 5" do

        setup {
          
          rotate(lst, 0)
          
        }

        post { |ret|

          assert {ret.eql?(L[1,2,3,4,5])}

        }
      end

      generate_program
    end
    
  end
end



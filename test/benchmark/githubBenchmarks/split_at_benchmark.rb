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
    RDL.nowrap :"Hamster::LazyList_1"
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
    RDL.type :TrueClass, :!, '() -> %bool'
    RDL.type :FalseClass, :!, '() -> %bool' 
    RDL.nowrap :DynamicType
    RDL.nowrap :TrueClass
    RDL.nowrap :FlaseClass
    #RDL.type :Object, :freeze, '() -> self'

    ## METHODS TO DECLARE AS UNKNOWNS
    #
    # RDL.type :"Hamster::List_1", :take, "(Integer) -> Hamster::List_1"
    # RDL.type :"Hamster::List_1", :drop, "(Integer) -> Hamster::List_1"
    # RDL.type :Array, :<<, '(Hamster::List_1) -> Array'
    
    
    # RDL.type :"Hamster::List_1", :take, "(%dyn) -> %dyn"
    # RDL.type :"Hamster::List_1", :drop, "(%dyn) -> %dyn"
    # RDL.type :Array, :<<, '(%dyn) -> %dyn'

    RDL.type :"DynamicType", :take, "(%dyn) -> %dyn"
    RDL.type :"DynamicType", :drop, "(%dyn) -> %dyn"
    RDL.type :"DynamicType", :<<, '(%dyn) -> %dyn'

    ParentsHelper.subtract()

    #solution: 
    # def split_at(arr, number)
    #  arr << take(number)
    #  arr << drop(number)
    #  arr.freeze # not sure how to implement assignment in rbsyn yet so not sure how to do freeze
    # end
    lst = L[*[1,2,3,4]]
    define :split_at, "(Array, Hamster::List_1, Integer)-> Array", [], consts: :true, moi: [:take, :drop, :<<] do
      
      spec "checks that prefix and remainder is correct" do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {ret[0].eql?(L[*[1,2]])}
          assert {ret[1].eql?(L[*[3,4]])}

        }
      end

      spec "checks that it returns an array of size 2" do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {ret.size == 2}

        }
      end

      spec "checks that original_list is unafeccted " do

        setup {
          
          split_at([], lst, 2)
          
        }

        post { |ret|

          assert {lst.eql?(L[*[1,2,3,4]])}

        }
      end

      generate_program
    end
    
  end
end



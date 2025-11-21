
# module Dry
#   module Monads
#     # @private
#     module Curry
#       # @private
#       def self.call(value)
#         func = value.is_a?(Proc) ? value : value.method(:call)
#         seq_args = func.parameters.count { |type, _| type.eql?(:req) || type.eql?(:opt) }
#         seq_args += 1 if func.parameters.any? { |type, _| type.eql?(:keyreq) }
#         if seq_args > 1
#           func.curry
#         else
#           func
#         end
#       end
#     end
#   end
# end

#taken from https://github.com/dry-rb/dry-monads/blob/main/lib/dry/monads/curry.rb
#curry exists in the RDL library, this just adds guards to make it monadic: ie always curries
#
#
# I don't think I know how to do the proc check with RDL so I will instead skip that and do the other so lets do 
# one that counts the number of arguments in a method call
# 
#
##         seq_args = func.parameters.count { |type, _| type.eql?(:req) || type.eql?(:opt) }
#         seq_args += 1 if func.parameters.any? { |type, _| type.eql?(:keyreq) }
#         
# This is kinda not gonna work without some helpers 
# I will make one that filters one way and another that filters the other way. 
# 
#


class Helper

  def initailize()
    
  end

  def filter_req(array)
    array.map {|type, _ | type.eql?(:req)}
  end

  def filter_opt(array)
    array.map {|type, _ | type.eql?(:opt)}
  end

  def filter_keywargs(array)
    array.parameters.map { |type, _| type.eql?(:keyreq) }
  end
end


def func_all_types(a, b, c = true, d = false, a1: , a2:, a3:)
  return false
end


def func_no_keywargs(a, b, c = true, d = false)
  return false
end


def func_only_keywargs(a1: , a2:, a3:)
  return false
end

# So I don't

f_all = method(:func_all_types).to_proc
f_no_key = method(:func_no_keywargs).to_proc
f_only_key = method(:func_only_keywargs).to_proc

require "test_helper"
include RDL::Annotate

describe "github_benchmarks" do
  it "count_arguments" do


    ParentsHelper.init_list()

    # RDL.nowrap :Helper
    RDL.nowrap :Array
    RDL.type_params Array, [:t], :all?
    RDL.nowrap :Proc
    RDL.nowrap :"%bool"
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :Symbol
    RDL.type :BasicObject, :!, '() -> %bool'
    #RDL.type :Proc, :curry, '() -> Proc' # not required yet
    RDL.type :Proc, :parameters, '() -> Array'
    RDL.type :Helper, "self.new", "() -> Helper"
    RDL.type :Helper, "filter_opt", "(Array) -> Array"
    RDL.type :Helper, "filter_req", "(Array) -> Array"
    RDL.type :Helper, "filter_keywargs", "(Array) -> Array"
    RDL.type :Array,  :size, "() -> Integer"
    RDL.type :Integer, :+, "(Integer) -> Integer"
    RDL.type :Integer, :>, '(Integer) -> %bool'

    ParentsHelper.subtract()


# seq_args = func.parameters.count { |type, _| type.eql?(:req) || type.eql?(:opt) }
# seq_args += 1 if func.parameters.any? { |type, _| type.eql?(:keyreq) }
    
    define :count_args, "(Helper, Proc) -> Integer", [], consts: :true, moi: [] do
      

      spec "Should return args + opts if no keywargs" do

        setup {
          h = Helper.new
          count_args(h, f_no_key)
        }

        post { |result|

          assert {result ==  4}
        }
      end



      spec "Should return 1 if only arguments that are returned are keywargs" do

        setup {
          count_args(f_only_key)
        }

        post { |result|

          assert {result ==  1}
        }
      end



      spec "Should return args + opts + 1 if there are keywargs" do

        setup {
          count_args(f_all)
        }

        post { |result|

          assert {result ==  5}
        }
      end


      
      generate_program
    end
    
  end
end


# well this one isnt working well, the problem seems to be that every argument it tries
# to build starts with arg0. Not sure why. I think that I either have an issue with the 
# type Proc, or there is an issue with me not being able to call an argument on the 
# implicit object? self doesn't seem to be working right now for that either. 
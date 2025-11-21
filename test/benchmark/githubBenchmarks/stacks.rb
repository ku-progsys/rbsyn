#Taken from https://github.com/TheAlgorithms/Ruby/blob/master/data_structures/stacks/stack.rb

# A stack is an abstract data type that serves as a collection of
# elements with two principal operations: push() and pop(). push() adds an
# element to the top of the stack, and pop() removes an element from the top
# of a stack. The order in which elements come off of a stack are
# Last In, First Out (LIFO)

class StackOverflowError < StandardError; end

class Stack
  def initialize(limit, stack = [])
    @stack = stack
    @limit = limit
  end

  attr_accessor :stack, :limit

  # def push(item)
  #   raise StackOverflowError unless stack.count < limit

  #   stack << item
  # end

  def pop
    stack.pop
  end

  def peek
    stack.last
  end

  def empty?
    stack.count.zero?
  end

  def full?
    stack.count == limit
  end

  def size
    stack.count
  end

  def contains?(item)
    stack.include?(item)
  end
end

stack = Stack.new(10, [])

puts stack.empty?
# => true

stack.push(3)
stack.push(5)
stack.push(7)
stack.push(9)

puts stack.full?
# => false

puts stack.contains?(5)
# => true

puts stack.pop
# => 9

puts stack.peek
# => 7

puts stack.size
# => 3

puts stack.inspect
# => #<Stack:0x00007fceed83eb40 @stack=[3, 5, 7], @limit=10>

stack.push(13)
stack.push(15)
stack.push(17)
stack.push(19)
stack.push(23)
stack.push(25)
stack.push(27)
# At this point, the stack is full

stack.push(29)
# => data_structures/stacks/stack.rb:18:in `push': StackOverflowError (StackOverflowError)
# from data_structures/stacks/stack.rb:83:in `<main>'
# 
#


require "test_helper"
include RDL::Annotate

describe "github_benchmarks" do
  it "count_arguments" do


    ParentsHelper.init_list()

    # RDL.nowrap :Helper
    RDL.nowrap :Stack
    RDL.type_params Array, [:t], :all?
    RDL.nowrap :Proc
    RDL.nowrap :"%bool"
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.type :BasicObject, :!, '() -> %bool'
    #RDL.type :Proc, :curry, '() -> Proc' # not required yet
    RDL.type :Proc, :parameters, '() -> Array'
    RDL.type :Stack :pop, '() -> Integer'
    RDL.type :Array,  :size, "() -> Integer"
    RDL.type :Integer, :+, "(Integer) -> Integer"
    RDL.type :Integer, :>, '(Integer) -> %bool'

    ParentsHelper.subtract()


    # seq_args = func.parameters.count { |type, _| type.eql?(:req) || type.eql?(:opt) }
    # seq_args += 1 if func.parameters.any? { |type, _| type.eql?(:keyreq) }
    
    define :count_args, "(Proc) -> Integer", [], consts: :true, moi: [] do

      spec "Should return args + opts if no keywargs" do

        setup {
          count_args(f_no_key)
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
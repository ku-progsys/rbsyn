
require "test_helper"
 
describe "Integer Benchmarks" do
  it "synthesize max_of_two" do
    load_typedefs :stdlib
    src = File.join(__dir__, "max_sketch.rb")
    sketch src, :max_of_two, "(Integer, Integer) -> Integer", [], consts: true do
      spec "left_bigger" do
        setup { max_of_two 7, 3 }
        post { |r| assert { r == 7 } }
      end
      spec "right_bigger" do
        setup { max_of_two 2, 9 }
        post { |r| assert { r == 9 } }
      end
      spec "equal" do
        setup { max_of_two 5, 5 }
        post { |r| assert { r == 5 } }
      end
      generate_program
    end
  end
 
end
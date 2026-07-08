require "test_helper"
 
describe "Integer Benchmarks" do
  src = File.join(__dir__, "abs_value_sketch.rb")
  sketch src, :absolute_value, "(Integer) -> Integer", [], consts: true do
    spec "pos" do
      setup { absolute_value 4 }
      post { |r| assert { r == 4 } }
    end
    spec "neg" do
      setup { absolute_value(-3) }
      post { |r| assert { r == 3 } }
    end
    spec "zero" do
      setup { absolute_value 0 }
      post { |r| assert { r == 0 } }
    end
    generate_program
  end
end

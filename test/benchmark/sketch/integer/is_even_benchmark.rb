require "test_helper"
 
describe "Integer Benchmarks" do
  it "synthesize is_even" do
    load_typedefs :stdlib
    src = File.join(__dir__, "is_even_sketch.rb")
    sketch src, :is_even, "(Integer) -> Boolean", [], consts: true do
      spec "even" do
        setup { is_even 4 }
        post { |r| assert { r == true } }
      end
      spec "odd" do
        setup { is_even 3 }
        post { |r| assert { r == false } }
      end
      spec "zero" do
        setup { is_even 0 }
        post { |r| assert { r == true } }
      end
      generate_program
    end
  end
end
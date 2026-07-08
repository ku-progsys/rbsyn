require "test_helper"
 
describe "Integer Benchmarks" do
  it "synthesize square" do
    load_typedefs :stdlib
    src = File.join(__dir__, "square_sketch.rb")
    sketch src, :square, "(Integer) -> Integer", [], consts: true do
      spec "0" do
        setup { square 0 }
        post { |r| assert { r == 0 } }
      end
      spec "3" do
        setup { square 3 }
        post { |r| assert { r == 9 } }
      end
      spec "5" do
        setup { square 5 }
        post { |r| assert { r == 25 } }
      end
      generate_program
    end
  end
end
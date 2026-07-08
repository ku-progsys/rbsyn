require "test_helper"
 
describe "Integer Benchmarks" do
  it "synthesize double" do
    load_typedefs :stdlib
    src = File.join(__dir__, "double_sketch.rb")
    sketch src, :double, "(Integer) -> Integer", [], consts: true do
      spec "0" do
        setup { double 0 }
        post { |r| assert { r == 0 } }
      end
      spec "3" do
        setup { double 3 }
        post { |r| assert { r == 6 } }
      end
      spec "7" do
        setup { double 7 }
        post { |r| assert { r == 14 } }
      end
      generate_program
    end
  end
end
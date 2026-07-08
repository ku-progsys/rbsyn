require "test_helper"
 
describe "Integer Benchmarks" do
  it "synthesize clamp" do
    load_typedefs :stdlib
    src = File.join(__dir__, "clamp_sketch.rb")
    sketch src, :clamp, "(Integer) -> Integer", [], consts: true do
      spec "below" do
        setup { clamp(-5) }
        post { |r| assert { r == 0 } }
      end
      spec "above" do
        setup { clamp 15 }
        post { |r| assert { r == 10 } }
      end
      spec "in_range" do
        setup { clamp 7 }
        post { |r| assert { r == 7 } }
      end
      generate_program
    end
  end
end
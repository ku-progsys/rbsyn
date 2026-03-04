require "test_helper"

describe "Integer Sketch 1 Benchmark" do
  it "synthesize in_1 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_1_sketch.rb")

    sketch src, :in_1, "(Integer) -> Integer", [], consts: true do

      spec "5" do
        setup {
          in_1 5
        }

        post { |result|
          assert { result == 12 }
        }
      end

      spec "3" do
        setup {
          in_1 3
        }

        post { |result|
          assert { result == 8 }
        }
      end

      generate_program
    end
  end
end

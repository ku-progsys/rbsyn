require "test_helper"

describe "Integer Sketch 8 Benchmark" do
  it "synthesize in_8 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_8_sketch.rb")

    sketch src, :in_8, "(Integer, Integer) -> Integer", [], consts: true do

      spec "2 3" do
        setup {
          in_8 2, 3
        }

        post { |result|
          assert { result == 11 }
        }
      end

      spec "1 5" do
        setup {
          in_8 1, 5
        }

        post { |result|
          assert { result == 11 }
        }
      end

      generate_program
    end
  end
end

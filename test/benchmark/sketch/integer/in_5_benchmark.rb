require "test_helper"

describe "Integer Sketch 5 Benchmark" do
  it "synthesize in_5 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_5_sketch.rb")

    sketch src, :in_5, "(Integer, Integer, Integer) -> Integer", [], consts: true do

      spec "1 2 3" do
        setup {
          in_5 1, 2, 3
        }

        post { |result|
          assert { result == 14 }
        }
      end

      spec "2 1 2" do
        setup {
          in_5 2, 1, 2
        }

        post { |result|
          assert { result == 16 }
        }
      end

      generate_program
    end
  end
end

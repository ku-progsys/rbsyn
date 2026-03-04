require "test_helper"

describe "Integer Sketch 3 Benchmark" do
  it "synthesize in_3 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_3_sketch.rb")

    sketch src, :in_3, "(Integer, Integer) -> Integer", [], consts: true do

      spec "2 3" do
        setup {
          in_3 2, 3
        }

        post { |result|
          assert { result == 10 }
        }
      end

      spec "1 4" do
        setup {
          in_3 1, 4
        }

        post { |result|
          assert { result == 10 }
        }
      end

      generate_program
    end
  end
end

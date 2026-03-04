require "test_helper"

describe "Integer Sketch 10 Benchmark" do
  it "synthesize in_10 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_10_sketch.rb")

    sketch src, :in_10, "(Integer, Integer) -> Integer", [], consts: true do

      spec "3 2" do
        setup {
          in_10 3, 2
        }

        post { |result|
          assert { result == 13 }
        }
      end

      spec "2 4" do
        setup {
          in_10 2, 4
        }

        post { |result|
          assert { result == 12 }
        }
      end

      generate_program
    end
  end
end

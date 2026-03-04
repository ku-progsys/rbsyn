require "test_helper"

describe "Integer Sketch 2 Benchmark" do
  it "synthesize in_2 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_2_sketch.rb")

    sketch src, :in_2, "(Integer) -> Integer", [], consts: true do

      spec "4" do
        setup {
          in_2 4
        }

        post { |result|
          assert { result == 6 }
        }
      end

      spec "2" do
        setup {
          in_2 2
        }

        post { |result|
          assert { result == 1 }
        }
      end

      generate_program
    end
  end
end

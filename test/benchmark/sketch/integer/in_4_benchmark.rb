require "test_helper"

describe "Integer Sketch 4 Benchmark" do
  it "synthesize in_4 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_4_sketch.rb")

    sketch src, :in_4, "(Integer) -> Integer", [], consts: true do

      spec "3" do
        setup {
          in_4 3
        }

        post { |result|
          assert { result == 13 }
        }
      end

      spec "5" do
        setup {
          in_4 5
        }

        post { |result|
          assert { result == 23 }
        }
      end

      generate_program
    end
  end
end

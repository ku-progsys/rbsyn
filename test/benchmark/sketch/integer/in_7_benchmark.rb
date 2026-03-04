require "test_helper"

describe "Integer Sketch 7 Benchmark" do
  it "synthesize in_7 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_7_sketch.rb")

    sketch src, :in_7, "(Integer) -> Integer", [], consts: true do

      spec "2" do
        setup {
          in_7 2
        }

        post { |result|
          assert { result == 13 }
        }
      end

      spec "3" do
        setup {
          in_7 3
        }

        post { |result|
          assert { result == 19 }
        }
      end

      generate_program
    end
  end
end

require "test_helper"

describe "Integer Sketch 6 Benchmark" do
  it "synthesize in_6 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_6_sketch.rb")

    sketch src, :in_6, "(Integer) -> Integer", [], consts: true do

      spec "4" do
        setup {
          in_6 4
        }

        post { |result|
          assert { result == 13 }
        }
      end

      spec "2" do
        setup {
          in_6 2
        }

        post { |result|
          assert { result == 7 }
        }
      end

      generate_program
    end
  end
end

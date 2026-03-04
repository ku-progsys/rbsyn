require "test_helper"

describe "Integer Sketch 9 Benchmark" do
  it "synthesize in_9 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "in_9_sketch.rb")

    sketch src, :in_9, "(Integer) -> Integer", [], consts: true do

      spec "2" do
        setup {
          in_9 2
        }

        post { |result|
          assert { result == 18 }
        }
      end

      spec "3" do
        setup {
          in_9 3
        }

        post { |result|
          assert { result == 28 }
        }
      end

      generate_program
    end
  end
end

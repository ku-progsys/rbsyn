require "test_helper"

describe "String Sketch 5 Benchmark" do
  it "synthesize string_5 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_5_sketch.rb")

    sketch src, :string_5, "(String, Integer) -> String", [], consts: true do

      spec "ab" do
        setup {
          string_5 "ab", 3
        }

        post { |result|
          assert { result == "ababab" }
        }
      end

      spec "x" do
        setup {
          string_5 "x", 4
        }

        post { |result|
          assert { result == "xxxx" }
        }
      end

      generate_program
    end
  end
end

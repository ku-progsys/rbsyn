require "test_helper"

describe "String Sketch 10 Benchmark" do
  it "synthesize string_10 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_10_sketch.rb")

    sketch src, :string_10, "(String) -> String", [], consts: true do

      spec "middle" do
        setup {
          string_10 "middle"
        }

        post { |result|
          assert { result == "[middle]" }
        }
      end

      spec "text" do
        setup {
          string_10 "text"
        }

        post { |result|
          assert { result == "[text]" }
        }
      end

      generate_program
    end
  end
end

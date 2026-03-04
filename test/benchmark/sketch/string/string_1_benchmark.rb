require "test_helper"

describe "String Sketch 1 Benchmark" do
  it "synthesize string_1 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_1_sketch.rb")

    sketch src, :string_1, "(String) -> String", [], consts: true do

      spec "hello" do
        setup {
          string_1 "hello"
        }

        post { |result|
          assert { result == "hello!" }
        }
      end

      spec "world" do
        setup {
          string_1 "world"
        }

        post { |result|
          assert { result == "world!" }
        }
      end

      generate_program
    end
  end
end

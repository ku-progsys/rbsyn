require "test_helper"

describe "String Sketch 8 Benchmark" do
  it "synthesize string_8 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_8_sketch.rb")

    sketch src, :string_8, "(String) -> Integer", [], consts: true do

      spec "ab" do
        setup {
          string_8 "ab"
        }

        post { |result|
          assert { result == 5 }
        }
      end

      spec "hello" do
        setup {
          string_8 "hello"
        }

        post { |result|
          assert { result == 8 }
        }
      end

      generate_program
    end
  end
end

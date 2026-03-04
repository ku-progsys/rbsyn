require "test_helper"

describe "String Sketch 2 Benchmark" do
  it "synthesize string_2 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_2_sketch.rb")

    sketch src, :string_2, "(String) -> Integer", [], consts: true do

      spec "abc" do
        setup {
          string_2 "abc"
        }

        post { |result|
          assert { result == 5 }
        }
      end

      spec "hello" do
        setup {
          string_2 "hello"
        }

        post { |result|
          assert { result == 7 }
        }
      end

      generate_program
    end
  end
end

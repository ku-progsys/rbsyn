require "test_helper"

describe "String Sketch 7 Benchmark" do
  it "synthesize string_7 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_7_sketch.rb")

    sketch src, :string_7, "(String, String, String) -> String", [], consts: true do

      spec "a b c" do
        setup {
          string_7 "a", "b", "c"
        }

        post { |result|
          assert { result == "a,b,c" }
        }
      end

      spec "x y z" do
        setup {
          string_7 "x", "y", "z"
        }

        post { |result|
          assert { result == "x,y,z" }
        }
      end

      generate_program
    end
  end
end

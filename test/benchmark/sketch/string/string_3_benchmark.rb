require "test_helper"

describe "String Sketch 3 Benchmark" do
  it "synthesize string_3 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_3_sketch.rb")

    sketch src, :string_3, "(String, String) -> String", [], consts: true do

      spec "hello and world" do
        setup {
          string_3 "hello", "world"
        }

        post { |result|
          assert { result == "hello-world" }
        }
      end

      spec "foo and bar" do
        setup {
          string_3 "foo", "bar"
        }

        post { |result|
          assert { result == "foo-bar" }
        }
      end

      generate_program
    end
  end
end

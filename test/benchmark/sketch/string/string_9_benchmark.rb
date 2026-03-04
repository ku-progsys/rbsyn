require "test_helper"

describe "String Sketch 9 Benchmark" do
  it "synthesize string_9 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_9_sketch.rb")

    sketch src, :string_9, "(String, Integer) -> String", [], consts: true do

      spec "ok" do
        setup {
          string_9 "ok", 2
        }

        post { |result|
          assert { result == "okoo" }
        }
      end

      spec "a" do
        setup {
          string_9 "a", 3
        }

        post { |result|
          assert { result == "aaaa" }
        }
      end

      generate_program
    end
  end
end

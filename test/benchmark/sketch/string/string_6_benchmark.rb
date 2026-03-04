require "test_helper"

describe "String Sketch 6 Benchmark" do
  it "synthesize string_6 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_6_sketch.rb")

    sketch src, :string_6, "(String) -> String", [], consts: true do

      spec "test" do
        setup {
          string_6 "test"
        }

        post { |result|
          assert { result == "pretest_post" }
        }
      end

      spec "data" do
        setup {
          string_6 "data"
        }

        post { |result|
          assert { result == "predata_post" }
        }
      end

      generate_program
    end
  end
end

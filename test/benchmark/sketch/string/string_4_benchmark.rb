require "test_helper"

describe "String Sketch 4 Benchmark" do
  it "synthesize string_4 function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_4_sketch.rb")

    sketch src, :string_4, "(String) -> String", [], consts: true do

      spec "world" do
        setup {
          string_4 "world"
        }

        post { |result|
          assert { result == "helloworld" }
        }
      end

      spec "ruby" do
        setup {
          string_4 "ruby"
        }

        post { |result|
          assert { result == "helloruby" }
        }
      end

      generate_program
    end
  end
end

require "test_helper"

describe "Sketch Basic Benchmark" do
  it "synthesize add_one function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "sketch_basic.rb")

    sketch src, :add_one, "(Integer) -> Integer", [], consts: true do

      spec "6" do
        setup {
          add_one 6
        }

        post { |result|
          assert { result == 13 }
        }
      end

      spec "5" do
        setup {
          add_one 5
        }

        post { |result|
          assert { result == 11 }
        }
      end

      generate_program
    end
  end
end

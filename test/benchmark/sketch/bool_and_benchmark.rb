require "test_helper"

describe "Bool And Sketch Benchmark" do
  it "synthesize both_true function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "bool_and_sketch.rb")

    sketch src, :both_true, "(Bool, Bool) -> Bool", [], consts: true do

      spec "true && true" do
        setup {
          both_true true, true
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "true && false" do
        setup {
          both_true true, false
        }

        post { |result|
          assert { result == false }
        }
      end

      generate_program
    end
  end
end

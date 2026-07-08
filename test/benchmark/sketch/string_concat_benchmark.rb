require "test_helper"

describe "String Concat Sketch Benchmark" do
  it "synthesize greet function" do
    load_typedefs :stdlib

    src = File.join(__dir__, "string_concat_sketch.rb")

    sketch src, :greet, "(String) -> String", [], consts: true do

      spec '"World"' do
        setup { greet "World" }
        post { |result| assert { result == "Hello, World" } }
      end

      spec '"RBSyn"' do
        setup { greet "RBSyn" }
        post { |result| assert { result == "Hello, RBSyn" } }
      end

      generate_program
    end
  end
end

require_relative "../../../test_helper"
include RDL::Annotate
require_relative "../colorDepenencies/color"
require 'pry'
require 'pry-byebug'



describe "ChunkyPNG::Color" do
  it "should calculate a pass size correctly and return 0 if one of the dimensions is zero" do 
    ParentsHelper.init_list()

    RDL.nowrap :Integer
    RDL.nowrap :String
    RDL.nowrap :Regexp
    RDL.nowrap :DynamicType

    RDL.nowrap :Symbol
    RDL.nowrap :Object
    RDL.nowrap :"ChunkyPNG::Color"


    RDL.type :Object, :is_a?, "(Class) -> %bool"
    RDL.type :Object, :to_s, "() -> String"
    RDL.type :Object, :to_i, "() -> Integer"
    
    RDL.type :"ChunkyPNG::Color", :scanline_bytesize, "(Integer, Integer, Integer) -> Integer"
    RDL.type :"Integer", :*, "(Integer) -> Integer"
    RDL.type :"Integer", :+, "(Integer) -> Integer"
    RDL.type :"Integer", :==, "(Integer) -> %bool"
  


    ParentsHelper.subtract()
    CHC = ChunkyPNG::Color
    define :pass_bytesize , "(ChunkyPNG::Color, Integer, Integer, Integer, Integer) -> Integer", [], consts: :true, moi: [] do
      
      spec "should calculate a pass size correctly" do
        setup {
          pass_bytesize(CHC, ChunkyPNG::COLOR_TRUECOLOR, 8, 10, 10)
        }
        post {|ret|

          assert {ret == 310}
        }
      end

      spec "should return 0 if one of the dimensions is zero 1" do
        setup {
          pass_bytesize(CHC, ChunkyPNG::COLOR_TRUECOLOR, 8, 0, 10)
        }
        post {|ret|
          assert {ret == 0}
        }
      end

      spec "should return 0 if one of the dimensions is zero 2" do
        setup {
          pass_bytesize(CHC, ChunkyPNG::COLOR_TRUECOLOR, 8, 10, 0)
        }
        post {|ret|
          assert {ret == 0}
        }
      end

      generate_program
    end
  end
end
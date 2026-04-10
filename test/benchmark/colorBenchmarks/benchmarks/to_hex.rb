# ORIGINAL SPEC
# describe "#to_hex" do
#   it "should represent colors correctly using hex notation" do
#     expect(to_hex(@white)).to eql "#ffffffff"
#     expect(to_hex(@black)).to eql "#000000ff"
#     expect(to_hex(@opaque)).to eql "#0a6496ff"
#     expect(to_hex(@non_opaque)).to eql "#0a649664"
#     expect(to_hex(@fully_transparent)).to eql "#0a649600"
#   end
#
#   it "should represent colors correctly using hex notation without alpha channel" do
#     expect(to_hex(@white, false)).to eql "#ffffff"
#     expect(to_hex(@black, false)).to eql "#000000"
#     expect(to_hex(@opaque, false)).to eql "#0a6496"
#     expect(to_hex(@non_opaque, false)).to eql "#0a6496"
#     expect(to_hex(@fully_transparent, false)).to eql "#0a6496"
#   end
# end
# 
#
#SOLUTION OF COLOR
# def to_hex(color, include_alpha = true)
#   include_alpha ? ("#%08x" % color) : ("#%06x" % [color >> 8])
# end


require_relative "../../../test_helper"
include RDL::Annotate
require_relative "../chunkyPNGdeps/lib/chunky_png/color.rb"
require 'pry'
require 'pry-byebug'


module ChunkyPNG::Color
  
  def wrap_to_s(k)
    # just forces the thing to be evaluated prior to the to_s is called. 
    String(k)
  end
  public :wrap_to_s

end


describe "ChunkyPNG::Color" do

    @white             = 0xffffffff
    @black             = 0x000000ff
    @opaque            = 0x0a6496ff
    @non_opaque        = 0x0a649664
    @fully_transparent = 0x0a649600

  it "should represent colors correctly using hex notation" do
    ParentsHelper.init_list()

    RDL.nowrap :Integer
    RDL.nowrap :String
    RDL.nowrap :Regexp
    RDL.nowrap :Symbol
    RDL.nowrap :Object
    RDL.nowrap :"ChunkyPNG::Color"
    RDL.type :Integer, :>>, "(Integer) -> Integer"
    RDL.type :String, :%, "(String) -> String"
    RDL.type :String, :%, "(Integer) -> String"
    RDL.type :FalseClass, :"!", "() -> %bool"
    #RDL.type :TrueClass, :"!", "() -> FalseClass"
    #RDL.type :"ChunkyPNG::Color", :wrap_to_s, "(Object) -> String"

    ParentsHelper.subtract()
    CHC = ChunkyPNG::Color
    define :to_hex, "(ChunkyPNG::Color, Integer, %bool) -> String", ["#%08x", "#%06x", 8], consts: false, moi: [] do

      # spec "should represent white with alpha" do
      #   setup {
      #     to_hex(CHC, 0xffffffff, true)
      #   }
      #   post {|ret|
      #     assert {ret == "#ffffffff"}
      #   }
      # end

      # spec "should represent black with alpha" do
      #   setup {
      #     to_hex(CHC, 0x000000ff, true)
      #   }
      #   post {|ret|
      #     assert {ret == "#000000ff"}
      #   }
      # end

      # spec "should represent an opaque color with alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a6496ff, true)
      #   }
      #   post {|ret|
      #     assert {ret == "#0a6496ff"}
      #   }
      # end

      # spec "should represent a non-opaque color with alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a649664, true)
      #   }
      #   post {|ret|
      #     assert {ret == "#0a649664"}
      #   }
      # end

      # spec "should represent a fully-transparent color with alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a649600, true)
      #   }
      #   post {|ret|
      #     assert {ret == "#0a649600"}
      #   }
      # end

      spec "should represent white without alpha" do
        setup {
          to_hex(CHC, 0xffffffff, false)
        }
        post {|ret|
          assert {ret == "#ffffff"}
        }
      end

      # spec "should represent black without alpha" do
      #   setup {
      #     to_hex(CHC, 0x000000ff, false)
      #   }
      #   post {|ret|
      #     assert {ret == "#000000"}
      #   }
      # end

      # spec "should represent an opaque color without alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a6496ff, false)
      #   }
      #   post {|ret|
      #     assert {ret == "#0a6496"}
      #   }
      # end

      # spec "should represent a non-opaque color without alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a649664, false)
      #   }
      #   post {|ret|
      #     assert {ret == "#0a6496"}
      #   }
      # end

      # spec "should represent a non-opaque color with alpha" do
      #   setup {
      #     to_hex(CHC, 0x0a649600, false)
      #   }
      #   post {|ret|
      #     assert {ret ==  "#0a6496"}
      #   }
      # end

      generate_program
    end
  end
end

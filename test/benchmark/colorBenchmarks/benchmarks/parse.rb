  
  # ORIGINAL SPEC
  # describe "#parse" do
  #   it "should interpret a hex string correctly" do
  #     expect(parse("0x0a649664")).to eql ChunkyPNG::Color.from_hex("#0a649664")
  #   end

  #   it "should interpret a color name correctly" do
  #     expect(parse(:spring_green)).to eql 0x00ff7fff
  #     expect(parse("spring green")).to eql 0x00ff7fff
  #     expect(parse("spring green @ 0.6666")).to eql 0x00ff7faa
  #   end

  #   it "should return numbers as is" do
  #     expect(parse("12345")).to eql 12345
  #     expect(parse(12345)).to eql 12345
  #   end
  # end

  
require_relative "../../../test_helper"
include RDL::Annotate
require_relative "../colorDepenencies/color"
require 'pry'
require 'pry-byebug'



#small helper methods
def is_str?(arg0)
  arg0.is_a? String
end

def is_int?(arg0)
  arg0.is_a? Integer
end

def is_regex?(arg0)
  arg0.is_a? Regexp
end

describe "ChunkyPNG::Color" do
  it "Parses colors correctly" do 
    ParentsHelper.init_list()

    RDL.nowrap :Integer
    RDL.nowrap :String
    RDL.nowrap :Regexp
    RDL.nowrap :DynamicType

    RDL.nowrap :Symbol
    RDL.nowrap :Object
    RDL.nowrap :"ChunkyPNG::Color"

    # RDL.type :Object, :is_str?, "(Class) -> %bool"
    # RDL.type :Object, :is_int?, "(Class) -> %bool"
    # RDL.type :Object, :is_regex?, "(Class) -> %bool"
    RDL.type :Object, :is_a?, "(Class) -> %bool"
    RDL.type :Object, :to_s, "() -> String"
    RDL.type :Object, :to_i, "() -> Integer"
    

    # RDL.type :"ChunkyPNG::Color", :HEX3_COLOR_REGEXP, "() -> Regexp"
    # RDL.type :"ChunkyPNG::Color", :HEX6_COLOR_REGEXP, "() -> Regexp"
    # RDL.type :"ChunkyPNG::Color", :HTML_COLOR_REGEXP, "() -> Regexp"
    RDL.type :"ChunkyPNG::Color", :DIGITS, "() -> Regexp"
    RDL.type :"ChunkyPNG::Color", :html_color, "(String) -> Integer"
    RDL.type :"from_hex", "(String) -> Integer"

    ParentsHelper.subtract()

    define :parse , "(String or Integer or Symbol)-> Integer", [ChunkyPNG::Color::HEX3_COLOR_REGEXP, ChunkyPNG::Color::HEX6_COLOR_REGEXP, ChunkyPNG::Color::HTML_COLOR_REGEXP, 2.class], consts: :true, moi: [] do
      
      spec  "should interpret a hex string correctly" do
        setup {

          parse("")
        }
        post {|ret|
          assert {ret == ChunkyPNG::Color.from_hex("#0a649664")}
        }
      end

      spec  "should interpret a color name correctly 1" do
        setup {
          parse(:spring_green)}
        post {|ret|
          assert {ret == 0x00ff7fff}
        }
      end

      spec "should interpret a color name correctly 2" do
        setup { parse("spring green") }
        
        post {|ret|
          assert {ret == 0x00ff7fff}
        }
      end

      spec "should interpret a color name correctly 3" do
        setup { parse("spring green @ 0.6666") }
        post {|ret|
          assert {ret == 0x00ff7faa}
        }
      end                                           

      spec "should return numbers as is 1" do
        setup {parse("12345")} 
        post {|ret|
          assert {ret ==12345}
        }
      end

      spec "should return numbers as is 2" do
        setup { parse(12345) }
        post {|ret|
          assert {ret == 12345}
        }
      end
      generate_program
    end
  end
end
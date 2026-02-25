  
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
    RDL.type :Regexp, :match?, "(String) -> %bool"
    


    RDL.type :"ChunkyPNG::Color", :html_color, "(String) -> Integer"
    RDL.type :"ChunkyPNG::Color", :"from_hex", "(String) -> Integer"

    ParentsHelper.subtract()
    CHC = ChunkyPNG::Color
    define :parse , "(ChunkyPNG::Color ,String or Integer or Symbol)-> Integer", [/\A(?:#|0x)?([0-9a-f]{3})\z/i , 
                         /\A(?:#|0x)?([0-9a-f]{6})([0-9a-f]{2})?\z/i, 
                         /^([a-z][a-z_ ]+[a-z])(?:\ ?\@\ ?(1\.0|0\.\d+))?$/i, 
                         /^\d+$/,  
                         1.class ], consts: :true, moi: [] do
      
      spec  "should interpret a hex string correctly" do
        setup {

          parse(CHC,"0x0a649664")
        }
        post {|ret|
          assert {ret == ChunkyPNG::Color.from_hex("#0a649664")}
        }
      end

      spec  "should interpret a color name correctly 1" do
        setup {
          parse(CHC,:spring_green)}
        post {|ret|
          assert {ret == 0x00ff7fff}
        }
      end

      spec "should interpret a color name correctly 2" do
        setup { parse(CHC,"spring green") }
        
        post {|ret|
          assert {ret == 0x00ff7fff}
        }
      end

      spec "should interpret a color name correctly 3" do
        setup { parse(CHC,"spring green @ 0.6666") }
        post {|ret|
          assert {ret == 0x00ff7faa}
        }
      end                                           

      spec "should return numbers as is 1" do
        setup {parse(CHC,"12345")} 
        post {|ret|
          assert {ret ==12345}
        }
      end

      spec "should return numbers as is 2" do
        setup { parse(CHC,12345) }
        post {|ret|
          assert {ret == 12345}
        }
      end
      generate_program
    end
  end
end
# augmented: true
require "test_helper"
include RDL::Annotate


describe "Phone-3" do
  it "removes dashes and parenthesizes the first three chars" do
    ENV["EXCONSTS"] = "TRUE"
    RDL.nowrap :Node
    RDL.nowrap :Integer
    RDL.nowrap :BasicObject
    RDL.nowrap :String
    
    RDL.type :String, :+, "(String) -> String"
    RDL.type :String, :gsub, "(String, String) -> String"


    RDL.type :Integer, :+, "(Integer) -> Integer"
    RDL.type :Integer, :-, "(Integer) -> Integer"

    RDL.type :String, :start_with?, "(String) -> %bool"
    RDL.type :String, :end_with?, "(String) -> %bool"
    RDL.type :String, :include?, "(String) -> %bool"

    # RDL.type :BasicObject, :!, '() -> %bool'
    # RDL.type :BasicObject, :==, '(BaiscObject) -> %bool'
    



    define :ref, "(String) -> String", [], consts: :true, moi: [] do
      

      spec "Removes Parens and dashes" do

        setup {
          
          [reformat("938-242-504"), 
          reformat("308-916-545"), 
          reformat("623-599-749"), 
          reformat("981-424-843"), 
          reformat("118-980-214"), 
          reformat("244-655-094"), 
          reformat("830-941-991")] 

        }

        post { |result|
          assert { result == ["(938) 242-504",
            "(308) 916-545",
            "(623) 599-749",
            "(981) 424-843",
            "(118) 980-214",
            "(244) 655-094",
            "(830) 941-991"]}
        }
      end

      generate_program
    end
    
  end
end



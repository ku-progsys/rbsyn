# augmented: true
require "test_helper"

describe "Diaspora" do
  it "invitation_code#use!" do
    load_typedefs # :stdlib , :active_record
    RDL.type_params Array, [:t], :all?
    ParentsHelper.init_list()
    RDL.type :"Integer", :-, "(Integer) -> Integer", wrap: false #BR UNCERTAIN WHY THIS IS REQURIED IN MY VERSION. 
    RDL.type :"DynamicType", :count, "() -> %dyn", wrap: false
    RDL.type :"DynamicType", :-, '(%dyn) -> %dyn', wrap: false
    RDL.type :TrueClass, :"!", "() -> FalseClass", wrap: false
    RDL.type :FalseClass, :"!", "() -> TrueClass", wrap: false
    RDL.type :DynamicType, :save, '() -> %bool', wrap: false, write: ['*']
    ParentsHelper.subtract()

    define :use!, "(InvitationCode) -> %bot", [InvitationCode], consts: true, moi: [:count, :-, :save] do
      spec "decrements the count of the code" do
        setup {
          @code = Fabricate(:invitation_code)
          @old_count = @code.count
        
          use!(@code)
        }
        post { |result|
          assert { (@old_count - @code.count) == 1 }
        }
      end

      generate_program
    end
  end
end

#ORIGINAL
# describe "Diaspora" do
#   it "invitation_code#use!" do
#     load_typedefs :stdlib, :active_record

#     RDL.type Integer, :-, '(Integer) -> Integer', wrap: false

#     define :use!, "(InvitationCode) -> %bot", [InvitationCode], consts: true do
#       spec "decrements the count of the code" do
#         setup {
#           @code = Fabricate(:invitation_code)
#           @old_count = @code.count
#           use!(@code)
#         }
#         post { |result|
#           assert { (@old_count - @code.count) == 1 }
#         }
#       end

#       generate_program
#     end
#   end
# end

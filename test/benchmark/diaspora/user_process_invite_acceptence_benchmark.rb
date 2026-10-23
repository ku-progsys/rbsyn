# augmented: true
require "test_helper"

describe "Diaspora" do
  it "user#process_invite_acceptence" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :invited_by_id=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :diaspora_user_id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :synth_use!, '() -> %dyn', wrap: false, write: ['InvitationCode.count'] # AI generated
    RDL.type :DynamicType, :invited_by_id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :count, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # RDL.type InvitationCode, :synth_use!, '() -> %bot', wrap: false, write: ['InvitationCode.count']  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :process_invite_acceptence, "(DiasporaUser, InvitationCode) -> %bot", [DiasporaUser, InvitationCode] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :process_invite_acceptence, "(DiasporaUser, InvitationCode) -> %bot", [DiasporaUser, InvitationCode], moi: [:invited_by_id=, :diaspora_user_id, :synth_use!, :invited_by_id, :id, :count] do # AI generated
      spec "sets the inviter on user" do
        setup {
          @bob = Fabricate(:diaspora_user, username: 'bob')
          @inv = Fabricate(:invitation_code, :diaspora_user => @bob)
          @old_count = @inv.count
          @user = Fabricate(:diaspora_user)
          process_invite_acceptence(@user, @inv)
        }

        post { |result|
          assert { @user.invited_by_id == @bob.id }
          assert { @inv.count < @old_count }
        }
      end

      generate_program
    end
  end
end

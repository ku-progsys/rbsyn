# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L941
# This benchmark has two merged tests (T1 and T2)

require "test_helper"

describe "Discourse" do
  it "activate" do
    load_typedefs :stdlib, :active_record, :ar_update
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.confirm', '(%dyn) -> %dyn', wrap: false, write: ['EmailToken'] # AI generated
    RDL.type :DynamicType, :email_tokens, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :first, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :token, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :active=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :save, '() -> %dyn', wrap: false, write: ['*'] # AI generated
    RDL.type :DynamicType, :email_confirmed?, '() -> %dyn', wrap: false, read: ['EmailToken'] # AI generated
    RDL.type :DynamicType, :active, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # define :activate, "(User) -> %bot", [User, EmailToken], prog_size: 30 do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :activate, "(User) -> %bot", [User, EmailToken, {hashkeys: [:id, :email, :token, :confirmed, :expired, :user_id]}], prog_size: 30, moi: [:exists?, :confirm, :email_tokens, :first, :token, :active=, :save, :email_confirmed?, :active] do # AI generated
      class Fabricate
        def self.inactive_user
          u = User.create(username: 'user1', password: 'secret', active: false)
          u.emails.create(email: 'user1@example.com', primary: true)
          u.email_tokens.create(email: 'user1@example.com', expired: false, confirmed: false, token: 'temp_token4')
          u
        end
      end

      # RDL.type User, :email, '() -> String', read: ['UserEmail'], write: []  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
      # RDL.type User, :email_confirmed?, '() -> %bool', read: ['EmailToken'], write: []  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
      # RDL.type EmailToken, 'self.confirm', '(String) -> %bool', read: [], write: ['EmailToken']  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
      # RDL.type EmailToken, :active, '() -> ActiveRecord_Relation<EmailToken>', read: ['EmailToken'], write: []  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

      spec "confirms email token and activates user" do
        setup {
          @inactive = Fabricate(:inactive_user)
          activate(@inactive)
        }

        post { |result|
          assert { @inactive.email_confirmed? }
          assert { @inactive.active }
          @inactive.reload
          assert { @inactive.email_confirmed? }
          assert { @inactive.active }
        }
      end

      # spec 'works without needing to reload the model' do
      #   setup {
      #     @inactive = Fabricate(:inactive_user)
      #     activate(@inactive)
      #   }

      #   post { |result|
      #     assert { @inactive.email_confirmed? }
      #     assert { @inactive.active }
      #   }
      # end

      spec 'activates user even if email token is already confirmed' do
        setup {
          @inactive = Fabricate(:inactive_user)
          token = @inactive.email_tokens.find_by(email: @inactive.email)
          token.update_column(:confirmed, true)
          activate(@inactive)
        }

        post { | result|
          assert { @inactive.active }
        }
      end

      generate_program
    end
  end
end

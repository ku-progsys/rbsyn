require "test_helper"

describe "Diaspora" do
  it "user#confirm_email" do
    load_typedefs :stdlib, :active_record

    # RDL.type String, :blank?, '() -> %bool', wrap: false
    # RDL.type String, :!=, '(String) -> %bool', wrap: false
    # RDL.type 'self.exists?', "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
    
    RDL.type :DynamicType, :blank?, '() -> %dyn', wrap: false
    RDL.type :DynamicType, :!=, '(%dyn) -> %dyn', wrap: false
    RDL.type :DynamicType, 'self.exists?', "(%dyn) -> %dyn", wrap: false


    RDL.type :DynamicType, :unconfirmed_email= , '(%dyn) -> %dyn', wrap: false, write: ['self']
    RDL.type :DynamicType, :email=, "(%dyn) -> %dyn", wrap: false, write: ['self']
    RDL.type :DynamicType, :confirm_email_token=, "(%dyn) -> %dyn", wrap:false, write: ['self']
    RDL.type :DynamicType, :unconfirmed_email, "() -> %dyn", wrap: false, read: ['self']



    define :confirm_email, "(DiasporaUser, String) -> %bool", [DiasporaUser], enable_nil: true, prog_size: 30, moi: [:blank?, :!=, :"self.exists", :unconfirmed_email=, :unconfirmed_email, :confirm_email_token=, :email=] do
      spec 'confirms email and set the unconfirmed_email to email on valid token' do
        setup {
          @user = Fabricate(:diaspora_user_with_token)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, @user.confirm_email_token)
        }
        post { |result|
          assert { result == true }
          assert { @user.email == "alice@newmail.com" }
          assert { @user.unconfirmed_email == nil }
          assert { @user.confirm_email_token == nil }
        }
      end

      spec 'returns false and does not change anything on wrong token' do
        setup {
          @user = Fabricate(:diaspora_user_with_token)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, @user.confirm_email_token.reverse)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        setup {
          @user = Fabricate(:diaspora_user_with_token)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, "")
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        setup {
          @user = Fabricate(:diaspora_user_with_token)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, nil)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      spec 'returns false and does not change anything on any token' do
        setup {
          @user = Fabricate(:diaspora_user)
          confirm_email(@user, "12345" * 6)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email == nil }
          assert { @user.confirm_email_token == nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        setup {
          @user = Fabricate(:diaspora_user)
          confirm_email(@user, "")
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email == nil }
          assert { @user.confirm_email_token == nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        setup {
          @user = Fabricate(:diaspora_user)
          confirm_email(@user, nil)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email == nil }
          assert { @user.confirm_email_token == nil }
        }
      end

      generate_program
    end
  end
end

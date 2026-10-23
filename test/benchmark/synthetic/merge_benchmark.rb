require "test_helper"

describe "Synthetic" do
  it "fold branches" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :!, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.joins', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :exists?, '(%dyn) -> %dyn', wrap: false # AI generated
    ParentsHelper.subtract() # AI generated

    # define :username_exists?, "(String, String) -> %bool", [User, UserEmail] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    # define :username_exists?, "(String, String) -> %bool", [User, UserEmail, {hashkeys: [:email, :primary, :user_id, :id, :name, :username, :password, :staged, :active, :admin, :moderator]}], moi: [:!, :joins, :exists?] do # AI generated
    # AI altered: symbols the solution needs as bare arguments are given as constant components (depth-0 fills)
    define :username_exists?, "(String, String) -> %bool", [User, UserEmail, :user, {hashkeys: [:email, :primary, :user_id, :id, :name, :username, :password, :staged, :active, :admin, :moderator]}], moi: [:!, :joins, :exists?] do # AI generated

      spec "returns true when user doesn't exist" do
        setup {
          username_exists? 'bruce1', nil
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns true when username exists without email" do
        setup {
          u = Fabricate(:user)
          Fabricate(:email, email: 'bruce@wayne.com')
          username_exists? u.username, 'bruce@wayne.com'
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns false when username exists with email" do
        setup {
          u = Fabricate(:user)
          u.emails.create(email: 'bruce@wayne.com')
          username_exists? u.username, 'bruce@wayne.com'
        }

        post { |result|
          assert { result == false }
        }
      end

      generate_program
    end
  end
end

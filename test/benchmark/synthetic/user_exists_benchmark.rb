require "test_helper"

describe "Synthetic" do
  it "user exists" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    ParentsHelper.subtract() # AI generated

    # define :username_exists?, "(String) -> %bool", [User, UserEmail], moi: [:exists?,] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :username_exists?, "(String) -> %bool", [User, UserEmail, {hashkeys: [:id, :name, :username, :password, :staged, :active, :admin, :moderator]}], moi: [:exists?] do # AI generated

      spec "returns false when user doesn't exist" do
        setup {
          username_exists? 'bruce1'
        }

        post { |result|
          assert { result == false }
        }
      end

      spec "returns true when user exists" do
        setup {
          u = Fabricate(:user)
          username_exists? u.username
        }

        post { |result|
          assert { result == true }
        }
      end

      generate_program
    end
  end
end

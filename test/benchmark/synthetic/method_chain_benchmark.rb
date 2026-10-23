require "test_helper"

describe "Synthetic" do
  it "method chains" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :!, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    ParentsHelper.subtract() # AI generated

    # define :username_available?, "(String) -> %bool", [User, UserEmail] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :username_available?, "(String) -> %bool", [User, UserEmail, {hashkeys: [:id, :name, :username, :password, :staged, :active, :admin, :moderator]}], moi: [:!, :exists?] do # AI generated

      spec "returns true when user doesn't exist" do
        setup {
          username_available? 'bruce1'
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns false when user exists" do
        setup {
          u = Fabricate(:user)
          username_available? u.username
        }

        post { |result|
          assert { result == false }
        }
      end

      generate_program
    end
  end
end

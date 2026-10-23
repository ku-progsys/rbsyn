require "test_helper"

describe "Synthetic" do
  it "branching" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.reserved_username?', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :!, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    ParentsHelper.subtract() # AI generated

    class SiteSettings
      class << self
        reserved_usernames = []
        attr_accessor :reserved_usernames
      end

      def self.reserved_username?(username)
        SiteSettings.reserved_usernames.include? username
      end
    end
    # RDL.type SiteSettings, 'self.reserved_username?', '(String) -> %bool', wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :username_available?, "(String) -> %bool", [User, UserEmail, SiteSettings] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :username_available?, "(String) -> %bool", [User, UserEmail, SiteSettings, {hashkeys: [:id, :name, :username, :password, :staged, :active, :admin, :moderator]}], moi: [:reserved_username?, :!, :exists?] do # AI generated

      reset {
        SiteSettings.reserved_usernames = []
      }

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

      spec "returns false when username is reserved" do
        setup {
          SiteSettings.reserved_usernames = ['apple', 'dog']
          username_available? 'apple'
        }

        post { |result|
          assert { result == false }
        }
      end

      generate_program
    end
  end
end

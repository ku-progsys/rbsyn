# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1532
require "test_helper"

describe "Discourse" do
  it "check_site_contact_username" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.set_and_log', '(%dyn, %dyn) -> %dyn', wrap: false, write: ['DiscourseSiteSetting'] # AI generated
    RDL.type :DynamicType, :'self.defaults', '() -> %dyn', wrap: false, read: ['DiscourseSiteSetting'] # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :admin, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :moderator, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :!, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.site_contact_username', '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :username, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    class DiscourseSiteSetting
      def self.set_and_log(field, value)
        case field
        when :site_contact_username
          @@site_contact_username = value
        else
          raise RuntimeError, "unknown field"
        end
      end

      def self.site_contact_username
        @@site_contact_username
      end

      def self.site_contact_username=(username)
        @@site_contact_username = username
      end

      def self.defaults
        { site_contact_username: 'default_contact' }
      end
    end

    # RDL.type DiscourseSiteSetting, 'self.set_and_log', '(:site_contact_username, String) -> %bot', write: ['DiscourseSiteSetting'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type DiscourseSiteSetting, 'self.site_contact_username', '() -> String', read: ['DiscourseSiteSetting.site_contact_username'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type DiscourseSiteSetting, 'self.defaults', '() -> { site_contact_username: String }', read: ['DiscourseSiteSetting'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type User, :staff?, '() -> %bool', read: ['User'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :check_site_contact_username, "(User) -> %bot", [DiscourseSiteSetting] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    # define :check_site_contact_username, "(User) -> %bot", [DiscourseSiteSetting], moi: [:set_and_log, :defaults, :[], :admin, :moderator, :!, :site_contact_username, :username] do # AI generated
    # AI altered: symbols the solution needs as bare arguments are given as constant components (depth-0 fills)
    define :check_site_contact_username, "(User) -> %bot", [DiscourseSiteSetting, :site_contact_username], moi: [:set_and_log, :defaults, :[], :admin, :moderator, :!, :site_contact_username, :username] do # AI generated

      spec "clears site_contact_username site setting when admin privilege is revoked" do
        setup {
          @contact_user = Fabricate(:admin)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      spec "clears site_contact_username site setting when moderator privilege is revoked" do
        setup {
          @contact_user = Fabricate(:moderator)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      spec "does not change site_contact_username site setting when admin privilege is revoked" do
        setup {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == @contact_user.username }
        }
      end

      spec "does not change site_contact_username site setting when moderator privilege is revoked" do
        setup {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == @contact_user.username }
        }
      end

      spec "clears site_contact_username site setting when staff privileges are revoked" do
        setup {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      generate_program
    end
  end
end

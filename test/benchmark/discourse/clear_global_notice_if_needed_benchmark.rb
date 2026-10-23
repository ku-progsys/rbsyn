# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1304
# test ordering matters in this to get a successful synthesis
require "test_helper"

describe "Discourse" do
  it "clear_global_notice_if_needed" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :<, '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :admin, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :'self.has_login_hint=', '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :'self.global_notice=', '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :'self.has_login_hint', '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :'self.global_notice', '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    class DiscourseSiteSetting
      class << self
        attr_accessor :has_login_hint, :global_notice
      end
    end

    # RDL.type DiscourseSiteSetting, 'self.has_login_hint', '() -> %bool', read: ['DiscourseSiteSetting.has_login_hint'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type DiscourseSiteSetting, 'self.has_login_hint=', '(%bool) -> %bool', write: ['DiscourseSiteSetting.has_login_hint'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type DiscourseSiteSetting, 'self.global_notice', '() -> String', read: ['DiscourseSiteSetting.global_notice'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type DiscourseSiteSetting, 'self.global_notice=', '(String) -> String', write: ['DiscourseSiteSetting.global_notice'], wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # RDL.type Integer, :<, '(Integer) -> %bool', wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :clear_global_notice_if_needed, "(User) -> %bot", [DiscourseSiteSetting], prog_size: 30, consts: true do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :clear_global_notice_if_needed, "(User) -> %bot", [DiscourseSiteSetting], prog_size: 30, consts: true, moi: [:id, :<, :admin, :has_login_hint=, :global_notice=, :has_login_hint, :global_notice] do # AI generated

      spec "doesn't clear the notice when a system user is saved" do
        setup {
          system_user = Fabricate(:admin, id: -1)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(system_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == true }
          assert { DiscourseSiteSetting.global_notice == "some notice" }
        }
      end

      spec "clears the notice when the admin is saved" do
        setup {
          admin = Fabricate(:admin)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(admin)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == false }
          assert { DiscourseSiteSetting.global_notice == "" }
        }
      end

      spec "doesn't clear the login hint when a regular user is saved" do
        setup {
          user = Fabricate(:user, admin: false)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(user)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == true }
          assert { DiscourseSiteSetting.global_notice == "some notice" }
        }
      end

      generate_program
    end
  end
end

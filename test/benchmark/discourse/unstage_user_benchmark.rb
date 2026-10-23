require "test_helper"

describe "Discourse" do
  it "unstage user" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.where', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :first, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :username=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :name=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :active=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :username, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :name, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :active, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :email, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # define :unstage, "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser", [AnotherUser], prog_size: 30, enable_nil: true do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    # define :unstage, "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser", [AnotherUser, {hashkeys: [:id, :name, :username, :password, :staged, :email, :active]}], prog_size: 30, enable_nil: true, moi: [:exists?, :where, :first, :username=, :name=, :active=, :[], :id, :username, :name, :active, :email] do # AI generated
    # AI altered: symbols the solution needs as bare arguments are given as constant components (depth-0 fills)
    define :unstage, "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser", [AnotherUser, :username, :name, {hashkeys: [:id, :name, :username, :password, :staged, :email, :active]}], prog_size: 30, enable_nil: true, moi: [:exists?, :where, :first, :username=, :name=, :active=, :[], :id, :username, :name, :active, :email] do # AI generated
      spec "correctly unstages a user" do
        setup {
          @staged = Fabricate(:staged_user, email: 'staged@account.com')
          unstage(email: 'staged@account.com', active: true, username: 'unstaged1', name: 'Foo Bar')
        }

        post { |user|
          assert { user.id == @staged.id }
          assert { user.username == 'unstaged1' }
          assert { user.name == 'Foo Bar' }
          assert { user.active == false }
          assert { user.email == 'staged@account.com' }
        }
      end

      spec "returns nil when the user cannot be unstaged" do
        setup {
          Fabricate(:coding_horror)
          unstage(email: 'jeff@somewhere.com')
        }

        post { |user|
          assert { user == nil }
        }
      end

      spec "returns nil when the user cannot be unstaged" do
        setup {
          unstage(email: 'ano@account.com')
        }

        post { |user|
          assert { user == nil }
        }
      end

      generate_program
    end
  end
end

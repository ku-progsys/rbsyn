# synthetic: true
require "test_helper"

describe "Synthetic" do
  it "overview example" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.exists?', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :'self.where', '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :first, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :title=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :created_by=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :slug=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :created_by, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :title, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :slug, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser], prog_size: 30, max_hash_size: 2 do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    # define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser, {hashkeys: [:id, :created_by, :slug, :title, :name, :username, :admin]}], prog_size: 30, max_hash_size: 2, moi: [:exists?, :where, :first, :title=, :created_by=, :slug=, :[], :id, :created_by, :title, :slug] do # AI generated
    # AI altered: symbols the solution needs as bare arguments are given as constant components (depth-0 fills)
    define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser, :title, :created_by, :slug, {hashkeys: [:id, :created_by, :slug, :title, :name, :username, :admin]}], prog_size: 30, max_hash_size: 2, moi: [:exists?, :where, :first, :title=, :created_by=, :slug=, :[], :id, :created_by, :title, :slug] do # AI generated
      class Shared
        def self.seed_db
          dummy = Fabricate(:demo_user, name: 'Dummy', username: 'dummy')
          admin = Fabricate(:demo_user, name: 'Admin', username: 'admin', admin: true)
          author = Fabricate(:demo_user, name: 'Author', username: 'author')
          dummy_post = Fabricate(:post, created_by: 'dummy')
          admin_post = Fabricate(:post, created_by: 'admin')
          author_post = Fabricate(:post, created_by: 'author')
        end
      end

      spec "author can only change titles" do
        setup {
          Shared.seed_db
          @post = Fabricate(:post, created_by: 'author', slug: 'hello-world', title: 'Hello World')
          update_post('author', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')
        }

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "author" }
          assert { updated.title == "Foo Bar" }
          assert { updated.slug == 'hello-world' }
        }
      end

      spec "unrelated users cannot change anything" do
        setup {
          Shared.seed_db
          @post = Fabricate(:post, created_by: 'author', slug: 'hello-world', title: 'Hello World')
          update_post('dummy', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')
        }

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "author" }
          assert { updated.title == "Hello World" }
          assert { updated.slug == 'hello-world' }
        }
      end

      spec "admin can takeover any post" do
        setup {
          Shared.seed_db
          @post = Fabricate(:post, created_by: 'author', slug: 'hello-world', title: 'Hello World')
          update_post('admin', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')
        }

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "dummy" }
          assert { updated.title == "Foo Bar" }
          assert { updated.slug == 'foo-bar' }
        }
      end

      generate_program
    end
  end
end

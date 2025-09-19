# synthetic: true
load_typedefs :stdlib, :active_record

define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser], prog_size: 30, max_hash_size: 2 do
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
end
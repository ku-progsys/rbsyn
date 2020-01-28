require "test_helper"

describe "Synthesis Benchmark" do
  it "unstage user" do
    define :unstage,
    "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser",
    [AnotherUser], prog_size: 10 do
      spec "correctly unstages a user" do
        pre {
          @dummy = AnotherUser.create(name: 'Dummy User', username: 'dummy1', active: true, email: 'dummy@account.com')
          @staged = AnotherUser.create(name: 'Staged User', username: 'staged1', active: true, email: 'staged@account.com')
        }

        user = unstage(email: 'staged@account.com', active: true, username: 'unstaged1', name: 'Foo Bar')

        post { |user|
          assert { user.id == @staged.id }
          assert { user.username == 'unstaged1' }
          # assert { user.name == 'Foo Bar' }
          # assert { user.active == false }
          # assert { user.email == 'staged@account.com' }
        }
      end

      puts generate_program
    end
  end
end

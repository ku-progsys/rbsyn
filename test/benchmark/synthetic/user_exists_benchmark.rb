require "test_helper"

# describe "Synthetic" do
#   it "user exists" do
    load_typedefs :stdlib, :active_record

    define :username_exists?, "(String) -> %bool", [User, UserEmail] do

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

      # generate_program
    end
#   end
# end

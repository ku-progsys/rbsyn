require "test_helper"

describe "Synthetic" do
  it "false" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    ParentsHelper.subtract() # AI generated

    define :just_false, "(String) -> %bool", [User, UserEmail] do

      spec "returns false" do
        setup {
          just_false 'hello'
        }

        post { |result|
          assert { result == false }
        }
      end

      generate_program
    end
  end
end

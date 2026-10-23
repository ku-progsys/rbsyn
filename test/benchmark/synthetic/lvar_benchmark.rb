require "test_helper"

describe "Synthetic" do
  it "lvar" do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    ParentsHelper.subtract() # AI generated

    define :identity, "(String) -> String", [User, UserEmail] do

      spec "returns same value" do
        setup {
          identity 'hello'
        }

        post { |result|
          assert { result == 'hello' }
        }
      end

      generate_program
    end
  end
end

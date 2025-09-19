load_typedefs :stdlib, :active_record

define :just_false, "(String) -> %bool", [User, UserEmail] do

  spec "returns false" do
    setup {
      just_false 'hello'
    }

    post { |result|
      assert { result == false }
    }
  end
end
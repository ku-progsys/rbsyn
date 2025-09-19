load_typedefs :stdlib, :active_record

define :identity, "(String) -> String", [User, UserEmail] do

  spec "returns same value" do
    setup {
      identity 'hello'
    }

    post { |result|
      assert { result == 'hello' }
    }
  end
end
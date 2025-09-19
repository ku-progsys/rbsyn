RDL.nowrap :Integer
RDL.nowrap :BasicObject
RDL.type :Integer, :%, "(Integer) -> Integer"
RDL.type :Integer, :!=, "(Integer) -> %bool"
RDL.type :Integer, :==, "(Integer) -> %bool"
RDL.type :BasicObject, :!, '() -> %bool'
RDL.nowrap :Hash
RDL.type_params :Hash, [:k, :v], :all?

define :even?, "(Integer) -> %bool", [], consts: true do

  spec "returns true for even" do
    setup {
      even? 4
    }

    post { |result|
      assert { result == true }
    }
  end

  spec "returns false for odd" do
    setup {
      even? 5
    }

    post { |result|
      assert { result == false }
    }
  end

  generate_program
end
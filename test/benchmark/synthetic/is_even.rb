require_relative "../test_helper"

define :is_even?, "(Integer) -> %bool", "pure" do

  spec "returns true for even numbers" do
    post(4) { |result| result == true }
  end

  spec "returns false for odd numbers" do
    post(5) { |result| result == false }
  end

  puts generate_program
end

# require_relative "HamsterDeps/hamster_stub.rb"
# L = Hamster::List_1
# require "rspec"

# describe Hamster::List_1 do
#   describe "#split_at" do
#     it "is lazy" do
#       expect { Hamster.stream { fail }.split_at(1) }.not_to raise_error
#     end

#     [
#       [[], [], []],
#       [[1], [1], []],
#       [[1, 2], [1, 2], []],
#       [[1, 2, 3], [1, 2], [3]],
#       [[1, 2, 3, 4], [1, 2], [3, 4]],
#     ].each do |values, expected_prefix, expected_remainder|
#       context "on #{values.inspect}" do
#         let(:list) { L[*values] }
#         let(:result) { list.split_at(2) }
#         let(:prefix) { result.first }
#         let(:remainder) { result.last }

#         it "preserves the original" do
#           result
#           expect(list).to eql(L[*values])
#         end

#         it "returns a frozen array with two items" do
#           expect(result.class).to be(Array)
#           expect(result).to be_frozen
#           expect(result.size).to be(2)
#         end

#         it "correctly identifies the matches" do
#           expect(prefix).to eql(L[*expected_prefix])
#         end

#         it "correctly identifies the remainder" do
#           expect(remainder).to eql(L[*expected_remainder])
#         end
#       end
#     end
#   end
# end

#THIS SPEC IS NOW WORKING (NOT THE SYTHESIS VERSION YET)
# I SEE THE REASON IT ISN'T WORKING IS BECAUSE IT CAN'T DEAL WITH 
# LOOPS



require_relative "./spec_helper.rb"

describe ChunkyPNG do
  it "should have a VERSION constant" do
    expect(ChunkyPNG.const_defined?("VERSION")).to be_truthy
  end
end

require "spec_helper.rb"
require "pathname"
require "fastimage"
require "shellwords"

describe CleanyStatus do
  it "has a version number" do
    expect(CleanyStatus::VERSION).not_to be nil
  end

  # it "does something useful" do
  #   expect(false).to eq(true)
  # end
end


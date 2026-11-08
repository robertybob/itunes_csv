require "minitest/autorun"
require "itunes_csv"

describe "README" do
  it "lists every field" do
    readme = File.read(File.expand_path("../README.md", __dir__))
    ItunesCsv::Fields.names.each do |name|
      _(readme).must_include "`#{name}`", "README is missing #{name}"
    end
  end
end

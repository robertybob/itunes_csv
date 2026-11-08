require "minitest/autorun"
require "stringio"
require "tmpdir"
require "itunes_csv"

describe ItunesCsv::CommandLine do
  FIXTURE = File.expand_path("fixtures/library.xml", __dir__)

  def run_cli(*args)
    out = StringIO.new
    err = StringIO.new
    status = ItunesCsv::CommandLine.invoke(args, out: out, err: err)
    [status, out.string, err.string]
  end

  it "exports name and artist by default" do
    status, out, err = run_cli("-p", FIXTURE)

    _(status).must_equal 0
    _(err).must_be_empty
    rows = CSV.parse(out)
    _(rows.first).must_equal ["name", "artist"]
    _(rows[1]).must_equal ["Life In Technicolor", "Coldplay"]
    _(rows.size).must_be :>, 2
  end

  it "exports the requested fields in order" do
    status, out, _err = run_cli("-p", FIXTURE, "-f", "year,name,album")

    _(status).must_equal 0
    rows = CSV.parse(out)
    _(rows.first).must_equal ["year", "name", "album"]
    _(rows[1]).must_equal ["2008", "Life In Technicolor", "Viva la Vida"]
  end

  it "writes to a file with --output" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "out.csv")
      status, out, _err = run_cli("-p", FIXTURE, "-o", path)

      _(status).must_equal 0
      _(out).must_include "CSV written to #{path}"
      _(CSV.read(path).first).must_equal ["name", "artist"]
    end
  end

  it "rejects unknown fields before reading the library, with nothing on stdout" do
    status, out, err = run_cli("-p", "does-not-exist.xml", "-f", "name,bogus")

    _(status).must_equal 1
    _(out).must_be_empty
    _(err).must_include "Unknown field: bogus"
    _(err).must_include "Valid fields:"
    _(err).must_include "artist"
  end

  it "reports a missing library file" do
    status, out, err = run_cli("-p", "does-not-exist.xml")

    _(status).must_equal 1
    _(out).must_be_empty
    _(err).must_include "iTunes library file not found"
  end

  it "reports where it looked when no default library exists" do
    Dir.mktmpdir do |home|
      with_home(home) do
        status, _out, err = run_cli

        _(status).must_equal 1
        _(err).must_include "Could not find an iTunes library XML file"
        _(err).must_include "iTunes Library.xml"
        _(err).must_include "iTunes Music Library.xml"
      end
    end
  end

  it "finds the default library under ~/Music/iTunes" do
    Dir.mktmpdir do |home|
      itunes_dir = File.join(home, "Music", "iTunes")
      FileUtils.mkdir_p(itunes_dir)
      FileUtils.cp(FIXTURE, File.join(itunes_dir, "iTunes Library.xml"))

      with_home(home) do
        status, out, _err = run_cli

        _(status).must_equal 0
        _(CSV.parse(out)[1]).must_equal ["Life In Technicolor", "Coldplay"]
      end
    end
  end

  it "fails on an invalid option" do
    status, _out, err = run_cli("--wat")

    _(status).must_equal 1
    _(err).must_include "invalid option"
  end

  def with_home(dir)
    old = ENV["HOME"]
    ENV["HOME"] = dir
    yield
  ensure
    ENV["HOME"] = old
  end
end

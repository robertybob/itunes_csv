require "minitest/autorun"
require "itunes_csv"

describe ItunesCsv::Fields do
  SONG_FIELDS = File.expand_path("fixtures/song_fields.xml", __dir__)

  def export_row(fields, row: 1)
    csv_string, _count = ItunesCsv.export(SONG_FIELDS, fields)
    CSV.parse(csv_string, headers: true)[row - 1].to_h
  end

  it "puts every field in one of the known sections, with a description" do
    ItunesCsv::Fields::ALL.each do |field|
      _(ItunesCsv::Fields::SECTIONS).must_include field.section, field.name
      _(field.description.to_s).wont_be_empty
    end
    _(ItunesCsv::Fields.names.uniq.size).must_equal ItunesCsv::Fields.names.size
  end

  it "no longer offers TV season and episode fields" do
    _(ItunesCsv.valid_fields).wont_include "season_number"
    _(ItunesCsv.valid_fields).wont_include "episode_number"
  end

  it "exports the song fields" do
    row = export_row(%w[album_artist grouping bpm compilation? track_count disc_number disc_count
                        comments work movement_name movement_number movement_count explicit?
                        skip_count last_skipped_at release_date sort_name sort_album_artist])
    _(row).must_equal({
      "album_artist" => "Various Artists", "grouping" => "Morning", "bpm" => "128",
      "compilation?" => "true", "track_count" => "12", "disc_number" => "1", "disc_count" => "2",
      "comments" => "A comment, with a comma", "work" => "Symphony No. 5",
      "movement_name" => "Allegro con brio", "movement_number" => "1", "movement_count" => "4",
      "explicit?" => "true", "skip_count" => "2", "last_skipped_at" => "2022-03-04T05:06:07+00:00",
      "release_date" => "2020-05-01T07:00:00+00:00", "sort_name" => "Song, Test",
      "sort_album_artist" => "Artists, Various"
    })
  end

  it "exports the file, status and rating fields" do
    row = export_row(%w[size date_modified track_type purchased? protected? volume_adjustment
                        equalizer start_time stop_time disabled? loved? favorited? disliked?])
    _(row).must_equal({
      "size" => "5000000", "date_modified" => "2021-06-07T08:09:10+00:00", "track_type" => "File",
      "purchased?" => "true", "protected?" => "true", "volume_adjustment" => "-50",
      "equalizer" => "Rock", "start_time" => "1000", "stop_time" => "240000",
      "disabled?" => "true", "loved?" => "true", "favorited?" => "true", "disliked?" => "true"
    })
  end

  it "uses false and 0 when iTunes leaves a property out" do
    row = export_row(%w[compilation? explicit? purchased? disabled? loved? play_count skip_count bpm album_artist], row: 2)
    _(row).must_equal({
      "compilation?" => "false", "explicit?" => "false", "purchased?" => "false",
      "disabled?" => "false", "loved?" => "false", "play_count" => "0", "skip_count" => "0",
      "bpm" => nil, "album_artist" => nil
    })
  end

  it "gives total_time in seconds" do
    _(export_row(%w[total_time])["total_time"]).must_equal "245"
  end

  it "turns Windows file locations into normal paths" do
    _(export_row(%w[location_path])["location_path"]).must_equal "C:/Users/me/Music/AC+DC Test Song.mp3"
  end
end

require "uri"

module ItunesCsv
  # Every field that can be exported, grouped into sections. This list drives
  # the command line (--fields), the GUI checkboxes and the README table.
  #
  # Each field reads a value from an ITunes::Track. Most read a property from
  # the iTunes XML directly; iTunes leaves a property out when it has no value,
  # so true/false fields default to false and counts to 0 where that is what
  # "missing" means.
  Field = Struct.new(:name, :section, :description, :reader) do
    def value(track)
      reader.call(track)
    end
  end

  module Fields
    SECTIONS = [
      "Song info",
      "File and technical",
      "Play status flags",
      "Rating details",
      "Other media types",
    ].freeze

    # Reads a property straight from the XML.
    def self.key(name)
      ->(t) { t[name] }
    end

    # Reads a true/false property, treating "missing" as false.
    def self.flag(name)
      ->(t) { t[name] ? true : false }
    end

    # Reads a count, treating "missing" as 0.
    def self.count(name)
      ->(t) { t[name] || 0 }
    end

    # Turns iTunes' file://localhost/... URL into a normal path,
    # e.g. C:/Users/me/Music/song.mp3 on Windows or /Users/me/Music/song.mp3 on a Mac.
    def self.location_path(track)
      location = track["Location"]
      return nil unless location
      path = URI.decode_www_form_component(location.sub(%r{\Afile://(localhost)?}, "").gsub("+", "%2B"))
      path.sub(%r{\A/([A-Za-z]:/)}, '\1')
    end

    ALL = [
      # Song info
      ["name",              "Song info", "Song title",                                   key("Name")],
      ["artist",            "Song info", "Artist",                                       key("Artist")],
      ["album_artist",      "Song info", "Album artist",                                 key("Album Artist")],
      ["album",             "Song info", "Album",                                        key("Album")],
      ["composer",          "Song info", "Composer",                                     key("Composer")],
      ["genre",             "Song info", "Genre",                                        key("Genre")],
      ["grouping",          "Song info", "Grouping",                                     key("Grouping")],
      ["year",              "Song info", "Year",                                         key("Year")],
      ["release_date",      "Song info", "Release date",                                 key("Release Date")],
      ["number",            "Song info", "Track number",                                 key("Track Number")],
      ["track_count",       "Song info", "Number of tracks on the disc (the \"of 12\" in \"3 of 12\")", key("Track Count")],
      ["disc_number",       "Song info", "Disc number",                                  key("Disc Number")],
      ["disc_count",        "Song info", "Number of discs (the \"of 2\" in \"1 of 2\")", key("Disc Count")],
      ["compilation?",      "Song info", "Part of a compilation album",                  flag("Compilation")],
      ["total_time",        "Song info", "Length in seconds",                            ->(t) { t["Total Time"] && t["Total Time"] / 1000 }],
      ["bpm",               "Song info", "Beats per minute",                             key("BPM")],
      ["comments",          "Song info", "Comments",                                     key("Comments")],
      ["work",              "Song info", "Work (classical music)",                       key("Work")],
      ["movement_name",     "Song info", "Movement name (classical music)",              key("Movement Name")],
      ["movement_number",   "Song info", "Movement number (classical music)",            key("Movement Number")],
      ["movement_count",    "Song info", "Number of movements (classical music)",        key("Movement Count")],
      ["explicit?",         "Song info", "Marked as explicit",                           flag("Explicit")],
      ["content_rating",    "Song info", "Content rating, as stored by iTunes",          key("Content Rating")],
      ["date_added",        "Song info", "Date and time added to the library",           key("Date Added")],
      ["play_count",        "Song info",  "Number of plays",                                     count("Play Count")],
      ["last_played_at",    "Song info",  "Date and time last played",                           key("Play Date UTC")],
      ["skip_count",        "Song info",  "Number of skips",                                     count("Skip Count")],
      ["last_skipped_at",   "Song info",  "Date and time last skipped",                          key("Skip Date")],
      ["rating",            "Song info", "Star rating, 0-100 (20 = 1 star, 100 = 5 stars)",       key("Rating")],
      ["album_rating",      "Song info", "Album star rating, 0-100",                              key("Album Rating")],
      ["sort_name",         "Song info", "Title used for sorting, if different",         key("Sort Name")],
      ["sort_artist",       "Song info", "Artist used for sorting, if different",        key("Sort Artist")],
      ["sort_album_artist", "Song info", "Album artist used for sorting, if different",  key("Sort Album Artist")],
      ["sort_album",        "Song info", "Album used for sorting, if different",         key("Sort Album")],
      ["sort_composer",     "Song info", "Composer used for sorting, if different",      key("Sort Composer")],

      # File and technical
      ["location",          "File and technical", "File location as a URL (file://localhost/...)", key("Location")],
      ["location_path",     "File and technical", "File location as a normal path",               method(:location_path)],
      ["kind",              "File and technical", "File type, e.g. \"MPEG audio file\" or \"AAC audio file\"", key("Kind")],
      ["size",              "File and technical", "File size in bytes",                           key("Size")],
      ["bit_rate",          "File and technical", "Bit rate in kbps, e.g. 256",                    key("Bit Rate")],
      ["sample_rate",       "File and technical", "Sample rate in Hz, e.g. 44100",                 key("Sample Rate")],
      ["date_modified",     "File and technical", "Date and time the file was last changed",       key("Date Modified")],
      ["track_type",        "File and technical", "Where the track lives, e.g. File, URL or Remote", key("Track Type")],
      ["purchased?",        "File and technical", "Bought from the iTunes Store",                  flag("Purchased")],
      ["protected?",        "File and technical", "Copy-protected (DRM)",                          flag("Protected")],
      ["artwork_count",     "File and technical", "Number of artwork images attached",             key("Artwork Count")],
      ["volume_adjustment", "File and technical", "Volume adjustment set for this song (-255 to 255)", key("Volume Adjustment")],
      ["equalizer",         "File and technical", "Equalizer preset set for this song",            key("Equalizer")],
      ["start_time",        "File and technical", "Custom start time in milliseconds",             key("Start Time")],
      ["stop_time",         "File and technical", "Custom stop time in milliseconds",              key("Stop Time")],
      ["id",                "File and technical", "iTunes' internal track number (can change if the library is rebuilt)", key("Track ID")],
      ["persistent_id",     "File and technical", "iTunes' permanent unique ID for the track",     key("Persistent ID")],

      # Play status flags
      ["played?",           "Play status flags", "Played at least once",                                ->(t) { t.played? }],
      ["unplayed?",         "Play status flags", "Never played, or marked as unplayed in iTunes",       ->(t) { t.unplayed? }],
      ["disabled?",         "Play status flags", "Unticked in iTunes (skipped when playing through)",   flag("Disabled")],

      # Rating details
      ["rating_computed?",       "Rating details", "Star rating was worked out by iTunes, not set by you",  flag("Rating Computed")],
      ["album_rating_computed?", "Rating details", "Album rating was worked out by iTunes, not set by you", flag("Album Rating Computed")],
      ["loved?",                 "Rating details", "Loved (older iTunes versions)",                         flag("Loved")],
      ["favorited?",             "Rating details", "Favorited (newer iTunes versions)",                     flag("Favorited")],
      ["disliked?",              "Rating details", "Disliked",                                              flag("Disliked")],

      # Other media types
      ["audio?",     "Other media types", "Audio (not video)",                     ->(t) { t.audio? }],
      ["video?",     "Other media types", "Has video, e.g. a music video",         flag("Has Video")],
      ["movie?",     "Other media types", "Movie",                                 flag("Movie")],
      ["tv_show?",   "Other media types", "TV show",                               flag("TV Show")],
      ["podcast?",   "Other media types", "Podcast",                               flag("Podcast")],
      ["audiobook?", "Other media types", "Audiobook (Audible)",                   ->(t) { t.audiobook? }],
    ].map { |name, section, description, reader| Field.new(name, section, description, reader).freeze }.freeze

    BY_NAME = ALL.to_h { |f| [f.name, f] }.freeze

    def self.names
      ALL.map(&:name)
    end

    def self.[](name)
      BY_NAME.fetch(name.to_s)
    end

    def self.in_section(section)
      ALL.select { |f| f.section == section }
    end
  end
end

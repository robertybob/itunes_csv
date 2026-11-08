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
      ["name", "Song info", key("Name"),
       "The song's title."],
      ["artist", "Song info", key("Artist"),
       "The singer or band."],
      ["album_artist", "Song info", key("Album Artist"),
       "The main artist for the whole album, e.g. \"Various Artists\" on a compilation. Often empty if it's the same as the artist."],
      ["album", "Song info", key("Album"),
       "The name of the album the song is on."],
      ["composer", "Song info", key("Composer"),
       "Who wrote the song."],
      ["genre", "Song info", key("Genre"),
       "The style of music, e.g. Rock or Pop."],
      ["grouping", "Song info", key("Grouping"),
       "A label you can type in to group songs together, e.g. \"Wedding\". Usually empty."],
      ["year", "Song info", key("Year"),
       "The year the song came out."],
      ["release_date", "Song info", key("Release Date"),
       "The full date the song came out. Usually only filled in for songs from the iTunes Store."],
      ["number", "Song info", key("Track Number"),
       "The song's position on the album (its track number)."],
      ["track_count", "Song info", key("Track Count"),
       "How many tracks are on the album or disc (the \"12\" in \"track 3 of 12\")."],
      ["disc_number", "Song info", key("Disc Number"),
       "Which disc the song is on, for albums with more than one CD."],
      ["disc_count", "Song info", key("Disc Count"),
       "How many discs the album has (the \"2\" in \"disc 1 of 2\")."],
      ["compilation?", "Song info", flag("Compilation"),
       "Whether the song is on a \"various artists\" style album, such as a soundtrack or a greatest-hits collection."],
      ["total_time", "Song info", ->(t) { t["Total Time"] && t["Total Time"] / 1000 },
       "How long the song is, in seconds (e.g. 245 = 4 minutes 5 seconds)."],
      ["bpm", "Song info", key("BPM"),
       "How fast the song is, in beats per minute. Usually empty unless you or another app filled it in."],
      ["comments", "Song info", key("Comments"),
       "Any notes typed into the song's Comments box."],
      ["work", "Song info", key("Work"),
       "For classical music: the name of the whole piece, e.g. \"Symphony No. 5\"."],
      ["movement_name", "Song info", key("Movement Name"),
       "For classical music: the name of this part of the piece, e.g. \"Allegro con brio\"."],
      ["movement_number", "Song info", key("Movement Number"),
       "For classical music: which part of the piece this is (1, 2, 3...)."],
      ["movement_count", "Song info", key("Movement Count"),
       "For classical music: how many parts the whole piece has."],
      ["explicit?", "Song info", flag("Explicit"),
       "Whether the song is marked as having explicit lyrics."],
      ["content_rating", "Song info", key("Content Rating"),
       "An age rating stored with the song, if there is one. Usually empty for music."],
      ["date_added", "Song info", key("Date Added"),
       "When the song was added to your iTunes library."],
      ["play_count", "Song info", count("Play Count"),
       "How many times you've played the song."],
      ["last_played_at", "Song info", key("Play Date UTC"),
       "When you last played the song."],
      ["skip_count", "Song info", count("Skip Count"),
       "How many times you skipped the song soon after it started."],
      ["last_skipped_at", "Song info", key("Skip Date"),
       "When you last skipped the song."],
      ["rating", "Song info", key("Rating"),
       "Your star rating for the song, from 0 to 100: 20 = 1 star, 40 = 2 stars, up to 100 = 5 stars."],
      ["album_rating", "Song info", key("Album Rating"),
       "The star rating for the whole album, from 0 to 100 (20 per star)."],
      ["sort_name", "Song info", key("Sort Name"),
       "If set, the title iTunes uses when sorting alphabetically instead of the real one (e.g. to ignore \"The\"). Usually empty."],
      ["sort_artist", "Song info", key("Sort Artist"),
       "If set, the artist name iTunes uses when sorting, e.g. \"Beatles\" for \"The Beatles\". Usually empty."],
      ["sort_album_artist", "Song info", key("Sort Album Artist"),
       "If set, the album artist name iTunes uses when sorting. Usually empty."],
      ["sort_album", "Song info", key("Sort Album"),
       "If set, the album name iTunes uses when sorting. Usually empty."],
      ["sort_composer", "Song info", key("Sort Composer"),
       "If set, the composer name iTunes uses when sorting. Usually empty."],

      # File and technical
      ["location", "File and technical", key("Location"),
       "Where the song's file is, written as a web-style address (file://...) with spaces shown as %20."],
      ["location_path", "File and technical", method(:location_path),
       "Where the song's file is, as a normal folder path, e.g. C:/Users/You/Music/song.mp3."],
      ["kind", "File and technical", key("Kind"),
       "The type of audio file, e.g. \"MPEG audio file\" (an MP3) or \"AAC audio file\"."],
      ["size", "File and technical", key("Size"),
       "How big the file is, in bytes (1,000,000 bytes is about 1 MB)."],
      ["bit_rate", "File and technical", key("Bit Rate"),
       "The audio quality in kbps. Higher means better sound and bigger files; 256 or 320 is high quality."],
      ["sample_rate", "File and technical", key("Sample Rate"),
       "A technical audio detail in Hz. Usually 44100, which is CD quality."],
      ["date_modified", "File and technical", key("Date Modified"),
       "When the song's file or details were last changed."],
      ["track_type", "File and technical", key("Track Type"),
       "Where the song lives: \"File\" for a file on your computer, or \"URL\" / \"Remote\" for streams and cloud songs."],
      ["purchased?", "File and technical", flag("Purchased"),
       "Whether the song was bought from the iTunes Store."],
      ["protected?", "File and technical", flag("Protected"),
       "Whether the file is copy-protected so it only plays in iTunes. Common for songs bought before 2009."],
      ["artwork_count", "File and technical", key("Artwork Count"),
       "How many pictures (such as album covers) are attached to the song."],
      ["volume_adjustment", "File and technical", key("Volume Adjustment"),
       "The volume setting from the song's Options, from -255 (quietest) to 255 (loudest). 0 or empty means no change."],
      ["equalizer", "File and technical", key("Equalizer"),
       "The equalizer preset chosen for this song, e.g. \"Rock\". Usually empty."],
      ["start_time", "File and technical", key("Start Time"),
       "If you set the song to start partway in, where it starts, in milliseconds (1000 = 1 second)."],
      ["stop_time", "File and technical", key("Stop Time"),
       "If you set the song to stop early, where it stops, in milliseconds (1000 = 1 second)."],
      ["id", "File and technical", key("Track ID"),
       "A number iTunes uses for the song in this file. It can change if the library is rebuilt, so don't rely on it."],
      ["persistent_id", "File and technical", key("Persistent ID"),
       "A code iTunes uses to identify the song. It never changes, so it's useful for matching songs between exports."],

      # Play status flags
      ["played?", "Play status flags", ->(t) { t.played? },
       "Whether you've played the song at least once."],
      ["unplayed?", "Play status flags", ->(t) { t.unplayed? },
       "The opposite of played?: true if you've never played the song, or it's marked as unplayed."],
      ["disabled?", "Play status flags", flag("Disabled"),
       "Whether the song's tick box is unticked in iTunes, which makes iTunes skip it when playing through a list."],

      # Rating details
      ["rating_computed?", "Rating details", flag("Rating Computed"),
       "True if the song's stars weren't set by you, but filled in by iTunes from the album's rating."],
      ["album_rating_computed?", "Rating details", flag("Album Rating Computed"),
       "True if the album's stars weren't set by you, but worked out by iTunes from its songs' ratings."],
      ["loved?", "Rating details", flag("Loved"),
       "Whether you've marked the song with a heart (\"Love\"). Used by older versions of iTunes."],
      ["favorited?", "Rating details", flag("Favorited"),
       "Whether you've marked the song as a Favorite. Used by newer versions of iTunes instead of Love."],
      ["disliked?", "Rating details", flag("Disliked"),
       "Whether you've marked the song as \"Dislike\", so iTunes plays it less."],

      # Other media types
      ["audio?", "Other media types", ->(t) { t.audio? },
       "Whether the item is audio rather than video. Always true for songs."],
      ["video?", "Other media types", flag("Has Video"),
       "Whether the item has video, e.g. a music video."],
      ["movie?", "Other media types", flag("Movie"),
       "Whether the item is a movie. Normally false, as only music is exported."],
      ["tv_show?", "Other media types", flag("TV Show"),
       "Whether the item is a TV show. Normally false, as only music is exported."],
      ["podcast?", "Other media types", flag("Podcast"),
       "Whether the item is a podcast. Normally false, as only music is exported."],
      ["audiobook?", "Other media types", ->(t) { t.audiobook? },
       "Whether the item is an Audible audiobook. Normally false, as only music is exported."],
    ].map { |name, section, reader, description| Field.new(name, section, description, reader).freeze }.freeze

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

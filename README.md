# iTunes CSV

Export iTunes Library XML data to CSV

# Why?

I wanted to do a clean-up of my library. iTunes allows you to copy and paste from iTunes into a spreadsheet, but this only includes visible columns. For non-visible columns such as location you need to parse the XML.

## Windows app (no command line needed)

There is a simple window for exporting without typing any commands:

1. Install Ruby from [rubyinstaller.org](https://rubyinstaller.org/). The recommended
   download with the default options is fine.
2. On this project's GitHub page, click **Code → Download ZIP**, and unzip it anywhere.
3. Double-click **`itunes_csv_gui.bat`** in the unzipped folder.

The first time, a black window appears for a minute while it installs the parts it needs
(this needs an internet connection). After that it opens straight away.

In the window:

1. **iTunes library file**: this is filled in automatically if your library is in the usual
   place. Otherwise click **Browse…** and choose your `iTunes Library.xml` file
   (see [Where it looks for your library](#where-it-looks-for-your-library)).
2. **Fields to include**: tick the columns you want in the spreadsheet. They are grouped into
   sections. Hover over a field to see what it contains, or see [Fields](#fields) below.
   **Select all** and **Select none** tick or clear them all.
3. Click **Export CSV…**, choose where to save the file, and it tells you how many tracks were
   exported. The CSV opens in Excel or any spreadsheet program.

Exporting a very large library (tens of thousands of tracks) can take ten seconds or more.

You can also start the window from a terminal with `bundle exec ruby bin/itunes_csv_gui`.

## Command line installation

    $ gem install itunes_csv

Note: this installs the original version from rubygems.org, which does not include the
changes in this fork. To use this version from the command line, download it as above and
run `bundle install`, then `bundle exec ruby bin/itunes_csv` from its folder.

## Command line usage

    $ itunes_csv --help
    Usage: itunes_csv [options]
        -f, --fields a,b,c               List of fields (default: name,artist)
        -p, --path PATH                  Path to iTunes XML file (default: first found of ~/Music/iTunes/iTunes Library.xml, ~/Music/iTunes/iTunes Music Library.xml)
        -o, --output FILE                Output to FILE instead of stdout (default: stdout)

Examples:

    $ itunes_csv -f name,artist,album,location -o library.csv
    $ itunes_csv -p "D:/Backups/iTunes Library.xml" -f name,play_count

### Where it looks for your library

If `--path` is not given, `itunes_csv` looks in the `Music/iTunes` folder under your home
folder (`C:\Users\<you>\Music\iTunes\` on Windows, `~/Music/iTunes/` on macOS). It tries
`iTunes Library.xml` first, then the older name `iTunes Music Library.xml`. If neither exists
it tells you where it looked.

iTunes only writes this XML file if sharing is turned on: *Edit > Preferences > Advanced >
Share iTunes Library XML with other applications* (on macOS, *iTunes > Preferences > Advanced*).

### Errors

If you ask for a field that does not exist, `itunes_csv` lists the valid fields and exits with
a non-zero status before reading the library. Error messages go to stderr, so they never end up
in your CSV.

## Fields

These are all the fields you can export, in the same sections as the checkboxes in the
Windows app. On the command line, pass the names to `--fields`, separated by commas.

Only music is exported (tracks in iTunes' Music playlist). iTunes leaves a property out
of its XML file when it has no value: those cells are left empty, except for fields ending
in `?`, which are `false`, and `play_count` / `skip_count`, which are `0`. Which properties
exist also depends on your iTunes version (for example, newer versions use `favorited?`
where older ones use `loved?`).

### Song info

| Field | What it is |
|---|---|
| `name` | The song's title. |
| `artist` | The singer or band. |
| `album_artist` | The main artist for the whole album, e.g. "Various Artists" on a compilation. Often empty if it's the same as the artist. |
| `album` | The name of the album the song is on. |
| `composer` | Who wrote the song. |
| `genre` | The style of music, e.g. Rock or Pop. |
| `grouping` | A label you can type in to group songs together, e.g. "Wedding". Usually empty. |
| `year` | The year the song came out. |
| `release_date` | The full date the song came out. Usually only filled in for songs from the iTunes Store. |
| `number` | The song's position on the album (its track number). |
| `track_count` | How many tracks are on the album or disc (the "12" in "track 3 of 12"). |
| `disc_number` | Which disc the song is on, for albums with more than one CD. |
| `disc_count` | How many discs the album has (the "2" in "disc 1 of 2"). |
| `compilation?` | Whether the song is on a "various artists" style album, such as a soundtrack or a greatest-hits collection. |
| `total_time` | How long the song is, in seconds (e.g. 245 = 4 minutes 5 seconds). |
| `bpm` | How fast the song is, in beats per minute. Usually empty unless you or another app filled it in. |
| `comments` | Any notes typed into the song's Comments box. |
| `work` | For classical music: the name of the whole piece, e.g. "Symphony No. 5". |
| `movement_name` | For classical music: the name of this part of the piece, e.g. "Allegro con brio". |
| `movement_number` | For classical music: which part of the piece this is (1, 2, 3...). |
| `movement_count` | For classical music: how many parts the whole piece has. |
| `explicit?` | Whether the song is marked as having explicit lyrics. |
| `content_rating` | An age rating stored with the song, if there is one. Usually empty for music. |
| `date_added` | When the song was added to your iTunes library. |
| `play_count` | How many times you've played the song. |
| `last_played_at` | When you last played the song. |
| `skip_count` | How many times you skipped the song soon after it started. |
| `last_skipped_at` | When you last skipped the song. |
| `rating` | Your star rating for the song, from 0 to 100: 20 = 1 star, 40 = 2 stars, up to 100 = 5 stars. |
| `album_rating` | The star rating for the whole album, from 0 to 100 (20 per star). |
| `sort_name` | If set, the title iTunes uses when sorting alphabetically instead of the real one (e.g. to ignore "The"). Usually empty. |
| `sort_artist` | If set, the artist name iTunes uses when sorting, e.g. "Beatles" for "The Beatles". Usually empty. |
| `sort_album_artist` | If set, the album artist name iTunes uses when sorting. Usually empty. |
| `sort_album` | If set, the album name iTunes uses when sorting. Usually empty. |
| `sort_composer` | If set, the composer name iTunes uses when sorting. Usually empty. |

### File and technical

| Field | What it is |
|---|---|
| `location` | Where the song's file is, written as a web-style address (file://...) with spaces shown as %20. |
| `location_path` | Where the song's file is, as a normal folder path, e.g. C:/Users/You/Music/song.mp3. |
| `kind` | The type of audio file, e.g. "MPEG audio file" (an MP3) or "AAC audio file". |
| `size` | How big the file is, in bytes (1,000,000 bytes is about 1 MB). |
| `bit_rate` | The audio quality in kbps. Higher means better sound and bigger files; 256 or 320 is high quality. |
| `sample_rate` | A technical audio detail in Hz. Usually 44100, which is CD quality. |
| `date_modified` | When the song's file or details were last changed. |
| `track_type` | Where the song lives: "File" for a file on your computer, or "URL" / "Remote" for streams and cloud songs. |
| `purchased?` | Whether the song was bought from the iTunes Store. |
| `protected?` | Whether the file is copy-protected so it only plays in iTunes. Common for songs bought before 2009. |
| `artwork_count` | How many pictures (such as album covers) are attached to the song. |
| `volume_adjustment` | The volume setting from the song's Options, from -255 (quietest) to 255 (loudest). 0 or empty means no change. |
| `equalizer` | The equalizer preset chosen for this song, e.g. "Rock". Usually empty. |
| `start_time` | If you set the song to start partway in, where it starts, in milliseconds (1000 = 1 second). |
| `stop_time` | If you set the song to stop early, where it stops, in milliseconds (1000 = 1 second). |
| `id` | A number iTunes uses for the song in this file. It can change if the library is rebuilt, so don't rely on it. |
| `persistent_id` | A code iTunes uses to identify the song. It never changes, so it's useful for matching songs between exports. |

### Play status flags

| Field | What it is |
|---|---|
| `played?` | Whether you've played the song at least once. |
| `unplayed?` | The opposite of played?: true if you've never played the song, or it's marked as unplayed. |
| `disabled?` | Whether the song's tick box is unticked in iTunes, which makes iTunes skip it when playing through a list. |

### Rating details

| Field | What it is |
|---|---|
| `rating_computed?` | True if the song's stars weren't set by you, but filled in by iTunes from the album's rating. |
| `album_rating_computed?` | True if the album's stars weren't set by you, but worked out by iTunes from its songs' ratings. |
| `loved?` | Whether you've marked the song with a heart ("Love"). Used by older versions of iTunes. |
| `favorited?` | Whether you've marked the song as a Favorite. Used by newer versions of iTunes instead of Love. |
| `disliked?` | Whether you've marked the song as "Dislike", so iTunes plays it less. |

### Other media types

| Field | What it is |
|---|---|
| `audio?` | Whether the item is audio rather than video. Always true for songs. |
| `video?` | Whether the item has video, e.g. a music video. |
| `movie?` | Whether the item is a movie. Normally false, as only music is exported. |
| `tv_show?` | Whether the item is a TV show. Normally false, as only music is exported. |
| `podcast?` | Whether the item is a podcast. Normally false, as only music is exported. |
| `audiobook?` | Whether the item is an Audible audiobook. Normally false, as only music is exported. |

## Running the tests

    $ bundle install
    $ bundle exec rake

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

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
   sections, and [Fields](#fields) below explains each one. **Select all** and
   **Select none** tick or clear them all.
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
| `name` | Song title |
| `artist` | Artist |
| `album_artist` | Album artist |
| `album` | Album |
| `composer` | Composer |
| `genre` | Genre |
| `grouping` | Grouping |
| `year` | Year |
| `release_date` | Release date |
| `number` | Track number |
| `track_count` | Number of tracks on the disc (the "of 12" in "3 of 12") |
| `disc_number` | Disc number |
| `disc_count` | Number of discs (the "of 2" in "1 of 2") |
| `compilation?` | Part of a compilation album |
| `total_time` | Length in seconds |
| `bpm` | Beats per minute |
| `comments` | Comments |
| `work` | Work (classical music) |
| `movement_name` | Movement name (classical music) |
| `movement_number` | Movement number (classical music) |
| `movement_count` | Number of movements (classical music) |
| `explicit?` | Marked as explicit |
| `content_rating` | Content rating, as stored by iTunes |
| `date_added` | Date and time added to the library |
| `play_count` | Number of plays |
| `last_played_at` | Date and time last played |
| `skip_count` | Number of skips |
| `last_skipped_at` | Date and time last skipped |
| `rating` | Star rating, 0-100 (20 = 1 star, 100 = 5 stars) |
| `album_rating` | Album star rating, 0-100 |
| `sort_name` | Title used for sorting, if different |
| `sort_artist` | Artist used for sorting, if different |
| `sort_album_artist` | Album artist used for sorting, if different |
| `sort_album` | Album used for sorting, if different |
| `sort_composer` | Composer used for sorting, if different |

### File and technical

| Field | What it is |
|---|---|
| `location` | File location as a URL (file://localhost/...) |
| `location_path` | File location as a normal path |
| `kind` | File type, e.g. "MPEG audio file" or "AAC audio file" |
| `size` | File size in bytes |
| `bit_rate` | Bit rate in kbps, e.g. 256 |
| `sample_rate` | Sample rate in Hz, e.g. 44100 |
| `date_modified` | Date and time the file was last changed |
| `track_type` | Where the track lives, e.g. File, URL or Remote |
| `purchased?` | Bought from the iTunes Store |
| `protected?` | Copy-protected (DRM) |
| `artwork_count` | Number of artwork images attached |
| `volume_adjustment` | Volume adjustment set for this song (-255 to 255) |
| `equalizer` | Equalizer preset set for this song |
| `start_time` | Custom start time in milliseconds |
| `stop_time` | Custom stop time in milliseconds |
| `id` | iTunes' internal track number (can change if the library is rebuilt) |
| `persistent_id` | iTunes' permanent unique ID for the track |

### Play status flags

| Field | What it is |
|---|---|
| `played?` | Played at least once |
| `unplayed?` | Never played, or marked as unplayed in iTunes |
| `disabled?` | Unticked in iTunes (skipped when playing through) |

### Rating details

| Field | What it is |
|---|---|
| `rating_computed?` | Star rating was worked out by iTunes, not set by you |
| `album_rating_computed?` | Album rating was worked out by iTunes, not set by you |
| `loved?` | Loved (older iTunes versions) |
| `favorited?` | Favorited (newer iTunes versions) |
| `disliked?` | Disliked |

### Other media types

| Field | What it is |
|---|---|
| `audio?` | Audio (not video) |
| `video?` | Has video, e.g. a music video |
| `movie?` | Movie |
| `tv_show?` | TV show |
| `podcast?` | Podcast |
| `audiobook?` | Audiobook (Audible) |

## Running the tests

    $ bundle install
    $ bundle exec rake

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

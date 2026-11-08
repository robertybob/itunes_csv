# iTunes CSV

Export iTunes Library XML data to CSV

# Why?

I wanted to do a clean-up of my library. iTunes allows you to copy and paste from iTunes into a spreadsheet, but this only includes visible columns. For non-visible columns such as location you need to parse the XML.

## Installation

    $ gem install itunes_csv

## Usage

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

## Notes

May take a long time to run for a large iTunes library (10,000+ tracks)

Supported fields come from the itunes-library gem (`ITunes::Track`) and are:

 * album
 * album_rating
 * album_rating_computed?
 * artist
 * artwork_count
 * audio?
 * audiobook?
 * bit_rate
 * composer
 * date_added
 * episode_number
 * genre
 * id
 * kind
 * last_played_at
 * location
 * location_path
 * movie?
 * name
 * number
 * persistent_id
 * play_count
 * played?
 * podcast?
 * rating
 * rating_computed?
 * sample_rate
 * season_number
 * total_time
 * tv_show?
 * unplayed?
 * video?
 * year


## Running the tests

    $ bundle install
    $ bundle exec rake

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

require "itunes_csv/version"
require "itunes_csv/fields"
require "itunes/library"
require "csv"
require 'optparse'

module ItunesCsv
  # Where iTunes writes its library XML, checked in order when --path is not given.
  # On both Windows and macOS this lives under ~/Music/iTunes; newer versions of
  # iTunes name the file "iTunes Library.xml", older ones "iTunes Music Library.xml".
  DEFAULT_PATHS = [
    '~/Music/iTunes/iTunes Library.xml',
    '~/Music/iTunes/iTunes Music Library.xml',
  ].freeze

  # Names of every exportable field, in section order. See ItunesCsv::Fields.
  def self.valid_fields
    Fields.names
  end

  def self.default_path
    DEFAULT_PATHS.map { |p| File.expand_path(p) }.find { |p| File.file?(p) }
  end

  # Builds CSV text for the music tracks in the library at library_path, with
  # one column per field (in the given order) and a header row.
  # Returns [csv_string, track_count]. Raises ArgumentError for unknown fields
  # and Errno::ENOENT if the library file does not exist.
  def self.export(library_path, fields)
    fields = fields.map(&:to_s)
    unknown = fields - valid_fields
    raise ArgumentError, "Unknown field#{'s' if unknown.size > 1}: #{unknown.join(', ')}" unless unknown.empty?
    raise ArgumentError, "No fields selected" if fields.empty?
    raise Errno::ENOENT, library_path unless File.file?(library_path)

    library = ITunes::Library.load(library_path)
    columns = fields.map { |f| Fields[f] }
    count = 0

    csv_string = CSV.generate do |csv|
      csv << fields
      library.music.tracks.each do |t|
        csv << columns.map { |c| c.value(t) }
        count += 1
      end
    end

    [csv_string, count]
  end

  class CommandLine
    # Returns a process exit status (0 on success) so callers and tests can check it.
    def self.invoke(args, out: $stdout, err: $stderr)
      options = { fields: ['name', 'artist'], path: nil, output: nil }

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: itunes_csv [options]"

        opts.on( '-f', '--fields a,b,c', Array, "List of fields (default: #{options[:fields].join(',')})" ) do |list|
          options[:fields] = list
        end

        opts.on( '-p', '--path PATH', "Path to iTunes XML file (default: first found of #{DEFAULT_PATHS.join(', ')})" ) do |path|
          options[:path] = path
        end

        opts.on( '-o', '--output FILE', "Output to FILE instead of stdout (default: stdout)" ) do |file|
          options[:output] = file
        end
      end

      begin
        opts.parse!(args)
      rescue OptionParser::ParseError => e
        err.puts e.message
        err.puts opts
        return 1
      end

      unknown = options[:fields] - ItunesCsv.valid_fields
      unless unknown.empty?
        err.puts "Unknown field#{'s' if unknown.size > 1}: #{unknown.join(', ')}"
        err.puts "Valid fields: #{ItunesCsv.valid_fields.join(', ')}"
        return 1
      end

      library_path = options[:path] ? File.expand_path(options[:path]) : ItunesCsv.default_path
      if library_path.nil?
        err.puts "Could not find an iTunes library XML file. Looked in:"
        DEFAULT_PATHS.each { |p| err.puts "  #{File.expand_path(p)}" }
        err.puts "Use --path to point at your library file."
        return 1
      elsif !File.file?(library_path)
        err.puts "iTunes library file not found: #{library_path}"
        return 1
      end

      csv_string, _count = ItunesCsv.export(library_path, options[:fields])

      if options[:output]
        File.write(options[:output], csv_string)
        out.puts "CSV written to #{options[:output]}"
      else
        out.puts csv_string
      end

      0
    end
  end
end

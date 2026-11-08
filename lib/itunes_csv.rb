require "itunes_csv/version"
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

  # Track methods that are not exportable fields.
  NON_FIELD_METHODS = [:[], :to_hash, :inspect].freeze

  def self.valid_fields
    (ITunes::Track.public_instance_methods(false) - NON_FIELD_METHODS).map(&:to_s).sort
  end

  def self.default_path
    DEFAULT_PATHS.map { |p| File.expand_path(p) }.find { |p| File.file?(p) }
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

      library = ITunes::Library.load(library_path)
      fields = options[:fields].map(&:to_sym)

      csv_string = CSV.generate do |csv|
        csv << options[:fields]
        library.music.tracks.each do |t|
          csv << fields.map { |f| t.send(f) }
        end
      end

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

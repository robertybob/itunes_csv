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

  def self.default_path
    DEFAULT_PATHS.map { |p| File.expand_path(p) }.find { |p| File.file?(p) }
  end

  class CommandLine
    def self.invoke(args)
      options = {}

      opts = OptionParser.new do |opts|
        options[:fields] = ['name', 'artist']
        opts.on( '-f', '--fields a,b,c', Array, "List of fields (default: #{options[:fields].join(',')})" ) do |list|
          options[:fields] = list
        end

        options[:path] = nil
        opts.on( '-p', '--path PATH', "Path to iTunes XML file (default: first found of #{DEFAULT_PATHS.join(', ')})" ) do |path|
          options[:path] = path
        end

        options[:output] = nil
        opts.on( '-o', '--output FILE', "Output to FILE instead of stdout (default: stdout)" ) do |file|
          options[:output] = file
        end
      end

      opts.parse!(args)

      library_path = options[:path] ? File.expand_path(options[:path]) : ItunesCsv.default_path
      if library_path.nil?
        $stderr.puts "Could not find an iTunes library XML file. Looked in:"
        DEFAULT_PATHS.each { |p| $stderr.puts "  #{File.expand_path(p)}" }
        $stderr.puts "Use --path to point at your library file."
        exit 1
      elsif !File.file?(library_path)
        $stderr.puts "iTunes library file not found: #{library_path}"
        exit 1
      end

      library = ITunes::Library.load(library_path)

      csv_string = CSV.generate do |csv|
        csv << options[:fields]
        library.music.tracks.each do |t|
          row = options[:fields].map do |f|
            unless t.respond_to?(f.to_sym)
              puts "Unknown field: #{f}"
              exit
            end
            t.send(f.to_sym)
          end
          csv << row
        end
      end

      if options[:output]
        File.write(options[:output], csv_string)
        puts "CSV written to #{options[:output]}"
      else
        puts csv_string
      end
    end
  end
end

require "fiddle"
require "fiddle/import"

module ItunesCsv
  # Open and Save dialogs that only offer the right kind of file. LibUI's own
  # dialogs can't filter by file type, so on Windows (64-bit Ruby) these use
  # the standard Windows dialogs directly. Elsewhere they return :unsupported
  # and the GUI falls back to LibUI's dialogs.
  module FileDialogs
    MAX_PATH_CHARS = 32_768

    def self.supported?
      Gem.win_platform? && Fiddle::SIZEOF_VOIDP == 8
    end

    # Asks for an iTunes library XML file. Returns the path, nil if cancelled,
    # or :unsupported.
    def self.open_xml(owner_hwnd, initial_dir: nil)
      show(:open, owner_hwnd,
           filter: [["iTunes library XML (*.xml)", "*.xml"]],
           initial_dir: initial_dir,
           flags: Win32::OFN_FILEMUSTEXIST | Win32::OFN_PATHMUSTEXIST)
    end

    # Asks where to save a CSV file; ".csv" is added if no extension is typed.
    # Returns the path, nil if cancelled, or :unsupported.
    def self.save_csv(owner_hwnd, initial_name: "iTunes export.csv")
      show(:save, owner_hwnd,
           filter: [["CSV file (*.csv)", "*.csv"]],
           initial_name: initial_name,
           default_ext: "csv",
           flags: Win32::OFN_OVERWRITEPROMPT | Win32::OFN_PATHMUSTEXIST)
    end

    def self.show(kind, owner_hwnd, filter:, flags:, initial_dir: nil, initial_name: nil, default_ext: nil)
      return :unsupported unless supported?

      keep = [] # buffers must stay alive until the dialog closes
      w = ->(s) { wide(s).tap { |p| keep << p } }

      # The filter is pairs of "description\0pattern\0", ending with an extra \0.
      filter_ptr = w.(filter.map { |desc, pattern| "#{desc}\0#{pattern}\0" }.join)

      file_buf = Fiddle::Pointer.malloc(MAX_PATH_CHARS * 2, Fiddle::RUBY_FREE)
      keep << file_buf
      start = (initial_name.to_s.tr("/", "\\").encode("UTF-16LE") + "\0".encode("UTF-16LE")).b
      file_buf[0, MAX_PATH_CHARS * 2] = "\0" * (MAX_PATH_CHARS * 2)
      file_buf[0, start.bytesize] = start

      ofn = Fiddle::Pointer.malloc(Win32::OFN_SIZE, Fiddle::RUBY_FREE)
      ofn[0, Win32::OFN_SIZE] = "\0" * Win32::OFN_SIZE
      put = ->(offset, format, value) { ofn[offset, [value].pack(format).bytesize] = [value].pack(format) }
      put.(0,   "L", Win32::OFN_SIZE)        # lStructSize
      put.(8,   "Q", owner_hwnd.to_i)        # hwndOwner
      put.(24,  "Q", filter_ptr.to_i)        # lpstrFilter
      put.(44,  "L", 1)                      # nFilterIndex
      put.(48,  "Q", file_buf.to_i)          # lpstrFile
      put.(56,  "L", MAX_PATH_CHARS)         # nMaxFile
      put.(80,  "Q", w.(initial_dir.tr("/", "\\")).to_i) if initial_dir && File.directory?(initial_dir) # lpstrInitialDir
      put.(96,  "L", flags | Win32::OFN_EXPLORER | Win32::OFN_HIDEREADONLY | Win32::OFN_NOCHANGEDIR) # Flags
      put.(104, "Q", w.(default_ext).to_i) if default_ext # lpstrDefExt

      ok = kind == :open ? Win32.GetOpenFileNameW(ofn) : Win32.GetSaveFileNameW(ofn)
      return nil if ok.zero?

      file_buf[0, MAX_PATH_CHARS * 2].force_encoding("UTF-16LE").encode("UTF-8").split("\0", 2).first
    end

    def self.wide(string)
      bytes = (string.encode("UTF-16LE") + "\0".encode("UTF-16LE")).b
      ptr = Fiddle::Pointer.malloc(bytes.bytesize, Fiddle::RUBY_FREE)
      ptr[0, bytes.bytesize] = bytes
      ptr
    end
    private_class_method :show, :wide

    module Win32
      if FileDialogs.supported?
        extend Fiddle::Importer
        dlload "comdlg32.dll"
        extern "int GetOpenFileNameW(void*)"
        extern "int GetSaveFileNameW(void*)"
      end

      OFN_OVERWRITEPROMPT = 0x00000002
      OFN_HIDEREADONLY    = 0x00000004
      OFN_NOCHANGEDIR     = 0x00000008
      OFN_PATHMUSTEXIST   = 0x00000800
      OFN_FILEMUSTEXIST   = 0x00001000
      OFN_EXPLORER        = 0x00080000
      # sizeof(OPENFILENAMEW) on 64-bit Windows.
      OFN_SIZE            = 152
    end
  end
end

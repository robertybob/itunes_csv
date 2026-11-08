require "fiddle"
require "fiddle/import"

module ItunesCsv
  # Hover tooltips for GUI controls. LibUI has no tooltip support, so on
  # Windows this creates a standard Windows tooltip control and attaches it to
  # the native window behind each LibUI control. On other systems it does
  # nothing, and the GUI simply has no tooltips.
  class Tooltips
    # Wraps tooltip text at this width, in pixels, instead of one long line.
    MAX_WIDTH = 320
    # How long a tooltip stays up while the mouse rests on the control, in ms.
    SHOW_FOR = 30_000

    # Windows with 64-bit Ruby (the RubyInstaller default), which the
    # TOOLINFO layout below is written for.
    def self.supported?
      Gem.win_platform? && Fiddle::SIZEOF_VOIDP == 8
    end

    # owner_hwnd: native handle of the window the controls are in.
    def initialize(owner_hwnd)
      @texts = [] # keep tooltip strings alive while the window is open
      return unless self.class.supported?

      @tooltip = Win32.CreateWindowExW(
        Win32::WS_EX_TOPMOST, wide("tooltips_class32"), nil,
        Win32::WS_POPUP | Win32::TTS_ALWAYSTIP | Win32::TTS_NOPREFIX,
        Win32::CW_USEDEFAULT, Win32::CW_USEDEFAULT, Win32::CW_USEDEFAULT, Win32::CW_USEDEFAULT,
        owner_hwnd, 0, 0, nil
      )
      return if @tooltip.zero?

      Win32.SendMessageW(@tooltip, Win32::TTM_SETMAXTIPWIDTH, 0, MAX_WIDTH)
      Win32.SendMessageW(@tooltip, Win32::TTM_SETDELAYTIME, Win32::TTDT_AUTOPOP, SHOW_FOR)
    end

    # Shows text when the mouse rests on the control with native handle hwnd.
    # Call this once the control has been placed in the window.
    def add(hwnd, text)
      return false unless @tooltip && !@tooltip.zero?

      text_ptr = wide(text)
      @texts << text_ptr

      info = Fiddle::Pointer.malloc(Win32::TOOLINFO_SIZE, Fiddle::RUBY_FREE)
      info[0, Win32::TOOLINFO_SIZE] = "\0" * Win32::TOOLINFO_SIZE
      info[0, 4]  = [Win32::TOOLINFO_SIZE].pack("L")
      info[4, 4]  = [Win32::TTF_IDISHWND | Win32::TTF_SUBCLASS].pack("L")
      info[8, 8]  = [Win32.GetParent(hwnd)].pack("Q") # window containing the control
      info[16, 8] = [hwnd].pack("Q")                  # the control itself
      info[48, 8] = [text_ptr.to_i].pack("Q")         # the text
      Win32.SendMessageW(@tooltip, Win32::TTM_ADDTOOLW, 0, info.to_i) != 0
    end

    private

    # A NUL-terminated UTF-16 string, as Windows' wide-character functions expect.
    def wide(string)
      bytes = (string.encode("UTF-16LE") + "\0".encode("UTF-16LE")).b
      ptr = Fiddle::Pointer.malloc(bytes.bytesize, Fiddle::RUBY_FREE)
      ptr[0, bytes.bytesize] = bytes
      ptr
    end

    module Win32
      if Gem.win_platform?
        extend Fiddle::Importer
        dlload "user32.dll"
        extern "uintptr_t CreateWindowExW(unsigned long, void*, void*, unsigned long, int, int, int, int, uintptr_t, uintptr_t, uintptr_t, void*)"
        extern "intptr_t SendMessageW(uintptr_t, unsigned int, uintptr_t, intptr_t)"
        extern "uintptr_t GetParent(uintptr_t)"
      end

      WS_POPUP          = 0x80000000
      WS_EX_TOPMOST     = 0x00000008
      CW_USEDEFAULT     = -0x80000000
      TTS_ALWAYSTIP     = 0x01
      TTS_NOPREFIX      = 0x02
      TTF_IDISHWND      = 0x0001
      TTF_SUBCLASS      = 0x0010
      WM_USER           = 0x0400
      TTM_SETDELAYTIME  = WM_USER + 3
      TTM_SETMAXTIPWIDTH = WM_USER + 24
      TTM_ADDTOOLW      = WM_USER + 50
      TTDT_AUTOPOP      = 2
      # The 64-bit TOOLINFOW layout up to and including lParam, which every
      # version of the Windows tooltip control accepts.
      TOOLINFO_SIZE     = 64
    end
  end
end

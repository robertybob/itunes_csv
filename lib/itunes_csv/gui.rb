require "itunes_csv"
require "itunes_csv/tooltips"

begin
  require "libui"
rescue LoadError
  abort "The itunes_csv GUI needs the libui gem. Install it with:  gem install libui"
end

module ItunesCsv
  # A small desktop window for exporting an iTunes library to CSV:
  # pick the library file, tick the fields you want, and click Export.
  class Gui
    UI = LibUI
    COLUMNS = 5
    DEFAULT_FIELDS = %w[name artist].freeze

    def self.run
      new.run
    end

    def run
      init_error = UI.init
      raise "Could not start the GUI: #{init_error}" unless init_error.nil?

      build_window
      UI.control_show(@window)
      add_tooltips
      main_loop
    ensure
      UI.uninit if init_error.nil?
    end

    private

    # Hovering over a field shows its description (Windows only). Done after
    # the window is shown, once each checkbox is in its final place.
    def add_tooltips
      @tooltips = Tooltips.new(UI.control_handle(@window))
      @checkboxes.each do |name, checkbox|
        @tooltips.add(UI.control_handle(checkbox), ItunesCsv::Fields[name].description)
      end
    rescue StandardError, Fiddle::DLError
      # Tooltips are a nice-to-have; never let them stop the window opening.
    end

    def build_window
      @window = UI.new_window("iTunes CSV Export", 900, 600, 0)
      UI.window_set_margined(@window, 1)
      UI.window_on_closing(@window) do
        UI.quit
        1
      end

      layout = UI.new_vertical_box
      UI.box_set_padded(layout, 1)
      UI.window_set_child(@window, layout)

      UI.box_append(layout, library_group, 0)
      UI.box_append(layout, fields_group, 1)
      UI.box_append(layout, export_row, 0)
    end

    def library_group
      group = UI.new_group("1. iTunes library file")
      UI.group_set_margined(group, 1)

      row = UI.new_horizontal_box
      UI.box_set_padded(row, 1)

      @path_entry = UI.new_entry
      UI.entry_set_text(@path_entry, ItunesCsv.default_path.to_s.tr("/", "\\"))
      UI.box_append(row, @path_entry, 1)

      browse = UI.new_button("Browse…")
      UI.button_on_clicked(browse) do
        path = take_string(UI.open_file(@window))
        UI.entry_set_text(@path_entry, path) if path
      end
      UI.box_append(row, browse, 0)

      UI.group_set_child(group, row)
      group
    end

    # Where each section goes in the checkbox grid: one row of sections per
    # entry, each section given as [name, first column, number of columns].
    # The three small sections share a row to keep the window short.
    LAYOUT = [
      [["Song info", 0, COLUMNS]],
      [["File and technical", 0, COLUMNS]],
      [["Play status flags", 0, 1], ["Rating details", 1, 2], ["Other media types", 3, 2]],
    ].freeze

    def fields_group
      box = UI.new_vertical_box
      UI.box_set_padded(box, 1)

      header = UI.new_horizontal_box
      UI.box_set_padded(header, 1)
      UI.box_append(header, UI.new_label("2. Fields to include"), 1)
      select_all = UI.new_button("Select all")
      UI.button_on_clicked(select_all) { set_all_checked(1) }
      select_none = UI.new_button("Select none")
      UI.button_on_clicked(select_none) { set_all_checked(0) }
      UI.box_append(header, select_all, 0)
      UI.box_append(header, select_none, 0)
      UI.box_append(box, header, 0)

      # All sections share one grid so their columns line up.
      @grid = UI.new_grid
      UI.grid_set_padded(@grid, 1)
      @checkboxes = {}
      top = 0
      LAYOUT.each do |sections|
        grid_add(UI.new_horizontal_separator, 0, top, COLUMNS)
        top += 1
        sections.each { |name, left, width| grid_add(UI.new_label(name), left, top, width) }
        top += 1
        top += sections.map { |name, left, width| add_checkboxes(name, left, top, width) }.max
      end
      UI.box_append(box, @grid, 1)
      box
    end

    # Adds a section's checkboxes to the grid, filling down each column first so
    # they read in the same order as the README table. Returns the rows used.
    def add_checkboxes(section, left, top, width)
      fields = ItunesCsv::Fields.in_section(section)
      rows = (fields.size + width - 1) / width
      fields.each_with_index do |field, i|
        checkbox = UI.new_checkbox(field.name)
        UI.checkbox_set_checked(checkbox, DEFAULT_FIELDS.include?(field.name) ? 1 : 0)
        grid_add(checkbox, left + i / rows, top + i % rows)
        @checkboxes[field.name] = checkbox
      end
      rows
    end

    def grid_add(control, left, top, width = 1)
      UI.grid_append(@grid, control, left, top, width, 1, 1, UI::AlignFill, 0, UI::AlignFill)
    end

    def export_row
      row = UI.new_horizontal_box
      UI.box_set_padded(row, 1)

      @status = UI.new_label("")
      UI.box_append(row, @status, 1)

      @export_button = UI.new_button("Export CSV…")
      UI.button_on_clicked(@export_button) { start_export }
      UI.box_append(row, @export_button, 0)
      row
    end

    def set_all_checked(value)
      @checkboxes.each_value { |c| UI.checkbox_set_checked(c, value) }
    end

    def selected_fields
      @checkboxes.select { |_field, c| UI.checkbox_checked(c) == 1 }.keys
    end

    def start_export
      library_path = take_string(UI.entry_text(@path_entry)).to_s.strip
      fields = selected_fields

      if library_path.empty?
        return error("No library file", "Choose your iTunes Library XML file first (use Browse…).")
      elsif !File.file?(library_path)
        return error("Library file not found", "Could not find:\n#{library_path}")
      elsif fields.empty?
        return error("No fields selected", "Tick at least one field to include in the CSV.")
      end

      output_path = ask_save_path
      return if output_path.nil?

      UI.control_disable(@export_button)
      UI.label_set_text(@status, "Exporting… (large libraries can take a while)")

      # Export in the background so the window stays responsive. The main loop
      # gives this thread time to run; UI updates go back via queue_main.
      Thread.new do
        begin
          csv_string, count = ItunesCsv.export(library_path, fields)
          File.write(output_path, csv_string)
          on_ui_thread do
            finish("Exported #{count} tracks.")
            UI.msg_box(@window, "Export complete", "Exported #{count} tracks to:\n#{output_path}")
          end
        rescue StandardError => e
          on_ui_thread do
            finish("Export failed.")
            error("Export failed", e.message)
          end
        end
      end
    end

    # Shows the Save dialog. Returns the chosen path (with .csv added if it has
    # no extension), or nil if the user cancelled.
    def ask_save_path
      path = take_string(UI.save_file(@window))
      return nil if path.nil? || path.empty?
      File.extname(path).empty? ? "#{path}.csv" : path
    end

    def finish(status_text)
      UI.label_set_text(@status, status_text)
      UI.control_enable(@export_button)
    end

    def error(title, message)
      UI.msg_box_error(@window, title, message)
    end

    def on_ui_thread(&block)
      UI.queue_main do
        block.call
        nil
      end
    end

    # Runs the event loop by hand so Ruby background threads (the export) get
    # CPU time between UI events. Returns when the window is closed.
    def main_loop
      UI.main_steps
      while UI.main_step(0) != 0
        sleep 0.01
      end
    end

    # Converts a char* returned by libui into a Ruby string and frees it.
    def take_string(pointer)
      return nil if pointer.nil? || pointer.null?
      string = pointer.to_s.dup.force_encoding(Encoding::UTF_8)
      UI.free_text(pointer)
      string
    end
  end
end

require_relative 'helpers'

module SeeAsVee
  class Sheet
    CELL_ERROR_MARKER = '⚑ '.freeze
    CELL_ERROR_STYLE = {
      bg_color: 'FF880000',
      fg_color: 'FFFFFFFF',
      sz: 14,
      border: { style: :thin, color: 'FFFF0000' }
    }.freeze
    WORK_SHEET_NAME = 'Processing errors shown in red'.freeze
    LEAVE_ERROR_MARKER = true

    attr_reader :rows, :formatters, :checkers

    def initialize whatever, formatters: {}, checkers: {}, skip_blank_rows: false
      @formatters = formatters.map { |k, v| [str_to_sym(k), v] }.to_h
      @checkers = checkers.map { |k, v| [str_to_sym(k), v] }.to_h
      @rows = whatever.is_a?(Array) ? whatever : Helpers.harvest_csv(whatever)

      @rows = @rows.map do |row|
        row unless skip_blank_rows && row.compact.empty?
      end.compact.map.with_index do |row, idx|
        idx.zero? ? row : plough_row(row)
      end
    end

    def values
      @rows[1..-1]
    end

    def headers symbolic = false
      headers = @rows.first
      unless headers.uniq.length == headers.length
        groups = headers.group_by { |h| h }.select { |_, group| group.size > 1 }
        headers = headers.map.with_index { |e, idx| groups[e].nil? ? e : "#{e} #{idx}" }
      end

      headers = headers.map.with_index { |s, ind| str_to_sym(s || "col #{ind}") } if symbolic
      headers
    end

    def [] index, key = nil
      key.nil? ? values[index] : values[index][header_index(key)]
    end

    def each
      return enum_for unless block_given?

      values.each_with_index do |row, idx|
        result = headers.zip(row).to_h
        errors = result.select { |_, v| malformed?(v) }
        yield idx, errors, result
      end
    end

    def map
      return enum_for unless block_given?

      values.map do |row|
        yield headers(true).zip(row).to_h
      end
    end

    def produce csv: true, xlsx: nil, **params
      [csv && produce_csv(**params), xlsx && produce_xlsx(**params)]
    end

    private

    def malformed? str
      str.to_s.start_with? CELL_ERROR_MARKER
    end

    def produce_csv **params
      Tempfile.new(['see_as_vee', '.csv']).tap do |f|
        CSV.open(f.path, "wb", params) do |content|
          @rows.each { |row| content << row }
        end unless @rows.empty?
      end
    end

    def produce_xlsx **params
      params, axlsx_params = split_params(params)
      Tempfile.new(['see_as_vee', '.xlsx']).tap do |f|
        Axlsx::Package.new do |p|
          red = p.workbook.styles.add_style(**params[:ces]) if params[:ces].is_a?(Hash)
          p.workbook.add_worksheet(**axlsx_params) do |sheet|
            @rows.each do |row|
              styles = row.map { |cell| malformed?(cell) ? red : nil }
              row = row.map { |cell| malformed?(cell) ? cell.to_s.gsub(/\A#{CELL_ERROR_MARKER}/, '') : cell } if params[:lem]
              sheet.add_row row, style: styles
            end
          end
          p.serialize(f.path)
        end
      end
    end

    def header_index key
      headers(true).index(str_to_sym(key))
    end

    def str_to_sym str
      str.is_a?(Symbol) ? str : squish(str).downcase.gsub(/\W/, '_').to_sym
    end

    def plough_row row
      return row if @formatters.empty? && @checkers.empty? # performance

      row.map.with_index do |cell, i|
        cell = format_cell(cell, i) unless @formatters.empty?
        cell = check_cell(cell, i) unless @checkers.empty?
        cell
      end
    end

    def format_cell cell, i
      case f = @formatters[headers(true)[i]]
      when Proc then f.call(cell)
      when Symbol then cell.public_send f
      else cell
      end
    end

    # rubocop:disable Style/MultilineTernaryOperator
    def check_cell cell, i
      f = @checkers[headers(true)[i]]
      case f
      when Proc then f.call(cell)
      when Symbol then cell.public_send(f)
      else true
      end ? cell : CELL_ERROR_MARKER + cell.to_s.split('').map { |c| "#{c}\u0336" }.join
    end
    # rubocop:enable Style/MultilineTernaryOperator

    def split_params params
      params = params.dup
      [
        { ces: params.delete(:cell_error_style) { CELL_ERROR_STYLE.dup },
          lem: params.delete(:leave_error_marker) { LEAVE_ERROR_MARKER } },
        { name: WORK_SHEET_NAME }.merge(params)
      ]
    end

    def squish str
      str.
        gsub(/\A[[:space:]]+/, '').
        gsub(/[[:space:]]+\z/, '').
        gsub(/[[:space:]]+/, ' ')
    end
  end
end

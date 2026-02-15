begin
  require 'filemagic'
rescue LoadError
  # OK, we do not have filemagick, no worries
  class FileMagic
    # file velocity.csv:  UTF-8 Unicode text, with very long lines
    # file velocity.xls:  Composite Document File V2 Document, Little Endian, Os: Windows, Version 1.0, Code page: -535, Revision Number: 0
    # file velocity.xlsx: Microsoft OOXML
    # file sesame_street_blog.xlsx: Microsoft Excel 2007+
    def file file
      `file --brief #{file}`
    end
  end
end

require 'axlsx'
require 'simple_xlsx_reader'
require 'csv'

require 'see_as_vee/version'
require 'see_as_vee/exceptions'

require 'see_as_vee/helpers'
require 'see_as_vee/sheet'

require 'see_as_vee/producers/hashes'

module SeeAsVee
  class Config
    include Singleton

    attr_accessor :allow_producing_empty_csv_files
    attr_accessor :file_type_mapping
  end

  Config.instance.file_type_mapping = {
    /\A(Microsoft Excel 2007+|Microsoft OOXML|Zip archive data)/ => :xlsx,
    /\A(CSV|UTF-8 Unicode|ASCII) text/ => :csv
  }

  def harvest whatever, formatters: {}, checkers: {}, skip_blank_rows: false, &cb
    sheet = SeeAsVee::Sheet.new whatever, formatters: formatters, checkers: checkers, skip_blank_rows: skip_blank_rows
    return sheet.each unless block_given?

    sheet.each(&cb)
    sheet
  end
  module_function :harvest

  def validate whatever, schema
    SeeAsVee::Sheet.new(whatever).map(&schema)
  end
  module_function :validate

  def csv *args, **params
    SeeAsVee::Producers::Hashes.csv(*args, **params)
  end
  module_function :csv

  def xlsx *args, **params
    SeeAsVee::Producers::Hashes.xlsx(*args, **params)
  end
  module_function :xlsx
end

class String
  def harvest_csv formatters: {}, checkers: {}, skip_blank_rows: false
    SeeAsVee.harvest self, formatters: formatters, checkers: checkers, skip_blank_rows: skip_blank_rows
  end
end

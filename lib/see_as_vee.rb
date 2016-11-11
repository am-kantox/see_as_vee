begin
  require 'filemagic'
rescue LoadError => e
  # OK, we do not have filemagick, no worries
end

require 'axlsx'
require 'simple_xlsx_reader'
require 'csv'

require "see_as_vee/version"
require "see_as_vee/exceptions"

require "see_as_vee/helpers"
require "see_as_vee/sheet"

require "see_as_vee/producers/hashes"

module SeeAsVee
  def harvest whatever, formatters: {}, checkers: {}
    sheet = SeeAsVee::Sheet.new whatever, formatters: formatters, checkers: checkers
    return sheet.each unless block_given?

    sheet.each(&Proc.new)
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
  def harvest_csv formatters: {}, checkers: {}
    SeeAsVee.harvest self, formatters: formatters, checkers: checkers
  end
end

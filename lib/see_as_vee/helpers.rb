SimpleXlsxReader.configuration.catch_cell_load_errors ||= true

module SeeAsVee
  module Helpers
    def file_with_type whatever
      file =  case whatever
              when IO then whatever
              when String
                File.exist?(whatever) ? File.new(whatever) : Privates.tempfile(whatever)
              else
                raise SeeAsVee::Exceptions::BadInputError.new(whatever)
              end

      [
        file,
        (Privates.handler_name(FileMagic.new.file(file.path)) if Kernel.const_defined?('FileMagic')) ||
          Privates.handler_by_ext(file.path[/(?<=\.).*\z/])
      ].tap do |_, handle|
        raise SeeAsVee::Exceptions::FileFormatError.new(file.path) if handle.nil?
      end
    end
    module_function :file_with_type

    def harvest_csv whatever
      file, type = file_with_type whatever
      Privates.public_send("#{type}_to_array", file.path)
    end
    module_function :harvest_csv

    module Privates
      FILE_TYPE = {
        /\A(Microsoft OOXML|Zip archive data)/ => :xlsx,
        /\A(UTF-8 Unicode|ASCII) text/ => :csv
      }.freeze

      def tempfile bytes
        Tempfile.new(['see_as_vee', '.csv']).tap { |f| f.syswrite(bytes) if bytes }
      end
      module_function :tempfile

      def handler_name file_type
        (FILE_TYPE.detect { |k, _| k =~ file_type } || []).last
      end
      module_function :handler_name

      def handler_by_ext ext
        ext.to_sym if %w(xlsx csv).include?(ext)
      end
      module_function :handler_by_ext

      def xlsx_to_array path
        SimpleXlsxReader.open(path).sheets.first.rows
      end
      module_function :xlsx_to_array
      def csv_to_array path
        CSV.read path
      end
      module_function :csv_to_array
    end
    private_constant :Privates
  end
end

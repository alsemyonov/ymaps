require 'geokit/geocoders'

module Geokit
  module Inflector
    if ''.respond_to?(:bytesize)  # Ruby 1.9
      def bytesize(string)
        string.bytesize
      end
    else                          # Ruby 1.8
      def bytesize(string)
        string.size
      end
    end
    module_function :bytesize

    def url_escape(s)
      s.gsub(/([^ a-zA-Z0-9_.-]+)/nu) {
        '%' + $1.unpack('H2' * bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end
  end
end

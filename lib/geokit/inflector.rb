require 'geokit/geocoders'

module Geokit
  module Inflector
    if defined?(::Rack)
      def url_escape(s)
          Rack::Utils::escape(s)
      end
    end
  end
end

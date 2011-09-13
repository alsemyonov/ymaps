module YMaps
  mattr_accessor :key
  self.key = 'REPLACE_WITH_YOUR_YANDEX_KEY'

  autoload :ActionView, 'ymaps/action_view'

  def self.geocode(query)
    require 'geokit/geocoders/yandex_geocoder'
    ::Geokit::Geocoders::YandexGeocoder.geocode(query)
  end

  def self.setup!
    ::ActionView::Base.send(:include, YMaps::ActionView::Helpers)
    ::Mime::Type.register_alias 'application/xml', :ymapsml
  end
end

require 'ymaps/railtie' if defined? Rails

module YMaps
  mattr_accessor :key
  self.key = 'REPLACE_WITH_YOUR_YANDEX_KEY'

  autoload :ActionView, 'ymaps/action_view'

  def self.geocode(query)
    require 'geokit/geocoders/yandex_geocoder'
    Geokit::Geocoders::Yandex.geocode(query)
  end
end

if defined? ActionView
  ActionView::Base.send(:include, YMaps::ActionView::Helpers)
end

require 'ymaps'
require 'rails/railtie'

class YMaps::Railtie < Rails::Railtie
  config.to_prepare do
    YMaps.setup!
  end
end

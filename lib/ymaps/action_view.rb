module YMaps
  module ActionView
    autoload :YMapsMLHelper, 'ymaps/action_view/ymapsml_helper'
    autoload :HtmlHelper, 'ymaps/action_view/html_helper'

    module Helpers
      include YMapsMLHelper
      include HtmlHelper
    end
  end
end

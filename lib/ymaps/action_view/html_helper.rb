module YMaps
  module ActionView
    module HtmlHelper
      class StaticMapPoint < Struct.new('MapPoint', :style, :color, :size, :number, :lat, :lng)
        def to_s
          "#{gml_lnglat},#{style}#{color}#{size}#{number}"
        end

        def gml_lnglat
          @gml_lnglat ||= "#{lng},#{lat}"
        end

        def gml_lnglat=(latlng)
          @gml_lnglat = latlng
        end

        def attributes=(attrs)
          attrs.each do |key, value|
            self[key] = value
          end
        end
      end

      def map_link(resource = nil, options = {})
        resource, options = nil, resource if resource.is_a?(Hash)

        url_params = options.delete(:url) { {} }
        href = if resource
                 polymorphic_url(resource, {:format => :ymapsml}.merge(url_params))
               else
                 url_for({:format => :ymapsml,
                          :only_path => false,
                          :time => Time.now}.merge(url_params))
               end

        tag(:link,
            options.merge!(:id => 'alternate_ymapsml',
                           :href => href,
                           :rel => 'alternate',
                           :type => 'application/ymapsml+xml'))
      end

      def ymaps_javascript_path(key = nil, by_require = 0)
        query = {:key => key || YMaps.key, :loadByRequire => by_require}.to_query
        "http://api-maps.yandex.ru/1.1/index.xml?#{query}"
      end

      def ymaps_include_tag(key = nil, by_require = 0)
        javascript_include_tag(ymaps_javascript_path(key, by_require))
      end

      def static_map(resources, options = {})
        title = options.delete(:title) { resources.to_s }
        map_type = options.delete(:map) { 'map' }
        width = options.delete(:width) { 600 }
        height = options.delete(:height) { 450 }
        map_size = "#{width},#{height}"
        zoom     = options.delete(:zoom) { 16 }

        common_point = StaticMapPoint.new(
          options.delete(:style) { 'pm' },
          options.delete(:color) { 'wt' },
          options.delete(:size)  { 'm' },
          options.delete(:number) { 0 }
        )

        collection = Array(resources).inject([]) do |result, resource|
          common_point.gml_lnglat = resource.latlng.gml_lnglat
          common_point.number += 1
          result << common_point.to_s
          result
        end.join('~')

        content_tag(:div, :class => 'b-map') do
          image_tag("http://static-maps.yandex.ru/1.x/?key=#{YMaps.key}&l=#{map_type}&pt=#{collection}&size=#{map_size}&z=#{zoom}", options.merge(
            :title => title,
            :alt => title,
            :class => 'static',
            :width => width,
            :height => height
          ))
        end
      end

      def geo_microformat(resource)
        latlng = resource.to_latlng
        resource_class ||= resource.class

        content_tag(:dl, :class => 'geo') do
          content_tag(:dt, resource_class.human_attribute_name(:lat)) +
            content_tag(:dd, latlng.lat, :class => 'latitude') +
            content_tag(:dt, resource_class.human_attribute_name(:lng)) +
            content_tag(:dd, latlng.lng, :class => 'longitude')
        end
      end

      def adr_microformat(resource)
        result = []
        if resource.respond_to?(:country) && resource.country.present?
          result << content_tag(:span, resource.country, :class => 'country-name')
        end
        if resource.respond_to?(:postal_code) && resource.postal_code.present?
          result << content_tag(:span, resource.postal_code, :class => 'postal-code')
        end
        if resource.respond_to?(:city) && resource.city.present?
          result << content_tag(:span, resource.city, :class => 'locality')
        end
        if resource.respond_to?(:street_address) && resource.street_address.present?
          result << content_tag(:span, resource.street_address, :class => 'street-address')
        end
        content_tag(:div, result.join(', '), :class => 'adr')
      end
    end
  end
end

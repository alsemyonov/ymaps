require 'geokit/geocoders/yandex_geocoder'

module YMaps
  module ActionView
    YMAPS_XMLNS = 'http://maps.yandex.ru/ymaps/1.x'
    GML_XMLNS = 'http://www.opengis.net/gml'
    REPR_XMLNS = 'http://maps.yandex.ru/representation/1.x'

    module YMapsMLHelper
      def ymapsml(options = {}, &block)
        xml = options.delete(:xml) { eval('xml', block.binding)  }
        xml.instruct!

        ymapsml_opts = {
          'xml:lang' => options.fetch(:language) { 'en-US' },
          'xmlns' => YMAPS_XMLNS,
          'xmlns:gml' => GML_XMLNS,
          'xmlns:repr' => REPR_XMLNS
        }
        ymapsml_opts.merge!(options).reject! { |key, value| !key.match(/^xml/) }

        xml.ymaps(ymapsml_opts) do
          yield YMapsBuilder.new(xml, self, options)
        end
      end
    end

    class Builder
      YMAPS_TAG_NAMES = %w(GeoObject GeoObjectCollection style ymaps AnyMetaData).map(&:to_sym)
      GML_TAG_NAMES = %w(boundedBy description Envelope exterior featureMember
        featureMembers interior LineString LinearRing lowerCorner
        metaDataProperty name Point Polygon pos posList upperCorner).map(&:to_sym)
      REPR_TAG_NAMES = %w(balloonContentStyle fill fillColor hintContentStyle iconContentStyle
        lineStyle href iconStyle mapType offset outline parentStyle polygonStyle
        Representation shadow size strokeColor strokeWidth Style Template
        template text View).map(&:to_sym)

      def initialize(xml)
        @xml = xml
      end

    protected
      def prefixed_method(method, *arguments, &block)
        @xml.__send__(*xmlns_prefix!(method, arguments), &block)
      end

      def link_to(name, href)
        prefixed_method(name, "\##{href}")
      end

    private
      def method_missing(method, *arguments, &block)
        prefixed_method(method, *arguments, &block)
      end

      def xmlns_prefix!(method, arguments)
        if GML_TAG_NAMES.include?(method)
          [:gml, method, *arguments]
        elsif REPR_TAG_NAMES.include?(method)
          [:repr, method, *arguments]
        else
          [method, *arguments]
        end
      end
    end

    class YMapsReprBuilder < Builder
      ACCEPTABLE_STYLES = {
        :balloon_content => [:template],
        :hint_content => [:template],
        :icon => [:href, :offset, :shadow, :size, :template],
        :icon_content => [:template],
        :line => [:stroke_color, :stroke_width],
        :polygon => [:fill, :fill_color, :outline, :stroke_color, :stroke_width],
      }

      def view(options = {})
        View {
          if options[:type]
            mapType(options[:type].to_s.upcase)
          end
          yield if block_given?
        }
      end

      # Add style definition
      # @param [Symbol, String] id      style name
      # @param [Hash]           options style options
      def style(id, options = {})
        options[:hasBalloon]  = options.delete(:balloon)  if options.key?(:balloon)
        options[:hasHint]     = options.delete(:hint)     if options.key?(:hint)
        parent                = options.delete(:parent) { false  }
        Style(options.merge('gml:id' => id.to_s)) {
          link_to(:parentStyle, parent) if parent
          yield
        }
      end

      ACCEPTABLE_STYLES.each do |name, values|
        define_method(name) do |options|
          tag_name = "#{ActiveSupport::Inflector.camelize(name.to_s, false)}Style"
          send(tag_name) do
            style_options(options, values)
          end
        end
      end

      def template(id, template_text = nil)
        Template('gml:id' => id.to_s) do
          text do
            cdata!(template_text || yield)
          end
        end
      end

      protected

      def style_options(options = {}, acceptable = nil)
        if acceptable
          options.assert_valid_keys(acceptable)
        end
        # Filling options
        fill(options[:fill] ? 1 : 0)            if options.key?(:fill)
        fillColor(options[:fill_color])         if options.key?(:fill_color)

        # Outline options
        outline(options[:outline] ? 1 : 0)      if options.key?(:outline)
        strokeColor(options[:stroke_color])     if options.key?(:stroke_color)
        strokeWidth(options[:stroke_width])     if options.key?(:stroke_width)

        href(options[:href])                    if options.key?(:href)
        size(*Array(options[:size]))            if options.key?(:size)
        offset(*Array(options[:offset]))        if options.key?(:offset)
        link_to(:template, options[:template])  if options.key?(:template)
        shadow do
          style_options(options[:shadow], [:href, :size, :template, :offset])
        end if options.key?(:shadow)
      end

      def size(x, y = nil)
        if x.is_a?(Hash)
          x, y = x[:x], x[:y]
        end
        prefixed_method(:size, :x => x, :y => y)
      end

      def offset(x, y = nil)
        if x.is_a?(Hash)
          x, y = x[:x], x[:y]
        end
        prefixed_method(:offset, :x => x, :y => y)
      end
    end

    class YMapsBuilder < Builder
      def initialize(xml, view, ymaps_options = {})
        @xml, @view, @ymaps_options = xml, view, ymaps_options
      end

      def collection(options = {})
        GeoObjectCollection do
          if options.key?(:style)
            @xml.style("\##{options.delete(:style)}")
          end
          featureMembers { yield }
        end
      end

      def object(object, options = {})
        GeoObject do
          if options.key?(:style)
            @xml.style("\##{options.delete(:style)}")
          end
          point(object.latlng)
          name(options.delete(:name) { object.to_s })
          yield self
        end
      end

      def point(latlng)
        Point {
          pos(latlng.gml_pos)
        }
      end

      def meta_data
        metaDataProperty {
          AnyMetaData {
            yield(@xml)
          }
        }
      end

      def representation
        Representation {
          yield(YMapsReprBuilder.new(@xml))
        }
      end
    end
  end
end

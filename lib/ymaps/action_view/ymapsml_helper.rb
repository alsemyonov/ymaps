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
        featureMembers interior LineString LinearString lowerCorner
        metaDataProperty name Point Polygon pos posList upperCorner).map(&:to_sym)
      REPR_TAG_NAMES = %w(balloonContentStyle fill fillColor hintContentStyle iconContentStyle
        lineStyle href iconStyle mapType offset outline parentStyle polygonStyle
        Representation shadow size strokeColor strokeWidth Style Template
        template text View).map(&:to_sym)

      def initialize(xml)
        @xml = xml
      end

    private
      def method_missing(method, *arguments, &block)
        @xml.__send__(*xmlns_prefix!(method, arguments), &block)
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
      def view(options = {})
        View {
          if options[:type]
            mapType(options[:type].to_s.upcase)
          end
          yield if block_given?
        }
      end

      def style(id, options = {})
        Style(options.merge('gml:id' => id.to_s)) {
          yield
        }
      end

      def template(id, template_text = nil)
        Template('gml:id' => id.to_s) do
          text do
            cdata!(template_text || yield)
          end
        end
      end

      def balloon_content(template)
        balloonContentStyle {
          @xml.repr(:template, "\##{template}")
        }
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

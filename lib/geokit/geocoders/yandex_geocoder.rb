require 'geokit'
require 'geokit/inflector'
require 'geokit/geocoders'

module Geokit
  self.default_units = :kms

  class LatLng
    def gml_pos
      "#{lng} #{lat}"
    end

    def gml_lnglat
      "#{lng},#{lat}"
    end

    def gml_lnglat=(lnglat)
      self.lng, self.lat = lnglat[0], lnglat[1]
    end
  end

  class Bounds
    def lower
      sw
    end

    def upper
      ne
    end
  end

  class GeoLoc
    attr_accessor :kind
    attr_writer :street_number, :street_name

    # Extracts the street number from the street address if the street address
    # has a value.
    def street_number
      @street_number ||= street_address && street_address[/(\d*)/]
    end

    # Returns the street name portion of the street address.
    def street_name
      @street_name ||= street_address && street_address[street_number.length, street_address.length].strip
    end

    # Do not use ugly Geokit::Inflector::titleize when set city’s name
    def city=(city)
      @city = city
    end

    # Do not use ugly Geokit::Inflector::titleize when set street address
    def street_address=(address)
      @street_address = address
    end
  end

  module Geocoders
    def self.yandex
      YMaps.key
    end

    def self.yandex=(key)
      YMaps.key = key
    end

    class YandexGeocoder < Geocoder
      KIND_ACCURACY_MAP = {
        'country'   => 1,
        'province'  => 2,
        'area'      => 3,
        # 5 postal code
        'locality'  => 4,
        'street'    => 6,
        'route'     => 6,
        # 7 kreuzung
        'house'     => 8,
        'metro'     => 8,
        'railway'   => 8,
        # 9 building
        # district hydro vegetation cemetery bridge km other
        #  0 #unknown
      }
      PRECISIONS = %w{unknown country state state city zip zip+4 street address building}

    private
      def self.call_geocoder_service(geocode)
        res = super("http://geocode-maps.yandex.ru/1.x/?geocode=#{Geokit::Inflector::url_escape(geocode)}&key=#{Geocoders::yandex}")

        unless res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPOK)
          return GeoLoc.new
        end

        xml = res.body
        logger.debug("Yandex geocoding: '#{geocode}'. Result: #{xml}")
        return xml2GeoLoc(xml)
      end

      def self.do_reverse_geocode(latlng)
        latlng = LatLng.normalize(latlng)
        call_geocoder_service(latlng.gml_lnglat) || GeoLoc.new
      end

      def self.do_geocode(address, options = {})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodable_s : address
        call_geocoder_service(address_str) || GeoLoc.new
      end

      def self.xml2GeoLoc(xml, address="")
        doc = REXML::Document.new(xml)

        if doc.elements['//GeocoderResponseMetaData/found'] != '0'
          geoloc = nil
          # Yandex can return multiple results as //featureMember elements.
          # iterate through each and extract each placemark as geoloc
          doc.each_element('//featureMember') do |e|
            extracted_geoloc = extract_placemark(e)

            if geoloc.nil?
              geoloc = extracted_geoloc
            else
              geoloc.all.push(extracted_geoloc)
            end
          end

          return geoloc
        else
          logger.info("Yandex was unable to geocode address: #{address}")
          return GeoLoc.new
        end
      end

      def self.extract_placemark(doc)
        res = GeoLoc.new
        res.provider = 'yandex'

        # basics
        res.gml_lnglat  = doc.elements['.//Point/pos'].text.to_s.split(' ')

        # extended -- false if not available
        res.full_address  = doc.elements['.//GeocoderMetaData/text'].try(:text)
        res.country       = doc.elements['.//CountryName'].try(:text)
        res.state         = doc.elements['.//AdministrativeAreaName'].try(:text)
        res.province      = doc.elements['.//SubAdministrativeAreaName'].try(:text)
        res.city          = doc.elements['.//LocalityName'].try(:text)
        res.district      = doc.elements['.//DependentLocalityName'].try(:text)
        res.street_name   = doc.elements['.//ThoroughfareName'].try(:text)
        res.street_number = doc.elements['.//PremiseNumber'].try(:text)
        res.zip           = doc.elements['.//PostalCodeNumber'].try(:text)

        res.kind = doc.elements['.//GeocoderMetaData/kind'].try(:text)
        res.accuracy = KIND_ACCURACY_MAP.fetch(res.kind) { 0 } if res.kind.present?
        res.precision = PRECISIONS[res.accuracy]

        if suggested_bounds = doc.elements['.//boundedBy']
          res.suggested_bounds = Bounds.normalize(
            suggested_bounds.elements['.//lowerCorner'].text.to_s.split(' ').reverse,
            suggested_bounds.elements['.//upperCorner'].text.to_s.split(' ').reverse
          )
        end

        res.success = true
        res
      end
    end
  end
end

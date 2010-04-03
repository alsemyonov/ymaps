require 'geokit'
require 'geokit/geocoders'

module Geokit
  self.default_units = :kms

  class LatLng
    def pos
      "#{lng} #{lat}"
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

    private
      def self.call_geocoder_service(geocode)
        res = super("http://geocode-maps.yandex.ru/1.x/?geocode=#{Geokit::Inflector::url_escape(geocode)}&key=#{Geocoders::yandex}")

        unless res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPOK)
          return GeoLoc.new
        end

        xml = res.body
        logger.debug "Yandex geocoding: '#{geocode}'. Result: #{xml}"
        return xml2GeoLoc(xml)
      end

      def self.do_reverse_geocode(latlng)
        latlng = LatLng.normalize(latlng)
        call_geocoder_service(latlng.ll)
      end

      def self.do_geocode(address, options = {})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodable_s : address
        call_geocoder_service(address_str)
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
          logger.ingo "Yandex was unable to geocode address: #{address}"
          return GeoLoc.new
        end
      end

      def self.extract_placemark(doc)
        res = GeoLoc.new
        res.provider = 'yandex'

        # basics
        coordinates = doc.elements['.//Point/pos'].text.to_s.split(' ')
        res.lng = coordinates[0]
        res.lat = coordinates[1]

        # extended -- false if not available
        res.city = doc.elements['.//LocalityName'].try(:text)
        res.state = doc.elements['.//AdministrativeAreaName'].try(:text)
        res.province = doc.elements['.//SubAdministrativeAreaName'].try(:text)
        res.full_address = doc.elements['.//GeocoderMetaData/text'].try(:text)
        res.zip = doc.elements['.//PostalCodeNumber'].try(:text)
        res.street_address = doc.elements['.//ThoroughfareName'].try(:text)
        res.country = doc.elements['.//CountryName'].try(:text)
        res.district = doc.elements['.//DependentLocalityName'].try(:text)

        # TODO: translate accuracy into Yahoo-style token address, street, zip, zip+4, city, state, country

        if suggested_bounds = doc.elements['.//boundedBy']
          res.suggested_bounds = Bounds.normalize(
            suggested_bounds.elements['.//lowerCorner'].text.to_s.split(' '),
            suggested_bounds.elements['.//upperCorner'].text.to_s.split(' ')
          )
        end

        res.success = true

        res
      end
    end
  end
end

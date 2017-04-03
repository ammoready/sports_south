module SportsSouth
  class Image < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/images.asmx'

    def self.urls(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      form_data = form_params(options).merge({
        ItemNumber: item_number
      })

      tempfile  = stream_to_tempfile(API_URL, '/GetPictureURLs', form_data)
      xml_doc   = Nokogiri::XML(tempfile)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      images = Hash.new

      SportsSouth::Parser.parse(tempfile, 'Table') do |node|
        size = content_for(node, 'ImageSize').to_sym
        images[size] = content_for(node, 'Link')
      end

      tempfile.unlink

      images
    end

  end
end

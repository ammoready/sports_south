module SportsSouth
  class Image < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/images.asmx'

    def self.urls(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/GetPictureURLs')

      request.set_form_data(form_params(options).merge({
        ItemNumber: item_number
      }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      images = Hash.new

      xml_doc.css('Table').each do |image|
        size = content_for(image, 'ImageSize').to_sym
        images[size] = content_for(image, 'Link')
      end

      images
    end

  end
end

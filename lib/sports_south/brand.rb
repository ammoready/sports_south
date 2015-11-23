module SportsSouth
  class Brand < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/BrandUpdate')

      request.set_form_data(form_params(options))
      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      brands = []

      xml_doc.css('Table').each do |brand|
        brands << {
          id: content_for(brand, 'BRDNO'),
          name: content_for(brand, 'BRDNM'),
          url: content_for(brand, 'BRDURL'),
          item_count: content_for(brand, 'ITCOUNT'),
        }
      end

      brands
    end

  end
end

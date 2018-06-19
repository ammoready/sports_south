module SportsSouth
  class Brand < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def initialize(options = {})
      requires!(options, :username, :password)

      @options = options
    end

    def self.all(options = {})
      requires!(options, :username, :password)

      new(options).all
    end

    def all
      http, request = get_http_and_request(API_URL, '/BrandUpdate')
      request.set_form_data(form_params(@options))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Table').map { |brand| map_hash(brand) }
    end

    protected

    def map_hash(node)
      {
        brand_id:   content_for(node, 'BRDNO'),
        name:       content_for(node, 'BRDNM'),
        url:        content_for(node, 'BRDURL'),
        item_count: content_for(node, 'ITCOUNT')
      }
    end

  end
end

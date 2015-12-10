module SportsSouth
  class Category < Base
    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/CategoryUpdate')

      request.set_form_data(form_params(options))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      categories = []

      xml_doc.css('Table').each do |category|
        categories << {
          category_id:  content_for(category, 'CATID'),
          description: content_for(category, 'CATDES'),
          department_id: content_for(category, 'DEPID'),
          department_description: content_for(category, 'DEP'),
          attribute_1: content_for(category, 'ATTR1'),
          attribute_2: content_for(category, 'ATTR2'),
          attribute_3: content_for(category, 'ATTR3'),
          attribute_4: content_for(category, 'ATTR4'),
          attribute_5: content_for(category, 'ATTR5'),
          attribute_6: content_for(category, 'ATTR6'),
          attribute_7: content_for(category, 'ATTR7'),
          attribute_8: content_for(category, 'ATTR8'),
          attribute_9: content_for(category, 'ATTR9'),
          attribute_10: content_for(category, 'ATTR0'),
          attribute_11: content_for(category, 'ATTR11'),
          attribute_12: content_for(category, 'ATTR12'),
          attribute_13: content_for(category, 'ATTR13'),
          attribute_14: content_for(category, 'ATTR14'),
          attribute_15: content_for(category, 'ATTR15'),
          attribute_16: content_for(category, 'ATTR16'),
          attribute_17: content_for(category, 'ATTR17'),
          attribute_18: content_for(category, 'ATTR18'),
          attribute_19: content_for(category, 'ATTR19'),
          attribute_20: content_for(category, 'ATTR20'),
        }
      end

      categories
    end
  end
end

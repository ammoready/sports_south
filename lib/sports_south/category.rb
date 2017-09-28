module SportsSouth
  class Category < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def self.all(options = {})
      requires!(options, :username, :password)

      http, request = get_http_and_request(API_URL, '/CategoryUpdate')
      request.set_form_data(form_params(options))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Table').map { |category| map_hash(category) }
    end

    protected

    def self.map_hash(node)
      {
        category_id:            content_for(node, 'CATID'),
        description:            content_for(node, 'CATDES'),
        department_id:          content_for(node, 'DEPID'),
        department_description: content_for(node, 'DEP'),
        attribute_1:            content_for(node, 'ATTR1'),
        attribute_2:            content_for(node, 'ATTR2'),
        attribute_3:            content_for(node, 'ATTR3'),
        attribute_4:            content_for(node, 'ATTR4'),
        attribute_5:            content_for(node, 'ATTR5'),
        attribute_6:            content_for(node, 'ATTR6'),
        attribute_7:            content_for(node, 'ATTR7'),
        attribute_8:            content_for(node, 'ATTR8'),
        attribute_9:            content_for(node, 'ATTR9'),
        attribute_10:           content_for(node, 'ATTR0'),
        attribute_11:           content_for(node, 'ATTR11'),
        attribute_12:           content_for(node, 'ATTR12'),
        attribute_13:           content_for(node, 'ATTR13'),
        attribute_14:           content_for(node, 'ATTR14'),
        attribute_15:           content_for(node, 'ATTR15'),
        attribute_16:           content_for(node, 'ATTR16'),
        attribute_17:           content_for(node, 'ATTR17'),
        attribute_18:           content_for(node, 'ATTR18'),
        attribute_19:           content_for(node, 'ATTR19'),
        attribute_20:           content_for(node, 'ATTR20')
      }
    end
  end
end

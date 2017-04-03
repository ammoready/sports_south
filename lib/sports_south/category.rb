module SportsSouth
  class Category < Base
    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      form_data = form_params(options)
      tempfile  = stream_to_tempfile(API_URL, '/CategoryUpdate', form_data)
      xml_doc   = Nokogiri::XML(tempfile)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      categories = Array.new

      SportsSouth::Parser.parse(tempfile, 'Table') do |node|
        categories.push(self.map_hash(node))
      end

      tempfile.unlink

      categories
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

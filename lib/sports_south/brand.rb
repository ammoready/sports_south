module SportsSouth
  class Brand < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      form_data = form_params(options)
      tempfile  = stream_to_tempfile(API_URL, '/BrandUpdate', form_data)
      xml_doc   = Nokogiri::XML(tempfile)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      brands = Array.new

      SportsSouth::Parser.parse(tempfile, 'Table') do |node|
        brands.push(self.map_hash(node))
      end

      tempfile.unlink

      brands
    end

    protected

    def self.map_hash(node)
      {
        id:         content_for(node, 'BRDNO'),
        name:       content_for(node, 'BRDNM'),
        url:        content_for(node, 'BRDURL'),
        item_count: content_for(node, 'ITCOUNT')
      }
    end

  end
end

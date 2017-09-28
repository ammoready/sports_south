module SportsSouth
  class Catalog < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    CATALOG_CODES = {
      'S' => :special,
      'C' => :closeout,
      'F' => :flyer,
      'B' => :buyers_special,
      'N' => :net_price,
    }

    ITEM_TYPES = {
      '1' => :handgun,
      '2' => :long_gun,
      '3' => :accessory,
      '4' => :ammunition,
      '5' => :optics,
      '6' => :archery,
      '7' => :reloading,
      '8' => :suppressor,
    }

    def initialize(options = {})
      requires!(options, :username, :password)

      @options = options
    end

    def self.all(chunk_size = 15, options = {}, &block)
      requires!(options, :username, :password)

      if options[:last_updated].present?
        options[:last_updated] = options[:last_updated].strftime("%-m/%-d/%Y")
      else
        options[:last_updated] ||= '1/1/1990'
      end

      options[:last_item] ||= '-1'

      new(options).all(chunk_size, &block)
    end

    def all(chunk_size, &block)
      chunker = SportsSouth::Chunker.new(chunk_size)
      http, request = get_http_and_request(API_URL, '/DailyItemUpdate')

      request.set_form_data(form_params(@options).merge({
        LastUpdate: @options[:last_updated],
        LastItem:   @options[:last_item].to_s
      }))

      response  = http.request(request)
      xml_doc   = Nokogiri::XML(sanitize_response(response))

      xml_doc.css('Table').map do |item|
        if chunker.is_full?
          yield(chunker.chunk)

          chunker.reset!
        else
          chunker.add(self.map_hash(item))
        end

        if chunker.chunk.count > 0
          yield(chunker.chunk)
        end
      end
    end

    protected

    def map_hash(node)
      {
        upc:  content_for(node, 'ITUPC'),
        item_identifier:  content_for(node, 'ITEMNO'),
        quantity: content_for(node, 'QTYOH').to_i,
        price: content_for(node, 'CPRC'),
        short_description: content_for(node, 'SHDESC'),
        long_description: content_for(node, 'IDESC'),
        category: content_for(node, 'CATID'),
        product_type: ITEM_TYPES[content_for(node, 'ITYPE')],
        mfg_number: content_for(node, 'IMFGNO'),
        weight: content_for(node, 'WTPBX'),
        map_price: content_for(node, 'MFPRC'),
        brand: content_for(node, 'ITBRDNO'),
        features: {
          length: content_for(node, 'LENGTH'),
          height: content_for(node, 'HEIGHT'),
          width: content_for(node, 'WIDTH')
        }
      }
    end

  end
end

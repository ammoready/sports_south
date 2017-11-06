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

      @options    = options
      @categories = SportsSouth::Category.all(options)
      @brands     = SportsSouth::Brand.all(options)
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

    def self.get_description(item_number, options = {})
      requires!(options, :username, :password)

      new(options, :username, :password)
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
          chunker.add(map_hash(item, @options[:full_product].present?))
        end
      end

      if chunker.chunk.count > 0
        yield(chunker.chunk)
      end
    end

    def get_description(item_number)
      http, request = get_http_and_request(API_URL, '/GetText')

      request.set_form_data(form_params(@options).merge({
        ItemNumber: item_number
      }))

      response  = http.request(request)
      xml_doc   = Nokogiri::XML(sanitize_response(response))

      content_for(xml_doc, 'CATALOGTEXT')
    end

    protected

    def map_hash(node, full_product = false)
      category  = @categories.find { |category| category[:category_id] == content_for(node, 'CATID') }
      brand     = @brands.find { |brand| brand[:brand_id] == content_for(node, 'ITBRDNO') }
      caliber   = content_for(node, 'ITATR3').present? ? content_for(node, 'ITATR3') : nil

      if full_product
        long_description = self.get_description(content_for(node, 'ITEMNO'))
      else
        nil
      end

      {
        name:               content_for(node, 'IDESC').gsub(/\s+/, ' '),
        upc:                content_for(node, 'ITUPC'),
        item_identifier:    content_for(node, 'ITEMNO'),
        quantity:           content_for(node, 'QTYOH').to_i,
        price:              content_for(node, 'CPRC'),
        short_description:  content_for(node, 'SHDESC'),
        long_description:   long_description,
        category:           category[:department_description],
        subcategory:        category[:description],
        product_type:       ITEM_TYPES[content_for(node, 'ITYPE')],
        mfg_number:         content_for(node, 'IMFGNO'),
        weight:             content_for(node, 'WTPBX'),
        caliber:            caliber,
        map_price:          content_for(node, 'MFPRC'),
        brand:              brand.present? ? brand[:name] : nil,
        features: {
          length: content_for(node, 'LENGTH'),
          height: content_for(node, 'HEIGHT'),
          width:  content_for(node, 'WIDTH')
        }
      }
    end

  end
end

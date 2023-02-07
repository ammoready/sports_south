module SportsSouth
  class Catalog < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'
    ITEM_NODE_NAME = 'Table'

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

    UNITS_OF_MEASURE = {
      'BX' => :box,
      'CS' => :case
    }

    def initialize(options = {})
      requires!(options, :username, :password)

      @options    = options
      @categories = SportsSouth::Category.all(options)
      @brands     = SportsSouth::Brand.all(options)
    end

    def self.all(options = {})
      requires!(options, :username, :password)

      if options[:last_updated]
        options[:last_updated] = options[:last_updated].strftime("%-m/%-d/%Y")
      else
        options[:last_updated] ||= '1/1/1990'
      end

      options[:last_item] ||= '-1'

      new(options).all
    end

    def all
      http, request = get_http_and_request(API_URL, '/DailyItemUpdate')

      request.set_form_data(form_params(@options).merge({
        LastUpdate: @options[:last_updated],
        LastItem:   @options[:last_item].to_s
      }))

      items    = []
      tempfile = download_to_tempfile(http, request)

      tempfile.rewind

      Nokogiri::XML::Reader.from_io(tempfile).each do |reader|
        next unless reader.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        next unless reader.name == ITEM_NODE_NAME

        node = Nokogiri::XML.parse(reader.outer_xml)

        _map_hash = map_hash(node.css(ITEM_NODE_NAME), @options[:full_product])

        items << _map_hash unless _map_hash.nil?
      end

      tempfile.close
      tempfile.unlink

      assign_brand_names(items)
    end

    def self.get_description(item_number, options = {})
      requires!(options, :username, :password)

      new(options, :username, :password)
    end

    def get_description(item_number)
      http, request = get_http_and_request(API_URL, '/GetText')

      request.set_form_data(form_params(@options).merge({
        ItemNumber: item_number
      }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      content_for(xml_doc, 'CATALOGTEXT')
    end

    protected

    def map_hash(node, full_product = false)
      category        = @categories.find { |category| category[:category_id] == content_for(node, 'CATID') }
      features        = self.map_features(category.except(:category_id, :department_id, :department_description, :description), node)
      model           = content_for(node, 'IMODEL')
      series          = content_for(node, 'SERIES')
      mfg_number      = content_for(node, 'MFGINO')
      caliber         = features[:caliber].presence || features[:gauge].presence
      action          = features[:action].presence
      unit_of_measure = UNITS_OF_MEASURE.fetch(content_for(node, 'UOM'), nil)

      if features.respond_to?(:[]=)
        features[:series] = series
        features[:unit_of_measure] = unit_of_measure
      end

      {
        name:              "#{model} #{series} #{mfg_number}".gsub(/\s+/, ' ').strip,
        model:             model,
        upc:               content_for(node, 'ITUPC').rjust(12, "0"),
        item_identifier:   content_for(node, 'ITEMNO'),
        quantity:          content_for(node, 'QTYOH').to_i,
        price:             content_for(node, 'CPRC'),
        short_description: content_for(node, 'SHDESC'),
        long_description:  (full_product ? get_description(content_for(node, 'ITEMNO')) : nil),
        category:          category[:description],
        product_type:      ITEM_TYPES[content_for(node, 'ITYPE')],
        mfg_number:        mfg_number,
        weight:            content_for(node, 'WTPBX'),
        caliber:           caliber,
        action:            action,
        map_price:         content_for(node, 'MFPRC'),
        brand:             content_for(node, 'ITBRDNO').presence,
        features:          features,
        unit_of_measure:   unit_of_measure,
      }
    end

    def map_features(attributes, node)
      features = {
        attributes[:attribute_1]  => content_for(node, 'ITATR1'),
        attributes[:attribute_2]  => content_for(node, 'ITATR2'),
        attributes[:attribute_3]  => content_for(node, 'ITATR3'),
        attributes[:attribute_4]  => content_for(node, 'ITATR4'),
        attributes[:attribute_5]  => content_for(node, 'ITATR5'),
        attributes[:attribute_6]  => content_for(node, 'ITATR6'),
        attributes[:attribute_7]  => content_for(node, 'ITATR7'),
        attributes[:attribute_8]  => content_for(node, 'ITATR8'),
        attributes[:attribute_9]  => content_for(node, 'ITATR9'),
        attributes[:attribute_10] => content_for(node, 'ITATR10'),
        attributes[:attribute_11] => content_for(node, 'ITATR11'),
        attributes[:attribute_12] => content_for(node, 'ITATR12'),
        attributes[:attribute_13] => content_for(node, 'ITATR13'),
        attributes[:attribute_14] => content_for(node, 'ITATR14'),
        attributes[:attribute_15] => content_for(node, 'ITATR15'),
        attributes[:attribute_16] => content_for(node, 'ITATR16'),
        attributes[:attribute_17] => content_for(node, 'ITATR17'),
        attributes[:attribute_18] => content_for(node, 'ITATR18'),
        attributes[:attribute_19] => content_for(node, 'ITATR19'),
        attributes[:attribute_20] => content_for(node, 'ITATR20'),
        'picref'                  => content_for(node, 'PICREF'),
      }

      features.delete_if { |k, v| v.to_s.blank? }
      features.transform_keys! { |k| k.gsub(/\s+/, '_').downcase }
      features.symbolize_keys!
    end

    def assign_brand_names(items)
      brand_ids = items.collect { |item| item[:brand] }.uniq.compact

      brand_ids.each do |brand_id|
        brand_name = @brands.find { |brand| brand[:brand_id] == brand_id }.try(:[], :name)

        next if brand_name.nil?

        items.map! do |item|
          item[:brand] = brand_name if item[:brand] == brand_id
          item
        end
      end

      items
    end

  end
end

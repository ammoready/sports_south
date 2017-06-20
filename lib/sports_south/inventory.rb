module SportsSouth
  class Inventory < Base

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

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      options[:last_update] ||= '1/1/1990' # Return full catalog.
      options[:last_item]   ||= '-1'       # Return all items.

      http, request = get_http_and_request(API_URL, '/DailyItemUpdate')

      request.set_form_data(form_params(options).merge({
        LastUpdate: options[:last_update],
        LastItem:   options[:last_item].to_s,
      }))

      xml_doc  = Nokogiri::XML(sanitize_response(http.request(request)))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Table').map { |item| map_hash(item, mode: options[:mode]) }
    end

    def self.get_text(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/GetText')

      request.set_form_data(form_params(options).merge({ ItemNumber: item_number }))

      response = http.request(request)
      xml_doc = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      {
        item_number:  item_number,
        catalog_text: content_for(xml_doc, 'CATALOGTEXT')
      }
    end

    def self.inquiry(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandInquiry')

      request.set_form_data(form_params(options).merge({ ItemNumber: item_number }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      {
        item_number:      content_for(xml_doc, 'I'),
        quantity_on_hand: content_for(xml_doc, 'Q').to_i,
        catalog_price:    content_for(xml_doc, 'P'),
        customer_price:   content_for(xml_doc, 'C'),
      }
    end

    def self.list_new_text(options = {})
      requires!(options, :username, :password, :source, :customer_number)
      options[:since] ||= (Time.now - 86400).strftime('%m/%d/%Y')

      http, request = get_http_and_request(API_URL, '/ListNewText')
      request.set_form_data(form_params(options).merge({ DateFrom: options[:since] }))

      xml_doc = Nokogiri::XML(sanitize_response(http.request(request)))

      xml_doc.css('Table').map do |item|
        {
          item_number: content_for(item, 'ITEMNO'),
          text: content_for(item, 'TEXT')
        }
      end
    end

    # This method accepts an Array of +item_numbers+.
    def self.onhand_update_by_csv(item_numbers, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandUpdatebyCSV')

      request.set_form_data(form_params(options).merge({ CSVItems: item_numbers.join(',') }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Table').map do |item|
        {
          item_number: content_for(item, 'I'),
          quantity: content_for(item, 'Q'),
          price: content_for(item, 'P'),
        }
      end
    end

    # Pass an optional `:since` option (YYYY-MM-DDTHH:mm:ss.mss-HH:00) to get items updated since that timestamp.
    def self.incremental_onhand_update(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      options[:since] ||= '-1'

      http, request = get_http_and_request(API_URL, '/IncrementalOnhandUpdate')

      request.set_form_data(form_params(options).merge({ SinceDateTime: options[:since] }))

      xml_doc = Nokogiri::XML(sanitize_response(http.request(request)))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Onhand').map do |item|
        {
          item_number:      content_for(item, 'I'),
          quantity:         content_for(item, 'Q'),
          quantity_changed: content_for(item, 'D'),
          catalog_price:    content_for(item, 'P'),
          customer_price:   content_for(item, 'C'),
        }
      end
    end

    def self.onhand_update(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandUpdate')

      request.set_form_data(form_params(options))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      xml_doc.css('Table').map do |item|
        {
          item_number:    content_for(item, 'I'),
          quantity:       content_for(item, 'Q').to_i,
          catalog_price:  content_for(item, 'P'),
          customer_price: content_for(item, 'C'),
        }
      end
    end

    protected

    def self.map_hash(node, mode: nil)
      if mode == :minimal
        {
          item_number:      content_for(node, 'ITEMNO'),
          catalog_price:    content_for(node, 'PRC1'),
          customer_price:   content_for(node, 'CPRC'),
          quantity_on_hand: content_for(node, 'QTYOH'),
        }
      else
        {
          item_number:              content_for(node, 'ITEMNO'),
          description:              content_for(node, 'IDESC'),
          manufacturer_sequence:    content_for(node, 'IMFSEQ'),
          manufacturer_number:      content_for(node, 'IMFGNO'),
          catalog_sequence:         content_for(node, 'CSEQ'),
          item_type:                ITEM_TYPES[content_for(node, 'ITYPE')],
          short_description:        content_for(node, 'SHDESC'),
          unit_of_measure:          content_for(node, 'UOM'),
          catalog_price:            content_for(node, 'PRC1'),
          customer_price:           content_for(node, 'CPRC'),
          quantity_on_hand:         content_for(node, 'QTYOH'),
          weight_per_box:           content_for(node, 'WTPBX'),
          upc:                      content_for(node, 'ITUPC'),
          manufacturer_item_number: content_for(node, 'MFGINO'),
          scan_name_1:              content_for(node, 'SCNAM1'),
          scan_name_2:              content_for(node, 'SCNAM2'),
          catalog_code:             CATALOG_CODES[content_for(node, 'CATCD')],
          mapp_price_code:          content_for(node, 'MFPRTYP'),
          mapp_price:               content_for(node, 'MFPRC'),
          category_id:              content_for(node, 'CATID'),
          text_reference_number:    content_for(node, 'TXTREF'),
          picture_reference_number: content_for(node, 'PICREF'),
          brand_id:                 content_for(node, 'ITBRDNO'),
          item_model_number:        content_for(node, 'IMODEL'),
          item_purpose:             content_for(node, 'IPURPOSE'),
          series_description:       content_for(node, 'SERIES'),
          item_length:              content_for(node, 'LENGTH'),
          item_height:              content_for(node, 'HEIGHT'),
          item_width:               content_for(node, 'WIDTH'),
          item_ships_hazmat_air:    content_for(node, 'HAZAIR'),
          item_ships_hazmat_ground: content_for(node, 'HAZGRND'),
          date_of_last_change:      content_for(node, 'CHGDTE'),
          date_added:               content_for(node, 'CHGDTE'),
          attribute_1:              content_for(node, 'ITATR1'),
          attribute_2:              content_for(node, 'ITATR2'),
          attribute_3:              content_for(node, 'ITATR3'),
          attribute_4:              content_for(node, 'ITATR4'),
          attribute_5:              content_for(node, 'ITATR5'),
          attribute_6:              content_for(node, 'ITATR6'),
          attribute_7:              content_for(node, 'ITATR7'),
          attribute_8:              content_for(node, 'ITATR8'),
          attribute_9:              content_for(node, 'ITATR9'),
          attribute_10:             content_for(node, 'ITATR0'),
          attribute_11:             content_for(node, 'ITATR11'),
          attribute_12:             content_for(node, 'ITATR12'),
          attribute_13:             content_for(node, 'ITATR13'),
          attribute_14:             content_for(node, 'ITATR14'),
          attribute_15:             content_for(node, 'ITATR15'),
          attribute_16:             content_for(node, 'ITATR16'),
          attribute_17:             content_for(node, 'ITATR17'),
          attribute_18:             content_for(node, 'ITATR18'),
          attribute_19:             content_for(node, 'ITATR19'),
          attribute_20:             content_for(node, 'ITATR20')
        }
      end
    end

  end
end

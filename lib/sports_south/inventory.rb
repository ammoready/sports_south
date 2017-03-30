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
    }

    def self.all(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      options[:last_update] ||= '1/1/1990'  # Return full catalog.
      options[:last_item]   ||= '-1'  # Return all items.

      http, request = get_http_and_request(API_URL, '/DailyItemUpdate')

      request.set_form_data(form_params(options).merge({
        LastUpdate: options[:last_update],
        LastItem: options[:last_item],
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      items = []

      xml_doc.css('Table').each do |item|
        items << {
          item_number: content_for(item, 'ITEMNO'),
          description: content_for(item, 'IDESC'),
          manufacturer_sequence: content_for(item, 'IMFSEQ'),
          manufacturer_number: content_for(item, 'IMFGNO'),
          catalog_sequence: content_for(item, 'CSEQ'),
          item_type: ITEM_TYPES[content_for(item, 'ITYPE')],
          short_description: content_for(item, 'SHDESC'),
          unit_of_measure: content_for(item, 'UOM'),
          catalog_price: content_for(item, 'PRC1'),
          customer_price: content_for(item, 'CPRC'),
          quantity_on_hand: content_for(item, 'QTYOH'),
          weight_per_box: content_for(item, 'WTPBX'),
          upc: content_for(item, 'ITUPC'),
          manufacturer_item_number: content_for(item, 'MFGINO'),
          scan_name_1: content_for(item, 'SCNAM1'),
          scan_name_2: content_for(item, 'SCNAM2'),
          catalog_code: CATALOG_CODES[content_for(item, 'CATCD')],
          mapp_price_code: content_for(item, 'MFPRTYP'),
          mapp_price: content_for(item, 'MFPRC'),
          category_id: content_for(item, 'CATID'),
          text_reference_number: content_for(item, 'TXTREF'),
          picture_reference_number: content_for(item, 'PICREF'),
          brand_id: content_for(item, 'ITBRDNO'),
          item_model_number: content_for(item, 'IMODEL'),
          item_purpose: content_for(item, 'IPURPOSE'),
          series_description: content_for(item, 'SERIES'),
          item_length: content_for(item, 'LENGTH'),
          item_height: content_for(item, 'HEIGHT'),
          item_width: content_for(item, 'WIDTH'),
          item_ships_hazmat_air: content_for(item, 'HAZAIR'),
          item_ships_hazmat_ground: content_for(item, 'HAZGRND'),
          date_of_last_change: content_for(item, 'CHGDTE'),
          date_added: content_for(item, 'CHGDTE'),
          attribute_1: content_for(item, 'ITATR1'),
          attribute_2: content_for(item, 'ITATR2'),
          attribute_3: content_for(item, 'ITATR3'),
          attribute_4: content_for(item, 'ITATR4'),
          attribute_5: content_for(item, 'ITATR5'),
          attribute_6: content_for(item, 'ITATR6'),
          attribute_7: content_for(item, 'ITATR7'),
          attribute_8: content_for(item, 'ITATR8'),
          attribute_9: content_for(item, 'ITATR9'),
          attribute_10: content_for(item, 'ITATR0'),
          attribute_11: content_for(item, 'ITATR11'),
          attribute_12: content_for(item, 'ITATR12'),
          attribute_13: content_for(item, 'ITATR13'),
          attribute_14: content_for(item, 'ITATR14'),
          attribute_15: content_for(item, 'ITATR15'),
          attribute_16: content_for(item, 'ITATR16'),
          attribute_17: content_for(item, 'ITATR17'),
          attribute_18: content_for(item, 'ITATR18'),
          attribute_19: content_for(item, 'ITATR19'),
          attribute_20: content_for(item, 'ITATR20'),
        }
      end

      items
    end

    def self.get_text(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/GetText')

      request.set_form_data(form_params(options).merge({ ItemNumber: item_number }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      { catalog_text: content_for(xml_doc, 'CATALOGTEXT') }
    end

    def self.inquiry(item_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandInquiry')

      request.set_form_data(form_params(options).merge({ ItemNumber: item_number }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      {
        item_number: content_for(xml_doc, 'I'),
        quantity_on_hand: content_for(xml_doc, 'Q').to_i,
        catalog_price: content_for(xml_doc, 'P'),
        customer_price: content_for(xml_doc, 'C'),
      }
    end

    # This method accepts an Array of +item_numbers+.
    def self.onhand_update_by_csv(item_numbers, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandUpdatebyCSV')

      request.set_form_data(form_params(options).merge({ CSVItems: item_numbers.join(',') }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      items = []

      xml_doc.css('Table').each do |item|
        items << {
          item_number: content_for(item, 'I'),
          quantity: content_for(item, 'Q'),
          price: content_for(item, 'P'),
        }
      end

      items
    end

    # Pass an optional `:since` option (YYYY-MM-DDTHH:mm:ss.mss-HH:00) to get items updated since that timestamp.
    def self.incremental_onhand_update(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      options[:since] ||= '-1'

      http, request = get_http_and_request(API_URL, '/IncrementalOnhandUpdate')

      request.set_form_data(form_params(options).merge({ SinceDateTime: options[:since] }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      items = []

      xml_doc.css('Onhand').each do |item|
        items << {
          item_number: content_for(item, 'I'),
          quantity: content_for(item, 'Q'),
          quantity_changed: content_for(item, 'D'),
          catalog_price: content_for(item, 'P'),
          customer_price: content_for(item, 'C'),
        }
      end

      items
    end

    def self.onhand_update(options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/OnhandUpdate')

      request.set_form_data(form_params(options))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      items = []

      xml_doc.css('Table').each do |item|
        items << {
          item_number: content_for(item, 'I'),
          quantity: content_for(item, 'Q'),
          catalog_price: content_for(item, 'P'),
          customer_price: content_for(item, 'C'),
        }
      end

      items
    end

    protected

    def self.stream_to_tempfile(endpoint, options)
      temp_file     = Tempfile.new
      http, request = get_http_and_request(API_URL, endpoint)

      request.set_form_data(options)

      http.request(request) do |response|
        File.open(temp_file, 'w') do |file|
          response.read_body do |chunk|
            file.write(chunk.gsub('&lt;', '<').gsub('&gt;', '>'))
          end
        end
      end

      temp_file
    end

  end
end

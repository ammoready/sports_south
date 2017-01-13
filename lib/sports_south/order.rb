module SportsSouth
  class Order < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/orders.asmx'

    SHIP_VIA = {
      ground:    '',
      next_day:  'N',
      two_day:   '2',
      three_day: '3',
      saturday:  'S',
    }

    # D=Placed, E=Error placing Order, R=Placed-Verifying, W=Open
    STATUS = {
      'D' => :placed,
      'E' => :error_placing_order,
      'R' => :placed_verifying,
      'W' => :open,
    }

    attr_reader :response_body
    attr_reader :order_number

    def self.find(order_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)
      new(options.merge({order_number: order_number}))
    end

    def initialize(options = {})
      requires!(options, :username, :password, :source, :customer_number)
      @options = options
      @order_number = options[:order_number]
    end

    def add_header(header = {})
      requires!(header, :purchase_order, :sales_message, :shipping)
      header[:customer_order_number] = header[:purchase_order] unless header.has_key?(:customer_order_number)
      header[:adult_signature] = false unless header.has_key?(:adult_signature)
      header[:signature] = false unless header.has_key?(:signature)
      header[:insurance] = false unless header.has_key?(:insurance)

      requires!(header[:shipping], :name, :address_one, :city, :state, :zip, :phone)
      header[:shipping][:attn] = '' unless header[:shipping].has_key?(:attn)
      header[:shipping][:via] = SHIP_VIA[:ground] unless header[:shipping].has_key?(:ship_via)
      header[:shipping][:address_two] = '' unless header[:shipping].has_key?(:address_two)

      http, request = get_http_and_request(API_URL, '/AddHeader')

      request.set_form_data(form_params(@options).merge({
        PO: header[:purchase_order],
        CustomerOrderNumber: header[:customer_order_number],
        SalesMessage: header[:sales_message],

        ShipVia: header[:shipping][:via],
        ShipToName: header[:shipping][:name],
        ShipToAttn: header[:shipping][:attn],
        ShipToAddr1: header[:shipping][:address_one],
        ShipToAddr2: header[:shipping][:address_two],
        ShipToCity: header[:shipping][:city],
        ShipToState: header[:shipping][:state],
        ShipToZip: header[:shipping][:zip],
        ShipToPhone: header[:shipping][:phone],

        AdultSignature: header[:adult_signature],
        Signature: header[:signature],
        Insurance: header[:insurance],
      }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(response.body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = response.body
      @order_number = xml_doc.content
    end

    def add_ship_instructions(ship_instructions = {})
      requires!(ship_instructions, :order_number, :ship_inst_1, :ship_inst_2)

      http, request = get_http_and_request(API_URL, '/AddShipInstructions')

      request.set_form_data(form_params(@options).merge({
        SystemOrderNumber: ship_instructions[:order_number],
        ShipInst1: ship_instructions[:ship_inst_1],
        ShipInst2: ship_instructions[:ship_inst_2],
      }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(response.body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = response.body
      xml_doc.content == 'true'
    end

    def add_detail(detail = {})
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      requires!(detail, :ss_item_number, :price)
      detail[:quantity] = 1 unless detail.has_key?(:quantity)
      detail[:item_number] = '' unless detail.has_key?(:item_number)
      detail[:item_description] = '' unless detail.has_key?(:item_description)

      http, request = get_http_and_request(API_URL, '/AddDetail')

      request.set_form_data(form_params(@options).merge({
        OrderNumber: @order_number,
        SSItemNumber: detail[:ss_item_number],
        Quantity: detail[:quantity],
        OrderPrice: detail[:price],
        CustomerItemNumber: detail[:item_number],
        CustomerItemDescription: detail[:item_description],
      }))

      response = http.request(request)
      xml_doc = Nokogiri::XML(response.body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = response.body

      xml_doc.content == 'true'
    end

    def submit!
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request(API_URL, '/Submit')

      request.set_form_data(form_params(@options).merge({
        OrderNumber: @order_number,
      }))

      response = http.request(request)
      xml_doc = Nokogiri::XML(response.body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = response.body

      xml_doc.content == 'true'
    end

    def header
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request(API_URL, '/GetHeader')

      request.set_form_data(form_params(@options).merge({
        CustomerOrderNumber: @order_number,
        OrderNumber: @order_number
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = body

      @header = {
        system_order_number: content_for(xml_doc, 'ORDNO'),
        customer_number: content_for(xml_doc, 'ORCUST'),
        order_po_number: content_for(xml_doc, 'ORPO'),
        customer_order_number: content_for(xml_doc, 'ORCONO'),
        order_date: content_for(xml_doc, 'ORDATE'),
        message: content_for(xml_doc, 'MSG'),
        air_code: content_for(xml_doc, 'ORAIR'),
        order_source: content_for(xml_doc, 'ORSRC'),
        status: STATUS[content_for(xml_doc, 'STATUS')],
      }
    end

    def details
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request(API_URL, '/GetDetail')

      request.set_form_data(form_params(@options).merge({
        CustomerOrderNumber: @order_number,
        OrderNumber: @order_number,
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = body
      @details = []

      xml_doc.css('Table').each do |table|
        @details << {
          system_order_number: content_for(table, 'ORDNO'),
          order_line_number: content_for(table, 'ORLINE'),
          customer_number: content_for(table, 'ORCUST'),
          order_item_number: content_for(table, 'ORITEM'),
          order_quantity: content_for(table, 'ORQTY'),
          order_price: content_for(table, 'ORPRC'),
          ship_quantity: content_for(table, 'ORQTYF'),
          ship_price: content_for(table, 'ORPRCF'),
          customer_item_number: content_for(table, 'ORCUSI'),
          customer_description: content_for(table, 'ORCUSD'),
          item_description: content_for(table, 'IDESC'),
          quantity_on_hand: content_for(table, 'QTYOH'),
          line_detail_comment: content_for(table, 'ORDCMT'),
          line_detail_po_number: content_for(table, 'ORPO2'),
        }
      end

      @details
    end

  end
end

require 'net/http'
require 'nokogiri'

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
      header[:shipping][:attn] = header[:shipping][:name] unless header.has_key?(:attn)
      header[:shipping][:via] = SHIP_VIA[:ground] unless header.has_key?(:ship_via)
      header[:shipping][:address_two] = '' unless header[:shipping].has_key?(:address_two)

      http, request = get_http_and_request('/AddHeader')

      request.set_form_data(form_params.merge({
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

      @response_body = response.body
      @order_number = xml_doc.content
    end

    def add_detail(detail = {})
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      requires!(detail, :ss_item_number, :price)
      detail[:quantity] = 1 unless detail.has_key?(:quantity)
      detail[:item_number] = '' unless detail.has_key?(:item_number)
      detail[:item_description] = '' unless detail.has_key?(:item_description)

      http, request = get_http_and_request('/AddDetail')

      request.set_form_data(form_params.merge({
        OrderNumber: @order_number,
        SSItemNumber: detail[:ss_item_number],
        Quantity: detail[:quantity],
        OrderPrice: detail[:price],
        CustomerItemNumber: detail[:item_number],
        CustomerItemDescription: detail[:item_description],
      }))

      response = http.request(request)
      xml_doc = Nokogiri::XML(response.body)

      @response_body = response.body

      xml_doc.content == 'true'
    end

    def submit!
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request('/Submit')

      request.set_form_data(form_params.merge({
        OrderNumber: @order_number,
      }))

      response = http.request(request)
      xml_doc = Nokogiri::XML(response.body)

      @response_body = response.body

      xml_doc.content == 'true'
    end

    def header
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request('/GetHeader')

      request.set_form_data(form_params.merge({
        CustomerOrderNumber: @order_number,
        OrderNumber: @order_number
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      @response_body = body

      @header = {
        system_order_number: xml_doc.css('ORDNO').first.content,
        customer_number: xml_doc.css('ORCUST').first.content,
        order_po_number: xml_doc.css('ORPO').first.content,
        customer_order_number: xml_doc.css('ORCONO').first.content,
        order_date: xml_doc.css('ORDATE').first.content,
        message: xml_doc.css('MSG').first.content,
        air_code: xml_doc.css('ORAIR').first.content,
        order_source: xml_doc.css('ORSRC').first.content,
        status: STATUS[xml_doc.css('STATUS').first.content],
      }
    end

    def details
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request('/GetDetail')

      request.set_form_data(form_params.merge({
        CustomerOrderNumber: @order_number,
        OrderNumber: @order_number,
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      @response_body = body
      @details = []

      xml_doc.css('Table').each do |table|
        @details << {
          system_order_number: table.css('ORDNO').first.content,
          order_line_number: table.css('ORLINE').first.content,
          customer_number: table.css('ORCUST').first.content,
          order_item_number: table.css('ORITEM').first.content,
          order_quantity: table.css('ORQTY').first.content,
          order_price: table.css('ORPRC').first.content,
          ship_quantity: table.css('ORQTYF').first.content,
          ship_price: table.css('ORPRCF').first.content,
          customer_item_number: table.css('ORCUSI').first.content,
          customer_description: table.css('ORCUSD').first.content,
          item_description: table.css('IDESC').first.content,
          quantity_on_hand: table.css('QTYOH').first.content,
          line_detail_comment: table.css('ORDCMT').first.content,
          line_detail_po_number: table.css('ORPO2').first.content,
        }
      end

      @details
    end

    private

    # Returns a hash of common form params.
    def form_params
      {
        UserName: @options[:username],
        Password: @options[:password],
        CustomerNumber: @options[:customer_number],
        Source: @options[:source],
      }
    end

    # Returns the Net::HTTP and Net::HTTP::Post objects.
    #
    #   http, request = get_http_and_request(<endpoint>)
    def get_http_and_request(endpoint)
      uri = URI([API_URL, endpoint].join)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)

      return http, request
    end

    # HACK: We have to fix the malformed XML response SS is currently returning.
    def sanitize_response(response)
      response.body.gsub('&lt;', '<').gsub('&gt;', '>')
    end

  end
end

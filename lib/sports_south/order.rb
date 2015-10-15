require 'net/http'

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

    def initialize(options = {})
      requires!(options, :username, :password, :source, :customer_number)
      @options = options
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

      uri = URI([API_URL, '/AddHeader'].join)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)

      request.set_form_data({
        UserName: @options[:username],
        Password: @options[:password],
        CustomerNumber: @options[:customer_number],
        Source: @options[:source],

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
      })

      response = http.request(request)
    end

    def add_detail(detail = {})
      raise 'Not yet implemented.'
    end

    def submit!
      raise 'Not yet implemented.'
    end

  end
end

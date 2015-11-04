module SportsSouth
  class Invoice < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/invoices.asmx'

    attr_reader :response_body
    attr_reader :order_number

    def self.find_by_order_number(order_number, options = {})
      requires!(options, :username, :password, :source, :customer_number)
      new(options.merge({order_number: order_number}))
    end

    def initialize(options = {})
      requires!(options, :username, :password, :source, :customer_number)
      @options = options
      @order_number = options[:order_number]
    end

    def tracking
      raise StandardError.new("No @order_number present.") if @order_number.nil?

      http, request = get_http_and_request(API_URL, '/GetTrackingByPo')

      request.set_form_data(form_params.merge({
        PONumber: @order_number,
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      @response_body = body

      @tracking = {
        invoice_number: content_for(xml_doc, 'INVNO'),
        customer_number: content_for(xml_doc, 'CUSNO'),
        po_number: content_for(xml_doc, 'PONBR'),
        ship_date: content_for(xml_doc, 'SHPDTE'),
        tracking_number: content_for(xml_doc, 'TRACKNO'),
        package_weight: content_for(xml_doc, 'PKGWT'),
        cod_amount: content_for(xml_doc, 'CODAMT'),
        hazmat: content_for(xml_doc, 'HAZMAT'),
        ship_amount: content_for(xml_doc, 'SHPAMT'),
        ship_service: content_for(xml_doc, 'SERVICE'),
      }
    end
  end
end

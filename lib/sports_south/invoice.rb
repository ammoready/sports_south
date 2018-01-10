module SportsSouth
  class Invoice < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/invoices.asmx'

    attr_reader :response_body
    attr_reader :po_number

    def self.find_by_po_number(po_number, options = {})
      requires!(options, :username, :password)
      new(options.merge({po_number: po_number}))
    end

    def initialize(options = {})
      requires!(options, :username, :password)
      @options = options
      @po_number = options[:po_number]
    end

    def tracking
      raise StandardError.new("No @po_number present.") if @po_number.nil?

      http, request = get_http_and_request(API_URL, '/GetTrackingByPo')

      request.set_form_data(form_params(@options).merge({
        PONumber: @po_number,
        customer_number: @options[:username],
        source: SportsSouth.config.source
      }))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

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

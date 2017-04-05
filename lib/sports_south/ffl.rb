module SportsSouth
  class FFL < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/orders.asmx'

    DATE_REGEX = /\A\d+\/\d+\/\d+/

    def self.accepts_transfer(ffl, options = {})
      requires!(options, :username, :password, :source, :customer_number)

      http, request = get_http_and_request(API_URL, '/FFLAcceptsTransfer')

      request.set_form_data(form_params(options).merge({ FFL: ffl }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      # Response returns FFL expiration date (does accept transfer),
      # '0' if they do not accept transfer,
      # or 'UNKNOWN' if SS cannot find the FFL.
      xml_doc.content =~ DATE_REGEX ? true : false
    end

  end
end

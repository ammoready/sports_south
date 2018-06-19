module SportsSouth
  class User < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/users.asmx'

    attr_reader :response_body

    def initialize(options = {})
      requires!(options, :username, :password)

      @options = options
    end

    def authenticated?
      # Use #email_preferences as a check, since there's no official way of just testing credentials.
      email_preferences
      true
    rescue SportsSouth::NotAuthenticated
      false
    end

    def email_preferences
      http, request = get_http_and_request(API_URL, '/GetEmailPrefs')

      request.set_form_data(form_params(@options))

      response = http.request(request)
      body = sanitize_response(response)
      xml_doc = Nokogiri::XML(body)

      raise SportsSouth::NotAuthenticated if not_authenticated?(xml_doc)

      @response_body = body

      @email_preferences = {
        default_email: content_for(xml_doc, 'CUEML'),
        statement_email: content_for(xml_doc, 'STMNTS'),
        marketing_email: content_for(xml_doc, 'MKTG'),
        email_statements: (content_for(xml_doc, 'EMLSTM') == 'E'),
        email_invoices: (content_for(xml_doc, 'EMLINV') == 'E'),
      }
    end

  end
end

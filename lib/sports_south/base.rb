module SportsSouth
  # Holds methods common to all classes.
  class Base

    TIMEOUT = 960 # seconds
    USER_AGENT = "sports_south rubygems.org/gems/sports_south v(#{SportsSouth::VERSION})"
    CONTENT_TYPE = 'application/x-www-form-urlencoded'.freeze

    protected

    # Wrapper to `self.requires!` that can be used as an instance method.
    def requires!(*args)
      self.class.requires!(*args)
    end

    def self.requires!(hash, *params)
      params.each do |param|
        if param.is_a?(Array)
          raise ArgumentError.new("Missing required parameter: #{param.first}") unless hash.has_key?(param.first)

          valid_options = param[1..-1]
          raise ArgumentError.new("Parameter: #{param.first} must be one of: #{valid_options.join(', ')}") unless valid_options.include?(hash[param.first])
        else
          raise ArgumentError.new("Missing required parameter: #{param}") unless hash.has_key?(param)
        end
      end
    end

    def content_for(xml_doc, field)
      node = xml_doc.css(field).first
      node.nil? ? nil : node.content.strip
    end

    # Returns a hash of common form params.
    def self.form_params(options = {})
      {
        UserName: options[:username],
        Password: options[:password],
        CustomerNumber: options[:customer_number],
        Source: options[:source],
      }
    end
    def form_params(*args); self.class.form_params(*args); end

    # Returns the Net::HTTP and Net::HTTP::Post objects.
    #
    #   http, request = get_http_and_request(<api_url>, <endpoint>)
    def self.get_http_and_request(api_url, endpoint)
      uri = URI([api_url, endpoint].join)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = TIMEOUT
      request = Net::HTTP::Post.new(uri.request_uri)
      request['User-Agent'] = USER_AGENT
      request['Content-Type'] = CONTENT_TYPE

      return http, request
    end
    def get_http_and_request(*args); self.class.get_http_and_request(*args); end

    def self.not_authenticated?(xml_doc)
      msg = content_for(xml_doc, 'ERROR')
      (msg =~ /Authentication Failed/i) || (msg =~ /NOT AUTHENTICATED/i)
    end
    def not_authenticated?(*args); self.class.not_authenticated?(*args); end

    # HACK: We have to fix the malformed XML response SS is currently returning.
    def self.sanitize_response(response)
      response.body.gsub('&lt;', '<').gsub('&gt;', '>')
    end
    def sanitize_response(*args); self.class.sanitize_response(*args); end

  end
end

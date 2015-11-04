module SportsSouth
  # Holds methods common to all classes.
  class Base

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
    #   http, request = get_http_and_request(<api_url>, <endpoint>)
    def get_http_and_request(api_url, endpoint)
      uri = URI([api_url, endpoint].join)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)

      return http, request
    end

    def content_for(xml_doc, field)
      node = xml_doc.css(field).first
      node.nil? ? nil : node.content.strip
    end

    # HACK: We have to fix the malformed XML response SS is currently returning.
    def sanitize_response(response)
      response.body.gsub('&lt;', '<').gsub('&gt;', '>')
    end

  end
end

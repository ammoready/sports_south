module SportsSouth
  class Inventory < Base

    API_URL = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

    def initialize(options = {})
      requires!(options, :username, :password)

      @options = options
    end

    def self.get_quantity_file(options = {})
      requires!(options, :username, :password)

      options[:last_updated]  = '1990-09-25T14:15:47-04:00'
      options[:last_item]     = '-1'

      new(options).get_quantity_file
    end

    def self.all(chunk_size = 15, options = {}, &block)
      requires!(options, :username, :password)

      if options[:last_updated].present?
        options[:last_updated] = options[:last_updated].strftime('%Y-%m-%dT%H:%M:00.00%:z')
      else
        options[:last_updated] = '1990-09-25T14:15:47-04:00'
      end

      options[:last_item] ||= '-1'

      new(options).all(chunk_size, &block)
    end

    def self.get(item_identifier, options = {})
      requires!(options, :username, :password)
      new(options).get(item_identifier)
    end

    def all(chunk_size, &block)
      chunker = SportsSouth::Chunker.new(chunk_size)
      http, request = get_http_and_request(API_URL, '/IncrementalOnhandUpdate')

      request.set_form_data(form_params = form_params(@options).merge({
        SinceDateTime: @options[:last_updated],
        LastItem:      @options[:last_item].to_s
      }))

      response  = http.request(request)
      xml_doc   = Nokogiri::XML(sanitize_response(response))

      xml_doc.css('Onhand').map do |item|
        if chunker.is_full?
          yield(chunker.chunk)

          chunker.reset!
        else
          chunker.add(self.map_hash(item))
        end
      end

      if chunker.chunk.count > 0
        yield(chunker.chunk)
      end
    end

    def get_quantity_file
      tempfile      = Tempfile.new
      http, request = get_http_and_request(API_URL, '/IncrementalOnhandUpdate')

      request.set_form_data(form_params = form_params(@options).merge({
        SinceDateTime: @options[:last_updated],
        LastItem:      @options[:last_item].to_s
      }))

      response  = http.request(request)
      xml_doc   = Nokogiri::XML(sanitize_response(response))

      xml_doc.css('Onhand').map do |item|
        tempfile.puts("#{content_for(item, 'I')},#{content_for(item, 'Q')}")
      end

      tempfile.close

      tempfile.path
    end

    def self.quantity(chunk_size = 100, options = {}, &block)
      requires!(options, :username, :password)

      if options[:last_updated].present?
        options[:last_updated] = options[:last_updated].to_s("yyyy-MM-ddTHH:mm:sszzz")
      else
        options[:last_updated] = '1990-09-25T14:15:47-04:00'
      end

      options[:last_item] ||= '-1'

      new(options).all(chunk_size, &block)
    end

    def quantity(chunk_size, &block)
      chunker = SportsSouth::Chunker.new(chunk_size)
      http, request = get_http_and_request(API_URL, '/IncrementalOnhandUpdate')

      request.set_form_data(form_params = form_params(@options).merge({
        SinceDateTime: @options[:last_updated],
        LastItem:      @options[:last_item].to_s
      }))

      response  = http.request(request)
      xml_doc   = Nokogiri::XML(sanitize_response(response))

      xml_doc.css('Onhand').map do |item|
        if chunker.is_full?
          yield(chunker.chunk)

          chunker.reset!
        else
          chunker.add({
            item_identifier: content_for(node, 'I'),
            quantity: content_for(node, 'Q').to_i
          })
        end
      end

      if chunker.chunk.count > 0
        yield(chunker.chunk)
      end
    end

    def get(item_identifier)
      http, request = get_http_and_request(API_URL, '/OnhandInquiry')

      request.set_form_data(form_params(@options).merge({ ItemNumber: item_identifier }))

      response = http.request(request)
      xml_doc  = Nokogiri::XML(sanitize_response(response))
    end

    protected

    def map_hash(node)
      {
        item_identifier: content_for(node, 'I'),
        quantity: content_for(node, 'Q').to_i,
        price: content_for(node, 'C')
      }
    end

  end
end

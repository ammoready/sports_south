module SportsSouth
  class Order < Base

    def initialize(options = {})
      requires!(options, :username, :password, :source, :customer_number)
      @options = options
    end

    def add_header(header = {})
      raise 'Not yet implemented.'
    end

    def add_detail(detail = {})
      raise 'Not yet implemented.'
    end

    def submit!
      raise 'Not yet implemented.'
    end

  end
end

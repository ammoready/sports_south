module SportsSouth
  class Order < Base

    def initialize(options)
      requires!(options, :username, :password, :source, :customer_number)
    end

    def add_header(options = {})
      raise 'Not yet implemented.'
    end

    def add_detail(options = {})
      raise 'Not yet implemented.'
    end

    def submit!
      raise 'Not yet implemented.'
    end

  end
end

require 'sports_south/version'

require 'json'
require 'net/http'
require 'nokogiri'

require 'sports_south/base'
require 'sports_south/brand'
require 'sports_south/catalog'
require 'sports_south/category'
require 'sports_south/ffl'
require 'sports_south/image'
require 'sports_south/inventory'
require 'sports_south/invoice'
require 'sports_south/order'
require 'sports_south/rotator'
require 'sports_south/user'

module SportsSouth
  class NotAuthenticated < StandardError; end

  class << self
    attr_accessor :config
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end

  class Configuration
    attr_accessor :source

    def initialize
      @source ||= "ammor"
    end
  end
end

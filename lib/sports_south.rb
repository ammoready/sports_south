require 'sports_south/version'

require 'json'
require 'net/http'
require 'nokogiri'

require 'sports_south/base'
require 'sports_south/brand'
require 'sports_south/category'
require 'sports_south/ffl'
require 'sports_south/image'
require 'sports_south/inventory'
require 'sports_south/invoice'
require 'sports_south/order'
require 'sports_south/rotator'
require 'sports_south/user'

require 'sports_south/chunker'
require 'sports_south/parser'
require 'sports_south/documents/inventory_document'

module SportsSouth
  class NotAuthenticated < StandardError; end
end

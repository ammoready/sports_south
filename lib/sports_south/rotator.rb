module SportsSouth
  class Rotator

    API_URL = 'http://tsw-api.com/images/rotator/check.php'

    def self.check(api_user_id, api_key, *items)
      new(api_user_id, api_key).check(items)
    end

    def initialize(api_user_id, api_key)
      @api_user_id = api_user_id
      @api_key = api_key
    end

    def check(*items)
      params = {
        u: @api_user_id,
        k: @api_key,
      }

      params[:i] = items.is_a?(String) ? items.first : items.join(',')

      uri = URI(API_URL)
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)

      results = {}
      JSON.parse(response.body).each { |k, v| results[k] = v == 'true' }
      results
    end

  end
end

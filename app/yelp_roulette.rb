require 'oauth'
require 'rack'
require 'json'

class YelpRoulette
  attr_reader :consumer, :access_token

  def initialize(consumer_key:, consumer_secret:, token:, token_secret:)
    @consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
      site: "http://api.yelp.com"
    )
    @access_token = OAuth::AccessToken.new(consumer, token, token_secret)
  end

  def find_food(location, limit = 20)
    total_count = total(location: location)
    offset = offset(total_count, limit)
    restaurants = businesses(location: location, offset: offset, limit: limit)
    restaurants.shuffle
  end

  # total count of search results
  def total(params)
    search(params.merge(limit: 1))['total']
  end

  # businesses array
  def businesses(params)
    search(params)['businesses']
  end

  private

  def search(params)
    params[:term] = "restaurants"
    JSON.parse(access_token.get(search_path(params)).body)
  end

  def search_path(params)
    "/v2/search?#{Rack::Utils.build_query(params)}"
  end

  def offset(total, limit, random = Random.new)
    # yelp only lets you retrieve a max of 1000 results
    max_results = [total, 1000].min
    max_offset = [0, max_results - limit].max
    random.rand(0..max_offset)
  end
end

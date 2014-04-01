require 'sinatra/base'
require_relative './yelp_roulette'

class RouletteApp < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  ROULETTE = YelpRoulette.new(
    consumer_key: ENV['YELP_CONSUMER_KEY'],
    consumer_secret: ENV['YELP_CONSUMER_SECRET'],
    token: ENV['YELP_TOKEN'],
    token_secret: ENV['YELP_TOKEN_SECRET']
  )

  get '/' do
    erb :index
  end

  get '/search' do
    results   = find_food(params)
    @location = results[:location]
    @total    = results[:total]
    @winner, *@losers = results[:restaurants]
    erb :search
  end

  get '/api/search' do
    content_type :json
    find_food(params).to_json
  end

  private

  def find_food(params)
    params ||= {}
    ROULETTE.find_food(
      get_location(params)
    )
  end

  def get_location(params)
    if params[:location].nil? || params[:location].empty?
      # hardcoding rocks!
      "770 Broadway New York, NY"
    else
      params[:location]
    end
  end
end

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
    location = if params[:location].empty?
                 # hardcoding rocks!
                 "770 Broadway New York, NY"
               else
                 params[:location]
               end
    results   = ROULETTE.find_food(location)
    @location = location
    @total    = results[:total]
    @winner, *@losers = results[:restaurants]
    erb :search
  end
end

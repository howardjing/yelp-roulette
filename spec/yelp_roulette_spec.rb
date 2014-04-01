require 'spec_helper'
require_relative '../app/yelp_roulette'

describe YelpRoulette do

  module Fake
    class Consumer
      def initialize(key, secret, site:)
      end
    end

    class AccessToken
      def initialize(consuer, token, token_secret)
      end

      def get(path)
        Response.new(path)
      end
    end

    class Response
      def initialize(path)
        @path = path
      end
      def body
        %Q({"hello":"#{@path}"})
      end
    end
  end

  let(:roulette) {
    YelpRoulette.new consumer_key: 'ck', consumer_secret: 'cs',
                     token: 't', token_secret: 'ts',
                     oauth_consumer: Fake::Consumer,
                     oauth_access_token: Fake::AccessToken
  }

  describe "#new" do
    after do
      roulette
    end
    it "instantiates OAuth::Consumer correctly" do
      expect(Fake::Consumer).to(
        receive(:new).with('ck', 'cs', site: 'http://api.yelp.com')
      )
    end

    it "instantiates OAuth::AccessToken correctly" do
      Fake::Consumer.stub(:new) { 'consumerobj' }
      expect(Fake::AccessToken).to(
        receive(:new).with('consumerobj', 't', 'ts')
      )
    end
  end

  describe "#find_food(location)" do
    before do
      roulette.stub(:total) { 4 }
      roulette.stub(:businesses) { (1..4).to_a }
    end

    it "returns a hash with total number of restaurants" do
      expect(roulette.find_food('good')[:total]).to eq 4
    end

    it "returns a hash with shuffled chosen restaurants" do
      restaurants = roulette.find_food('good')[:restaurants]
      expect(restaurants.length).to eq 4
      (1..4).to_a.each do |n|
        expect(restaurants.include?(n)).to be_true
      end
    end

    it "returns a hash with the given location" do
      expect(roulette.find_food('sup')[:location]).to eq 'sup'
    end
  end

  describe "#total" do
    before do
      roulette.stub(:search) { |arg| { 'total' => { arg: arg } } }
    end

    it "returns the 'total' key from #search" do
      expect(roulette.total(location: 'ny')).to eq(
        { arg: { location: 'ny', limit: 1 } }
      )
    end
  end

  describe "#businesses" do
    before do
      roulette.stub(:search) { |arg| { 'businesses' => { arg: arg } } }
    end
    it "returns the 'businesses' key from #search" do
      expect(roulette.businesses(location: 'here')).to eq(
        { arg: { location: 'here' } }
      )
    end
  end

  describe "#search(path)" do
    it "returns the response body of the given path" do
      expect(roulette.send :search, location: 'earth').to eq(
        { 'hello' => '/v2/search?location=earth&term=restaurants' }
      )
    end
  end

  describe "#search_path(params)" do
    it "returns path based on given params" do
      expect(roulette.send :search_path, hello: 'world').to eq(
        "/v2/search?hello=world"
      )
    end
  end

  describe "#offset" do
    let(:random) { Random.new }

    context "when limit <= total" do
      it "returns 0" do
        expect(random).to receive(:rand).with(0..0).twice
        roulette.send :offset, 10, 20, random
        roulette.send :offset, 10, 10, random
      end
    end

    context "when limit > total" do
      it "returns an integer from 0..(limit - total)" do
        expect(random).to receive(:rand).with(0..20)
        roulette.send :offset, 50, 30, random
      end
    end

    context "when total > 1000" do
      it "returns an integer from 0..1000" do
        expect(random).to receive(:rand).with(0..1000)
        roulette.send :offset, 1001, 0, random
      end
    end
  end
end

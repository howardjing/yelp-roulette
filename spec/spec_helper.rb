ENV['RACK_ENV'] = 'test'
RSpec.configure do |c|
  c.order = 'random'
end

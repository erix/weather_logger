require 'rack/test'
require 'database_cleaner'
require 'json_spec'

ENV['RACK_ENV'] = 'test'

begin
  require_relative '../server/application.rb'
rescue NameError
  require File.expand_path('../server/application.rb', __FILE__)
end

module RSpecMixin
  include Rack::Test::Methods
  def app() App end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.include JsonSpec::Helpers

  c.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  c.before(:each) do
    DatabaseCleaner.start
  end

  c.after(:each) do
    DatabaseCleaner.clean
  end
end

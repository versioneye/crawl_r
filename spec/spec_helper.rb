# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter "/spec"
end

require 'ruby_crawl'
require 'rspec/autorun'
require 'mongoid'
require 'database_cleaner'
require 'rubygems'
require 'bundler'
require 'factory_girl'

require 'vcr'
require 'webmock/rspec'
require 'fakeweb'

require 'versioneye-core'

require 'versioneye/domain_factories/product_factory'
require 'versioneye/domain_factories/user_factory'

Mongoid.load!("config/mongoid.yml", :test)
Mongoid.logger.level = Logger::ERROR

RSpec.configure do |config|

  #RubyCrawl.new

  config.before(:each) do
    FakeWeb.clean_registry

    FakeWeb.allow_net_connect = true
    WebMock.enable!
    WebMock.allow_net_connect!

    DatabaseCleaner.clean

    models = Mongoid.models
    models.each do |model|
      model.all.each(&:delete)
    end
  end

  config.before(:each) do
  end

  #include FactoryGirl into test DSL
  config.include FactoryGirl::Syntax::Methods

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
    c.ignore_localhost = true
    c.hook_into :webmock # or :fakeweb
    c.allow_http_connections_when_no_cassette = true
  end

end

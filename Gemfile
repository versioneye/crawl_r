source "http://rubygems.org"

gem 'versioneye-core'    , :git => 'https://github.com/versioneye/versioneye-core.git', :tag => 'v11.1.6'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

gem 'rufus-scheduler', '3.3.1'

# rubygems for text similarities
gem 'narray', '0.6.1.2'
gem 'tf-idf-similarity', '0.1.5'


group :development do
  gem "shoulda"  , ">= 0"
  gem "rdoc"     , "~> 5.0.0"
  gem "jeweler"  , "~> 2.3.0"
end

group :test do
  gem 'simplecov'       , '~> 0.12.0'
  gem 'rspec'           , '~> 3.5.0'
  gem 'rspec_junit_formatter', '0.2.3'
  gem 'database_cleaner', '~> 1.5.1'
  gem 'factory_girl'    , '~> 4.8.0'
  gem 'capybara'        , '~> 2.11.0'
  gem 'vcr'             , '~> 3.0.1', :require => false
  gem 'webmock'         , '~> 2.3.1', :require => false
  gem 'fakeweb'         , '~> 1.3.0'
end

source "http://rubygems.org"

gem 'versioneye-core', :git => 'https://github.com/versioneye/versioneye-core.git', :tag => 'v12.10.4'
#gem 'versioneye-core'    , :path => "../versioneye-core"

gem 'rufus-scheduler', '3.4.2'

# rubygems for text similarities
gem 'narray', '0.6.1.2'
gem 'tf-idf-similarity', '0.1.6'
gem 'fuzzy_match', '2.0.4'

group :development do
  gem "shoulda"  , ">= 0"
  gem "rdoc"     , "~> 5.1.0"
end

group :test do
  gem 'simplecov'       , '~> 0.14.1'
  gem 'rspec'           , '~> 3.6.0'
  gem 'rspec_junit_formatter', '0.2.3'
  gem 'database_cleaner', '~> 1.6.1'
  gem 'factory_girl'    , '~> 4.8.0'
  gem 'capybara'        , '~> 2.14.0'
  gem 'vcr'             , '~> 3.0.1', :require => false
  gem 'webmock'         , '~> 3.0.1', :require => false
  gem 'fakeweb'         , '~> 1.3.0'
end

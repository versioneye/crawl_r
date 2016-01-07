source "http://rubygems.org"

gem 'bundler'            , '~> 1.11.0'

gem 'versioneye-core'    , :git => 'git@github.com:versioneye/versioneye-core.git', :tag => 'v8.4.2'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

gem 'rufus-scheduler', '3.1.10'

group :development do
  gem "shoulda"  , ">= 0"
  gem "rdoc"     , "~> 4.2.0"
  gem "jeweler"  , "~> 2.0.1"
end

group :test do
  gem 'simplecov'       , '~> 0.10.0'
  gem 'rspec'           , '~> 3.4.0'
  gem 'database_cleaner', '~> 1.5.1'
  gem 'factory_girl'    , '~> 4.5.0'
  gem 'capybara'        , '~> 2.5.0'
  gem 'vcr'             , '~> 2.9.2',  :require => false
  gem 'webmock'         , '~> 1.22.3', :require => false
  gem 'fakeweb'         , '~> 1.3.0'
end

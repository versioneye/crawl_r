source "http://rubygems.org"

gem 'log4r'              , '~> 1.1.0'
gem 'bundler'            , '~> 1.9.1'

gem 'versioneye-core'    , :git => 'git@github.com:versioneye/versioneye-core.git', :tag => 'v7.9.0'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

gem 'rufus-scheduler', '3.1.1'

group :development do
  gem "shoulda"  , ">= 0"
  gem "rdoc"     , "~> 4.2.0"
  gem "jeweler"  , "~> 2.0.1"
end

group :test do
  gem 'simplecov'       , '~> 0.10.0'
  gem 'rspec'           , '~> 3.2.0'
  gem 'database_cleaner', '~> 1.4.0'
  gem 'factory_girl'    , '~> 4.5.0'
  gem 'capybara'        , '~> 2.4.1'
  gem 'vcr'             , '~> 2.9.2',  :require => false
  gem 'webmock'         , '~> 1.21.0', :require => false
  gem 'fakeweb'         , '~> 1.3.0'
end

module Versioneye
  class Crawl

    require 'versioneye/model'

    require './lib/versioneye/crawlers/bower_crawler'
    require './lib/versioneye/crawlers/new_bower_crawler'
    require './lib/versioneye/crawlers/cocoapods_crawler'
    require './lib/versioneye/crawlers/cocoapods_podspec_parser'
    require './lib/versioneye/crawlers/composer_utils'
    require './lib/versioneye/crawlers/crawler_utils'
    require './lib/versioneye/crawlers/github_crawler'
    require './lib/versioneye/crawlers/github_version_crawler'
    require './lib/versioneye/crawlers/npm_crawler'
    require './lib/versioneye/crawlers/npm_license_crawler'
    require './lib/versioneye/crawlers/license_crawler'
    require './lib/versioneye/crawlers/bower_npm_license_sync'

    require './lib/versioneye/crawlers/php/packagist_crawler'
    require './lib/versioneye/crawlers/php/packagist_license_crawler'
    require './lib/versioneye/crawlers/php/packagist_source_crawler'
    require './lib/versioneye/crawlers/php/satis_crawler'
    require './lib/versioneye/crawlers/php/magento_crawler'
    require './lib/versioneye/crawlers/php/firegento_crawler'
    require './lib/versioneye/crawlers/php/tiki_crawler'
    require './lib/versioneye/crawlers/php/branch_cleaner'

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

  end
end

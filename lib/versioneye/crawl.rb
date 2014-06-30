module Versioneye
  class Crawl

    require 'versioneye/model'

    require './lib/versioneye/crawlers/bower_crawler'
    require './lib/versioneye/crawlers/cocoapods_crawler'
    require './lib/versioneye/crawlers/cocoapods_podspec_parser'
    require './lib/versioneye/crawlers/composer_utils'
    require './lib/versioneye/crawlers/crawler_utils'
    require './lib/versioneye/crawlers/github_crawler'
    require './lib/versioneye/crawlers/github_version_crawler'
    require './lib/versioneye/crawlers/npm_crawler'
    require './lib/versioneye/crawlers/packagist_crawler'
    require './lib/versioneye/crawlers/packagist_license_crawler'
    require './lib/versioneye/crawlers/satis_crawler'
    require './lib/versioneye/crawlers/tiki_crawler'
    require './lib/versioneye/crawlers/firegento_crawler'

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

  end
end

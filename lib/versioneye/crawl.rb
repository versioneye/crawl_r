module Versioneye
  class Crawl

    require 'versioneye/crawlers/bower_crawler'
    require 'versioneye/crawlers/cocoapods_crawler'
    require 'versioneye/crawlers/cocoapods_podspec_parser'
    require 'versioneye/crawlers/composer_utils'
    require 'versioneye/crawlers/crawler_utils'
    require 'versioneye/crawlers/git_crawler'
    require 'versioneye/crawlers/github_crawler'
    require 'versioneye/crawlers/github_version_crawler'
    require 'versioneye/crawlers/npm_crawler'
    require 'versioneye/crawlers/packagist_crawler'
    require 'versioneye/crawlers/tiki_crawler'

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

  end
end

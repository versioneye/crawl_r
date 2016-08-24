require 'timeout'

module Versioneye
  class Crawl

    require 'versioneye/model'

    require './lib/versioneye/crawlers/spdx_crawler'
    require './lib/versioneye/crawlers/coreos_crawler'
    require './lib/versioneye/crawlers/cocoapods_crawler'
    require './lib/versioneye/crawlers/cocoapods_podspec_parser'
    require './lib/versioneye/crawlers/crawler_utils'
    require './lib/versioneye/crawlers/github_crawler'
    require './lib/versioneye/crawlers/github_version_crawler'
    require './lib/versioneye/crawlers/npm_crawler'
    require './lib/versioneye/crawlers/license_crawler'
    require './lib/versioneye/crawlers/bower_npm_license_sync'
    require './lib/versioneye/crawlers/chef_crawler'
    require './lib/versioneye/crawlers/pom_crawler'
    require './lib/versioneye/crawlers/phpeye_crawler'
    require './lib/versioneye/crawlers/nuget_crawler'
    require './lib/versioneye/crawlers/cpan_crawler'

    require './lib/versioneye/crawlers/php/packagist_crawler'
    require './lib/versioneye/crawlers/php/packagist_license_crawler'
    require './lib/versioneye/crawlers/php/packagist_source_crawler'
    require './lib/versioneye/crawlers/php/satis_crawler'
    require './lib/versioneye/crawlers/php/magento_crawler'
    require './lib/versioneye/crawlers/php/firegento_crawler'
    require './lib/versioneye/crawlers/php/tiki_crawler'
    require './lib/versioneye/crawlers/php/spryker_crawler'
    require './lib/versioneye/crawlers/php/zendframework_crawler'
    require './lib/versioneye/crawlers/php/wpackagist_crawler'
    require './lib/versioneye/crawlers/php/branch_cleaner'
    require './lib/versioneye/crawlers/php/composer_utils'

    require './lib/versioneye/crawlers/bower/bower'
    require './lib/versioneye/crawlers/bower/bower_source_checker'
    require './lib/versioneye/crawlers/bower/bower_projects_crawler'
    require './lib/versioneye/crawlers/bower/bower_versions_crawler'
    require './lib/versioneye/crawlers/bower/bower_tag_crawler'
    require './lib/versioneye/crawlers/bower/bower_starter'

    require './lib/versioneye/producers/producer'
    require './lib/versioneye/producers/common_crawl_producer'
    require './lib/versioneye/producers/packagist_crawl_producer'
    require './lib/versioneye/producers/npm_crawl_producer'
    require './lib/versioneye/producers/satis_crawl_producer'
    require './lib/versioneye/producers/bower_crawl_producer'
    require './lib/versioneye/producers/nuget_crawl_producer'

    require './lib/versioneye/workers/worker'
    require './lib/versioneye/workers/common_crawl_worker'
    require './lib/versioneye/workers/packagist_crawl_worker'
    require './lib/versioneye/workers/npm_crawl_worker'
    require './lib/versioneye/workers/satis_crawl_worker'
    require './lib/versioneye/workers/bower_crawl_worker'
    require './lib/versioneye/workers/nuget_crawl_worker'

    require './lib/versioneye/utils/license_matcher'

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

    def self.logger
      Versioneye::Log.instance.log
    end

    def logger
      Versioneye::Log.instance.log
    end
    
    def self.fetch_json( url, ttl = 5)
      res = Timeout::timeout(ttl) { HTTParty.get(url) }
      if res.code != 200
        self.logger.error "Failed to fetch JSON doc from: #{url} - #{res}"
        return nil
      end

      JSON.parse(res.body, {symbolize_names: true})
    rescue => e
      logger.error "Failed to parse JSON response from #{url} - #{e.message.to_s}"
      logger.error e.backtrace.join('\n')
      nil
    end

    def self.post_json(url, options, ttl = 5)
      res = Timeout::timeout(ttl) { HTTParty.post(url, options) }
      if res.code > 205
        logger.error "Failed to post data to the url: #{url}, #{res.code} - #{res.message}\n#{options}"
        return
      end
  
      return if res.body.to_s.empty?
      JSON.parse(res.body, {symbolize_names: true})
    rescue => e
      logger.error "Failed to post data to #{url} - #{options}"
      logger.error e.message.to_s
      logger.error e.backtrace.join('\n')
      nil
    end
  end
end

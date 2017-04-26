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
    require './lib/versioneye/crawlers/crates_crawler'

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
    require './lib/versioneye/producers/crates_crawl_producer'

    require './lib/versioneye/workers/worker'
    require './lib/versioneye/workers/common_crawl_worker'
    require './lib/versioneye/workers/packagist_crawl_worker'
    require './lib/versioneye/workers/npm_crawl_worker'
    require './lib/versioneye/workers/satis_crawl_worker'
    require './lib/versioneye/workers/bower_crawl_worker'
    require './lib/versioneye/workers/nuget_crawl_worker'
    require './lib/versioneye/workers/crates_crawl_worker'

    require './lib/versioneye/utils/license_matcher'
    require './lib/versioneye/utils/python_license_detector'
    require './lib/versioneye/crawlers/github_license_crawler'
    require './lib/versioneye/crawlers/codeplex_license_crawler'

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


    def self.parse_url url_text
      uri = URI.parse(url_text)

      return uri if uri.is_a?(URI::HTTPS) or uri.is_a?(URI::HTTP)
      return nil
    rescue
      logger.error "Not valid url: #{url_text}"
      nil
    end

    def self.fetch url
     HTTParty.get url, { timeout: 5 }
    rescue
      logger.error "failed to fetch data from #{url}"
      nil
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


    # updates or adds a new detected licenses for the product
    # params:
    #   prod_dt - {language: Str, prod_key: Str, version: Str, url: Str}
    #   matches - [[spdx_id, confidence, url]]
    #   min_confidence - 0.9
    def self.save_license_updates(prod_dt, matches, min_confidence, comment = "")
      return false if matches.nil?

      matches.to_a.each do |spdx_id, score, url|
        if score < min_confidence
          logger.warn "save_license_updates: low confidence #{prod_dt.to_s} => #{spdx_id} : #{score} , #{url}"
          next
        end

        logger.info "save_license_updates: updating #{prod_dt.to_s} => #{spdx_id}"
        upsert_license_data(
          prod_dt[:language], prod_dt[:prod_key], prod_dt[:version], spdx_id, url,
          comment.to_s.strip
        )
      end

      true
    end

    #tries to update license with unknown id otherwise will create a new license
    def self.upsert_license_data(language, prod_key, version, spdx_id, url, comment)
      prod_licenses = License.where(language: language, prod_key: prod_key, version: version)
      lic_db = prod_licenses.where(name: 'Nuget Unknown').first #try to update unknown license
      lic_db = prod_licenses.where(name: /Unknown/i).first  unless lic_db #try to update existing Unknown license
      lic_db = prod_licenses.where(spdx_id: spdx_id).first unless lic_db #try to upate existing
      lic_db = prod_licenses.first_or_create unless lic_db #create a new model if no matches

      lic_db.update(
        name: spdx_id,
        spdx_id: spdx_id,
        url: url,
        comments: comment
      )
      lic_db.save
      lic_db
    end



  end
end

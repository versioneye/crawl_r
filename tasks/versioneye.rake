# require 'ruby_crawl'

require 'rufus-scheduler'
require 'versioneye-core'
require './lib/ruby_crawl'

namespace :versioneye do

  desc "start scheduler for crawl_r"
  task :scheduler_crawl_r do
    RubyCrawl.new
    scheduler = Rufus::Scheduler.new
    env = Settings.instance.environment

    value = GlobalSetting.get(env, 'SCHEDULE_CRAWL_COCOAPODS')
    # value = '1 * * * *' if value.to_s.empty?
    if !value.to_s.empty?
      scheduler.cron value do
        CommonCrawlProducer.new "cocoa_pods_1"
      end
    end

    value = GlobalSetting.get(env, 'satis_schedule')
    # value = '1 * * * *' if value.to_s.empty?
    if !value.to_s.empty?
      scheduler.cron value do
        CommonCrawlProducer.new "satis_1"
      end
    end

    scheduler.join
    while 1 == 1
      p "keep alive rake task"
      sleep 30
    end
  end

  desc "start scheduler for crawl_r prod"
  task :scheduler_crawl_r_prod do
    RubyCrawl.new
    scheduler = Rufus::Scheduler.new
    env = Settings.instance.environment


    # Crawl it once a hour. A crawl takes ~ 1 minutes!
    value = '20 * * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        SatisCrawlProducer.new '::tiki::'
      end
    end

    # Crawl it once a hour. A crawl takes ~ 3 minutes!
    value = '22 * * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        SatisCrawlProducer.new '::firegento::'
      end
    end

    # Crawl it once a hour. A crawl takes ~ 3 minutes!
    value = '25 * * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        SatisCrawlProducer.new '::magento::'
      end
    end

    # Crawl it once a hour. A crawl takes ~ 1 minute!
    value = '29 * * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        SatisCrawlProducer.new '::zendframework::'
      end
    end

    # Crawl it once a hour. A crawl takes ~ 3 minutes!
    value = '30 * * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        CommonCrawlProducer.new '::github::'
      end
    end


    # Crawl it once a day. A crawl takes ~ 20 minutes!
    value = GlobalSetting.get(env, 'SCHEDULE_CRAWL_COCOAPODS')
    value = '1 0 * * *' if value.to_s.empty?
    if !value.to_s.empty?
      scheduler.cron value do
        CommonCrawlProducer.new "cocoa_pods_1"
      end
    end

    # This crawl takes almost 7 hours
    value = '0 1 * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        NpmCrawlProducer.new '::npm::'
      end
    end

    value = '11 2 * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        BowerCrawlProducer.new '::bower::'
      end
    end

    value = '0 3 * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        PackagistCrawlProducer.new '::packagist::'
      end
    end

    value = '1 4 * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        BiicodeCrawlProducer.new '::biicode::'
      end
    end

    value = '1 5 * * *'
    if !value.to_s.empty?
      scheduler.cron value do
        CommonCrawlProducer.new '::chef::'
      end
    end

    scheduler.join
    while 1 == 1
      p "keep alive rake task"
      sleep 30
    end
  end

  # ***** Crawler Tasks *****

  desc "crawl Chef"
  task :crawl_chef do
    puts "START to crawle Chef repository"
    RubyCrawl.new
    ChefCrawler.crawl
    puts "---"
  end

  desc "crawl Packagist"
  task :crawl_packagist do
    puts "START to crawle Packagist repository"
    RubyCrawl.new
    PackagistCrawler.crawl
    puts "---"
  end

  desc "crawl Tiki"
  task :crawl_tiki do
    puts "START to crawle Tiki repository"
    RubyCrawl.new
    TikiCrawler.crawl
    puts "---"
  end

  desc "crawl Firegento"
  task :crawl_firegento do
    puts "START to crawle Firegento repository"
    RubyCrawl.new
    FiregentoCrawler.crawl
    puts "---"
  end

  desc "crawl Magento"
  task :crawl_magento do
    puts "START to crawle Magento repository"
    RubyCrawl.new
    MagentoCrawler.crawl
    puts "---"
  end

  desc "crawl Zendframework"
  task :crawl_zendframework do
    puts "START to crawle Zendframework repository"
    RubyCrawl.new
    ZendframeworkCrawler.crawl
    puts "---"
  end

  desc "crawl NPM"
  task :crawl_npm do
    puts "START to crawle NPM repository"
    RubyCrawl.new
    NpmCrawler.crawl
    puts "---"
  end

  desc "crawl NPM licenses only"
  task :crawl_npm_licenses do
    puts "START to crawle NPM repository"
    RubyCrawl.new
    NpmLicenseCrawler.crawl
    puts "---"
  end

  desc "crawl Cococapods"
  task :crawl_cocoapods do
    puts "START to crawle CocoaPods repository"
    RubyCrawl.new
    CocoapodsCrawler.crawl
    GithubVersionCrawler.crawl
    puts "---"
  end

  desc "crawl GitHub"
  task :crawl_github do
    puts "START to crawle GitHub repository"
    RubyCrawl.new
    GithubCrawler.crawl
    puts "---"
  end

  desc "crawl Licenses"
  task :crawl_licenses do
    puts "START to crawle licenses "
    RubyCrawl.new
    LicenseCrawler.crawl
    puts "---"
  end

  desc "Sync NPM to Bower Licenses"
  task :bower_npm_license_sync do
    puts "START to sync NPM - Bower Licenses "
    RubyCrawl.new
    BowerNpmLicenseSync.sync
    puts "---"
  end


  desc "crawl Bower.io"
  task :crawl_bower do
    puts "START to crawle Bower.io repository"
    RubyCrawl.new
    BowerStarter.crawl
    puts "---"
  end

  desc "Bower source checker "
  task :crawl_bower_source_checker do
    puts "START bower souce checker"
    RubyCrawl.new
    reiz = User.find_by_username('reiz')
    BowerSourceChecker.crawl reiz.github_token
    puts "---"
  end

  desc "Bower projects crawler "
  task :crawl_bower_projects do
    puts "START bower projects crawler"
    RubyCrawl.new
    reiz = User.find_by_username('reiz')
    BowerProjectsCrawler.crawl reiz.github_token
    puts "---"
  end

  desc "Bower versions crawler "
  task :crawl_bower_versions do
    puts "START bower versions crawler"
    RubyCrawl.new
    reiz = User.find_by_username('reiz')
    BowerVersionsCrawler.crawl reiz.github_token
    puts "---"
  end

  desc "Bower tag crawler "
  task :crawl_bower_tags do
    puts "START bower tag crawler"
    RubyCrawl.new
    reiz = User.find_by_username('reiz')
    BowerTagCrawler.crawl reiz.github_token
    puts "---"
  end



  # --- Workers ---

  desc "Start CommonCrawlWorker"
  task :common_crawl_worker do
    puts "START CommonCrawlWorker"
    RubyCrawl.new
    CommonCrawlWorker.new.work
    puts "---"
  end

  desc "Start PackagistCrawlWorker"
  task :packagist_crawl_worker do
    puts "START PackagistCrawlWorker"
    RubyCrawl.new
    PackagistCrawlWorker.new.work
    puts "---"
  end

  desc "Start SatisCrawlWorker"
  task :satis_crawl_worker do
    puts "START SatisCrawlWorker"
    RubyCrawl.new
    SatisCrawlWorker.new.work
    puts "---"
  end

  desc "Start BiicodeCrawlWorker"
  task :biicode_crawl_worker do
    puts "START BiicodeCrawlWorker"
    RubyCrawl.new
    BiicodeCrawlWorker.new.work
    puts "---"
  end

  desc "Start NpmCrawlWorker"
  task :npm_crawl_worker do
    puts "START NpmCrawlWorker"
    RubyCrawl.new
    NpmCrawlWorker.new.work
    puts "--- THE END ---"
  end

  desc "Start BowerCrawlWorker"
  task :bower_crawl_worker do
    puts "START BowerCrawlWorker"
    RubyCrawl.new
    BowerCrawlWorker.new.work
    puts "--- THE END ---"
  end


end

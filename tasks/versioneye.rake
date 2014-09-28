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

    scheduler.join
    while 1 == 1
      p "keep alive rake task"
      sleep 30
    end
  end

  # ***** Crawler Tasks *****

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

  desc "crawl Bower.io"
  task :crawl_bower do
    puts "START to crawle Bower.io repository"
    RubyCrawl.new
    reiz = User.find_by_username('reiz')
    BowerCrawler.crawl reiz.github_token
    puts "---"
  end


  # --- Workers ---

  desc "Start CocoaPodsWorker"
  task :cocoa_pods_worker do
    puts "START cocoa_pods_worker"
    RubyCrawl.new
    CommonCrawlWorker.new.work
    puts "---"
  end


end

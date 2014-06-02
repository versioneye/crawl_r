# require 'ruby_crawl'

require 'versioneye-core'
require './lib/ruby_crawl'

namespace :versioneye do

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

  desc "crawl NPM"
  task :crawl_npm do
    puts "START to crawle NPM repository"
    RubyCrawl.new
    NpmCrawler.crawl
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

end

# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "ruby_crawl"
  gem.homepage = "http://github.com/reiz/ruby_crawl"
  gem.license = "MIT"
  gem.summary = %Q{VersionEye crawlers implemented in Ruby}
  gem.description = %Q{VersionEye crawlers implemented in Ruby}
  gem.email = "robert.reiz.81@gmail.com"
  gem.authors = ["reiz"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby_crawl #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir.glob('lib/*.rake').each { |r| import r }


namespace :versioneye do

  require 'versioneye-core'
  require 'ruby_crawl'

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
    TikiCrawler.crawl
    puts "---"
  end

  desc "crawl NPM"
  task :crawl_npm do
    puts "START to crawle NPM repository"
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
    GithubCrawler.crawl
    puts "---"
  end

  desc "crawl Bower.io"
  task :crawl_bower do
    puts "START to crawle Bower.io repository"
    reiz = User.find_by_username('reiz')
    BowerCrawler.crawl reiz.github_token
    puts "---"
  end

end

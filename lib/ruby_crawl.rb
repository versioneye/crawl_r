require 'mongoid'
require 'httparty'

require 'settings'
require './lib/versioneye/crawl'

require 'versioneye-core'



class RubyCrawl

  def initialize
    puts "initialize ruby_crawl"
    VersioneyeCore.new
    init_settings
    init_logger
    init_mongodb
  end

  def init_logger
    Versioneye::Log.instance.log
  end

  def init_mongodb
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  end

  def init_settings
    Settings.instance.load_settings
    Settings.instance.reload_from_db GlobalSetting.new
  end

end

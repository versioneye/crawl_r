require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'httparty'

require 'settings'
require './lib/versioneye/crawl'


class RubyCrawl

  def initialize
    puts "initialize ruby_crawl"
    init_logger
    init_mongodb
    init_settings
  end

  def init_logger
    Log4r::Configurator.load_xml_file('config/log4r.xml')
  end

  def init_mongodb
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  end

  def init_settings
    Settings.instance.reload_from_db GlobalSetting.new
  end

end

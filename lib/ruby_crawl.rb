require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'httparty'

require 'settings'


class RubyCrawl

  def initialize
    puts "initialize ruby_crawl"
    init_logger
    init_mongodb
  end

  def init_logger
    Log4r::Configurator.load_xml_file('config/log4r.xml')
  end

  def init_mongodb
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  end

end

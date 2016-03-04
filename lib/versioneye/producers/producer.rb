class Producer

  require 'bunny'

  def get_connection
    connection_url = "amqp://#{Settings.instance.rabbitmq_addr}:#{Settings.instance.rabbitmq_port}"
    Bunny.new( connection_url )
  end

  def self.log
    Versioneye::Log.instance.log
  end

  def log
    Versioneye::Log.instance.log
  end

  def self.cache
    Versioneye::Cache.instance.mc
  end

  def cache
    Versioneye::Cache.instance.mc
  end

  def multi_log msg
    puts msg
    log.info msg
  end

end

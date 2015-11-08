class Worker

  require 'bunny'

  def get_connection
    Bunny.new("amqp://#{Settings.instance.rabbitmq_addr}:#{Settings.instance.rabbitmq_port}")
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

  private

    def reload_settings
      Settings.instance.reload_from_db GlobalSetting.new
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end

end

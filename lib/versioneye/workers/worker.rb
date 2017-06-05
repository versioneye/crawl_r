require 'json'

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

  def multi_log msg
    puts msg
    log.info msg
  end

  def start_worker(worker_name, queue_name, durable = true)
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue(queue_name, :durable => durable)

    multi_log " [*] #{worker_name} waiting for messages in #{queue_name}. To exit press CTRL+C"


    queue.subscribe(ack: true, block: true) do |delivery_info, properties, message|
      multi_log " [x] #{worker_name} received #{message}"

      process_work message
      channel.ack(delivery_info.delivery_tag)

      multi_log " [x] #{worker_name} job done #{message}"
    end

  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    connection.close
  end

  def parse_json_safely json_txt
    JSON.parse(json_txt.to_s, symbolize_names: true)
  rescue => e
    log.error "Failed to parse #{json_txt}"
    nil
  end

  private

    def reload_settings
      Settings.instance.reload_from_db GlobalSetting.new
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end

end

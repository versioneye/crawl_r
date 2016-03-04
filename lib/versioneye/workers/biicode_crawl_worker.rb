class BiicodeCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("biicode_crawl", :durable => true)

    multi_log " [*] BiicodeCrawlWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] BiicodeCrawlWorker received #{message}"
        process_work message
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] BiicodeCrawlWorker job done #{message}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_work package_name
    BiicodeCrawler.crawl
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

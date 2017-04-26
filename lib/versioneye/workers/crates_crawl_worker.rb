class CratesCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("crates_crawl", :durable => true)

    multi_log " [*] CratesCrawlWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] CratesCrawlWorker received #{message}"
        process_work message
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] CratesCrawlWorker job done #{message}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_work package_name
    return nil if package_name.to_s.empty?

    if package_name.eql?('::crates::')
      CratesCrawler.crawl
    else
      CratesCrawler.crawle_package package_name
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

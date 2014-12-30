class NpmCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("npm_crawl", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, message|
        puts " [x] Received #{message}"

        process_work message

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_work package_name
    return nil if package_name.to_s.empty?

    if package_name.eql?('::npm::')
      NpmCrawler.crawl 
    else 
      NpmCrawler.crawle_package package_name
    end
  rescue => e
    p e.message 
    p e.backtrace.join("\n")
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

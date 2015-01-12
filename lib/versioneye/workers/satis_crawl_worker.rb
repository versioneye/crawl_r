class SatisCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("satis_crawl", :durable => true)

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
    
    if package_name.eql?('::tiki::')
      TikiCrawler.crawl
    elsif package_name.eql?('::firegento::')
      FiregentoCrawler.crawl 
    elsif package_name.eql?('::magento::')
      MagentoCrawler.crawl 
    elsif package_name.eql?('::zendframework::')
      ZendframeworkCrawler.crawl 
    end
    
    log.info "Crawl done for #{package_name}"
  rescue => e
    p e.message 
    p e.backtrace.join("\n")
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

class SatisCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("satis_crawl", :durable => true)

    multi_log " [*] SatisCrawlWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] SatisCrawlWorker received #{message}"
        process_work message
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] SatisCrawlWorker job done #{message}"
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
    elsif package_name.eql?('::spryker::')
      SprykerCrawler.crawl
    elsif package_name.eql?('::wpackagist::')
      WpackagistCrawler.crawl
    end

    log.info "Crawl done for #{package_name}"
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

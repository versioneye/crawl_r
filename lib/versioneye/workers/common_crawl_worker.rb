class CommonCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("common_crawl", :durable => true)

    multi_log " [*] CommonCrawlWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] CommonCrawlWorker received #{message}"
        process_work message
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] CommonCrawlWorker job done #{message}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_work message
    return nil if message.to_s.empty?

    if message.eql?("cocoa_pods_1")
      CocoapodsCrawler.crawl
      GithubVersionCrawler.crawl
    elsif message.eql?('satis_1')
      base_url = GlobalSetting.get env, 'satis_base_url'
      crawler  = SatisCrawler.new base_url, "Satis Page"
      crawler.crawl
    elsif message.eql?('::github::')
      GithubCrawler.crawl
    elsif message.eql?('::chef::')
      ChefCrawler.crawl
    elsif message.eql?('::coreos::')
      CoreosCrawler.crawl
    elsif message.eql?('::phpeye::')
      PhpeyeCrawler.crawl
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  private


    def multi_log log_msg
      puts log_msg
      log.info log_msg
    end


end

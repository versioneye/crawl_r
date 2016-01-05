class BowerCrawlWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("bower_crawl", :durable => true)

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

    user = User.find_by_email "reiz@versioneye.com"
    token = user.github_token

    if package_name.eql?('::bower::')
      BowerStarter.crawl(token, 'https://bower.herokuapp.com/packages', true )
    else
      sps  = package_name.split("::")
      name = sps[0]
      url  = sps[1]
      BowerStarter.register_package name, url, token
    end
  rescue => e
    p e.message
    p e.backtrace.join("\n")
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

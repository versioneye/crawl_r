class TikiCrawler < SatisCrawler

  def self.logger
    ActiveSupport::BufferedLogger.new('log/tiki.log')
  end

  @@base_url = 'http://composer.tiki.org/'
  @@link_name = 'Tiki Page'


  def self.crawl
    start_time = Time.now
    packages = get_first_level_list
    packages.each do |package|
      crawle_package package
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def self.get_first_level_list
    body = JSON.parse HTTParty.get("#{@@base_url}/packages.json" ).response.body
    body['packages']
  rescue => e
    self.logger.error "ERROR in get_first_level_list of #{@@base_url}: Message: #{e.message}"
    self.logger.error e.backtrace.join('\n')
    nil
  end


end

class SprykerCrawler < SatisCrawler

  def logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/spryker.log", 10).log
    end
    @@log
  end

  A_BASE_URL  = 'https://code.spryker.com/repo/private'
  A_LINK_NAME = 'Spryker Page'


  def self.crawl base_url = A_BASE_URL, link_name = A_LINK_NAME
    crawler = SprykerCrawler.new base_url, link_name
    crawler.crawl
  end

  def crawl
    start_time = Time.now
    packages = get_first_level_list if packages.nil?
    packages.each do |package_name|
      crawle_package_url package_name
    end
    duration = Time.now - start_time
    logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def crawle_package_url package_name
    url = "#{A_BASE_URL}/p/#{package_name}.json"
    body = JSON.parse HTTParty.get( url ).response.body
    packages = body['packages']
    packages.each do |package|
      crawle_package package
    end
  rescue => e
    logger.error "ERROR in crawle_package_url Message:   #{e.message}"
    logger.error e.backtrace.join("\n")
  end


end

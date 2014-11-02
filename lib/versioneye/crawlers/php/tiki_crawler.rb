class TikiCrawler < SatisCrawler

  def logger
    ActiveSupport::BufferedLogger.new('log/tiki.log')
  end

  A_BASE_URL  = 'http://composer.tiki.org/'
  A_LINK_NAME = 'Tiki Page'


  def self.crawl
    crawler = TikiCrawler.new A_BASE_URL, A_LINK_NAME
    crawler.crawl
  end


  def get_first_level_list
    body = JSON.parse HTTParty.get("#{@base_url}/packages.json" ).response.body
    body['packages']
  rescue => e
    logger.error "ERROR in get_first_level_list of #{@base_url}: Message: #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  private


    def homepage_url product
      @base_url
    end

end

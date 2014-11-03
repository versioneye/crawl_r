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


end

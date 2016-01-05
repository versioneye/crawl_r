class TikiCrawler < SatisCrawler

  def logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/tiki.log", 10).log
    end
    @@log
  end

  A_BASE_URL  = 'http://composer.tiki.org/'
  A_LINK_NAME = 'Tiki Page'


  def self.crawl
    crawler = TikiCrawler.new A_BASE_URL, A_LINK_NAME
    crawler.crawl
  end


end

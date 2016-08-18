class MagentoCrawler < SatisCrawler

  def logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/magento.log", 10).log
    end
    @@log
  end

  A_BASE_URL  = 'http://packages.magento.com'
  A_LINK_NAME = 'Magento Page'


  def self.crawl packages = nil, early_exit = false
    crawler = MagentoCrawler.new A_BASE_URL, A_LINK_NAME
    crawler.crawl packages, early_exit
  end


end

class HexCrawlWorker < Worker


  A_QUEUE_NAME = 'hex_crawl'

  attr_reader :name

  def initialize
    @name = self.class.name.to_s
  end

  def work
    start_worker( @name, A_QUEUE_NAME)
  end

  def process_work message
    HexCrawler.crawl
  end


end

class CpanCrawlWorker < Worker
  A_QUEUE_NAME = 'cpan_release_crawl'

  attr_reader :name

  def initialize
    @name = self.class.name.to_s
  end

  def work
    start_worker(@name, A_QUEUE_NAME)
  end

  # crawl CPAN release and insert result into database
  # params:
  #   artifact_id: String, csv of author_id and release_id
  def process_work( artifact_id )
    author_id, release_id = artifact_id.to_s.split(',')

    prod_db = CpanCrawler.crawl_release(author_id, release_id)
    if prod_db
      log.info "#{@name} - added #{artifact_id} => #{prod_db}"
    else
      log.error "#{@name} - failed to fetch #{artifact_id}"
    end

    true
  rescue => e
    log.error "#{@name} - failed to process #{artifact_id}"
    log.error "\treason: #{e.message}"
    log.error e.backtrace.join('\n')
    false
  end

end

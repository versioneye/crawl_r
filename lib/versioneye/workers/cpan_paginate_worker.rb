class CpanPaginateWorker < Worker
  A_QUEUE_NAME = 'cpan_paginate_crawl'

  attr_reader :name

  def initialize
    @name = self.class.name.to_s
  end

  def work
    start_worker(@name, A_QUEUE_NAME)
  end

  # fetches a list of CPAN release artifacts over the time period
  # and turns each artifact into task of CpanCrawlWorker
  # params:
  #   msg - JSON string, with given fields
  #     :all - Boolean, required, true if it should fetch all the releases
  #     :from_days_ago - integer, optional, oldest release in days to fetch
  #     :to_days_ago   - integer, optional, newest release in days to fetch, default 0
  def process_work( msg )
    params = parse_json_safely msg
    if params.nil?
      log.error "#{@name} - got empty message, will abort the process"
      return
    end

    CpanCrawler.crawl(params[:all], params[:from_days_ago].to_i, params[:to_days_ago].to_i)

    true
  rescue => e
    log.error "#{@name} - failed to process {msg}"
    log.error "\treason: #{e.message}"
    log.error e.backtrace.join('\n')
    false
  end

end

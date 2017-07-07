class CpanPaginateProducer < Producer
  A_QUEUE_NAME = 'cpan_paginate_crawl'

  attr_reader :name

  # start a new paginate tasks to fetch releases for timeperiod
  # params:
  #   all - Boolean, true => fetch all the releases from the beginning
  #   from_days_ago - Integer, since when to start paginate
  #   to_days_ago - Integer, to when it should keep paginate, 0 = today
  def initialize(all, from_days_ago = 2, to_days_ago = 0)
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue = channel.queue(A_QUEUE_NAME, :durable => true)

    msg = {
      all: all,
      from_days_ago: from_days_ago,
      to_days_ago: to_days_ago
    }.to_json

    queue.publish(msg, persistent: true)
    multi_log " [x] #{name} sent #{msg} to #{A_QUEUE_NAME}"
    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
  end
end

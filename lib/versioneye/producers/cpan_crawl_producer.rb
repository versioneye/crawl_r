class CpanCrawlProducer < Producer
  A_QUEUE_NAME = 'cpan_release_crawl'

  attr_reader :name

  # params:
  #   author_id = String, author ID on Cpan
  #   release_id = String, uniqueu release ID of the package
  def initialize(author_id, release_id)
    @name = self.class.name

    artifact_id = "#{author_id},#{release_id}".strip
    if artifact_id.size < 2
      multi_log " [-] #{@name} - missing author_id or release_id #{artifact_id}"
      return
    end

    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue(A_QUEUE_NAME, :durable => true)

    queue.publish(artifact_id, :persistent => true)

    multi_log " [x] #{@name} sent #{artifact_id} to #{A_QUEUE_NAME}"

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end
end

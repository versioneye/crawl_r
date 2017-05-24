class GithubLicenseCrawlProducer < Producer
  A_QUEUE_NAME = 'github_license_crawl'

  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue(A_QUEUE_NAME, :durable => true)

    queue.publish(msg.to_json, :persistent => true)

    multi_log " [x] #{self.class.name} sent #{msg}"

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.build_msg(product, repo_url)
    repo_url = repo_url.to_s.gsub(/https?:\/\//i, '').to_s.strip
    host, owner, repo, _ = repo_url.split('/', 4)
    unless host.to_s =~ /github/i
      log.error "build_golang_msg: #{host} is not github domain"
      return
    end

    {
      language: product[:language],
      prod_key: product[:prod_key],
      repo_owner: owner,
      repo_name: repo
    }
  end
end

class GosearchVersionProducer < Producer
  A_QUEUE_NAME = 'gosearch_version_crawl'

  attr_reader :name


  # params:
  #   msg - output of GosearchVersionProducer.build_message(pkg_id)
  def initialize msg
    return if msg.nil? or msg.empty?

    @name = self.class.name

    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue(A_QUEUE_NAME, :durable => true)

    queue.publish(msg.to_json, :persistent => true)

    multi_log " [x] #{@name} sent #{msg} to #{A_QUEUE_NAME}"

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  # builds valid message for Go package
  # for accepted format check VersionCrawlerWorker.process_work
  def self.build_message(prod_key, user_email = nil, login = nil)
    return if prod_key.to_s.empty?

    gopkg = Product.where(
      language: Product::A_LANGUAGE_GO,
      prod_key: prod_key
    ).first
    if gopkg.nil?
      log.error "Found no such Go package: #{prod_key}"
      return
    end

    domain, owner, repo, _ = gopkg[:repo_name].split('/', 4)
    unless domain =~ /github/i
      log.error "#{prod_key} is not github package"
      return
    end

    if owner.nil? or repo.nil?
      log.error "Repo name doesnt include owner and repo_name: #{gopkg}"
      return
    end

    msg = {
      language: gopkg[:language],
      prod_key: gopkg[:prod_key],
      owner: owner.to_s,
      repo: repo.to_s,
    }

    msg[:user_email] = user_email unless user_email.to_s.empty?
    msg[:login] = login unless login.nil?

    msg
  end
end

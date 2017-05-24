require 'json'

class GithubLicenseCrawlWorker < Worker
  A_QUEUE_NAME = 'github_license_crawl'

  attr_reader :name, :lm

  def initialize
    super

    @name = self.class.name
    @lm   = LicenseMatcher.new
  end

  #TODO: refactor into parent class
  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue(A_QUEUE_NAME, :durable => true)

    multi_log " [*] #{@name} waiting for messages in #{A_QUEUE_NAME}. To exit press CTRL+C"

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] #{@name} received #{message}"
        process_work message
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] #{@name} job done #{message}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end

  # params:
  # message - json doc with given structure
  #           {
  #             language: String,
  #             prod_key: String,
  #             repo_owner: String,
  #             repo_name: String
  #           }
  def process_work message
    return nil if message.nil?
    task_params = parse_json_safely message
    if task_params.nil?
      log.error "#{@name} process_work: failed to parse message #{message}"
      return
    end

    GithubLicenseCrawler.crawl_product_commit_tree(
      task_params[:language], task_params[:prod_key],
      task_params[:repo_owner], task_params[:repo_name],
      0.9, @lm
    )

  end

  def parse_json_safely(json_txt)
    JSON.parse(json_txt.to_s, symbolize_names: true)
  rescue => e
    log.error e.message
    nil
  end

end

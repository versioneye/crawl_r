class VersionCrawlerWorker < Worker
  A_QUEUE_NAME = 'version_crawl'

  attr_reader :name

  def initialize
    @name = self.class.name.to_s
  end

  def work
    start_worker( @name, A_QUEUE_NAME)
  end

  # handles message and fires version crawler
  # params:
  #   message = json string with given structure
  #             {
  #               owner: String, # a owner of repo, i.e versioneye
  #               repo: String,  # a name of repo, i.e versioneye-core
  #               language: String, # a language of Product model
  #               prod_key: String, # a product_key of Product
  #               user_email: nil/String # optional, will users Github token
  #               login: nil/HashMap     # optional, login data for Octokit
  #                                        check GithubVersionFetcher.initialize
  #               use_env_login: Boolean # optional, default true, use Github tokens from Settings.json
  #             }
  def process_work message
    task_dt = parse_json_safely message

    use_env_login = task_dt.fetch(:use_env_login, true)
    auth_dt = get_auth_by_email(task_dt[:user_email])
    auth_dt ||= task_dt[:login]
    if use_env_login == false and (auth_dt.nil? or auth_dt.empty?)
      log.error "#{@name} - message had no authorization data and not allowed to use env authorization data"
      return
    end

    # delete sensitive data, so we can lazily log it out
    task_dt.delete(:login)
    task_dt.delete(:user_email)

    product = Product.where(
      language: task_dt[:language], prod_key: task_dt[:prod_key]
    ).first
    if product.nil?
      log.error "#{@name} - found no product for #{task_dt}"
      return
    end

    api_client = GithubVersionFetcher.new(auth_dt, use_env_login)
    res = GithubVersionCrawler.crawl_for_product(
      api_client, product, task_dt[:owner].to_s, task_dt[:repo].to_s
    )
    if res
      log.info "#{@name} - fetched successfully for #{task_dt}"
    else
      log.info "#{@name} - failed to fetch versions for #{task_dt}"
    end

    res
  rescue => e
    log.error "#{@name} - failed to process #{message} "
    log.error e.message
    log.error e.backtrace.join("\n")

  end

  def get_auth_by_email(user_email)
    user = User.find_by_email user_email.to_s
    return if user.nil?

    if user.github_token
      {access_login: user.github_token}
    end
  end
end

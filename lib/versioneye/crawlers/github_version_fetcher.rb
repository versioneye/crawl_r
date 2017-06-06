require 'octokit'

# This is helper class for VersionCrawler
# it only includes functions to retrieve data by sharing same client
# between multiple request and skip creating a new API client like old version
# NB! it leaves all the persistance related questions to crawler

class GithubVersionFetcher < Versioneye::Crawl
  attr_reader :api, :logger

  A_MINIMUM_RATE_LIMIT = 5
  A_MAX_PAGES = 2048
  A_RETRY_TIMEOUT = 60
  A_MAX_RETRY = 10
  A_PER_PAGE  = 100

  def init_logger
    if !defined?(@log) || @log.nil?
      @logger = Versioneye::DynLog.new("log/github_version_crawler.log", 10).log
    end
    @logger
  end

  # initialize crawler instance
  # params:
  #   login-data - hashmap with valid Octokit login data,
  #                examples: {access_login: String},
  #                          {login: String, password: String}
  #                          {client_id: String, client_secret: String}
  #
  #  use_env_logins - boolean, if true, it will use auth keys from settings
  #                   if it didnt get login data from user or crawler
  def initialize(login_data = nil, use_env_logins = true)
    init_logger

    login_data ||= get_login_from_settings if use_env_logins
    @api = Octokit::Client::new(login_data)
  end

  # pulls list of tags for the repo
  # returns:
  #   list of tags - tag item: {name: String, commit: {sha: String, url: String}}
  def fetch_all_repo_tags( owner, repo )
    logger.info "fetch_all_repo_tags: going to fetch version tags for #{owner}/#{repo}"

    repo = fetch_repo owner, repo
    return if repo.nil?

    res = repo.rels[:tags].get(query: {per_page: A_PER_PAGE})
    return if res.nil?

    #fetch the first page of repos
    tags = res.data.to_a
    return if tags.empty?

    tags += paginate_rels(res.rels)

    tags
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def fetch_repo(owner, repo)
    if owner.to_s.empty? or repo.to_s.empty?
      logger.error "fetch_repo: no owner( #{owner}) or repo(#{repo}) specify"
      return
    end

    api.root.rels[:repository].get(
      :uri => { owner: owner, repo: repo },
    ).data

  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  # fetches commit details
  def fetch_commit_details( owner, repo, sha )
    return unless owner or repo

    @api.commit({owner: owner, repo: repo}, sha)
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  # will follow hypermedia pagination until end
  def paginate_rels(rels, allow_limit_pauses = true)
    results = []
    n, n_tries = 1, 1

    while true do
      if rels.nil? or rels[:next].nil?
        logger.warn "paginate_rels: no pagination data"
        break
      end

      remaining = check_limit_or_pause('paginate_rels', allow_limit_pauses)
      if remaining < A_MINIMUM_RATE_LIMIT
        log.error "paginate_rels: no remaining request limits after re-tries"
        break
      end

      logger.info "paginate_rels: reading page: #{n}"
      res = rels[:next].get(:query => {per_page: A_PER_PAGE})
      if res.nil?
        logger.info "paginate_rels: got no response for page.#{n}"
        break
      end

      results += res.data.to_a
      rels = res.rels

      if rels.nil? or rels[:next].nil?
        logger.info "paginate_rels: we are done with paginating related sources"
        break
      end

      n += 1
      if n > A_MAX_PAGES
        logger.error "fetch_all_repo_tags: too many pages, will stop after #{A_MAX_PAGES}"
        break
      end
    end


    results
  end


  # Checks request limits and will processing until rate limits are changed or
  # runs out of time it's allowed to re-check
  #
  # use for combined requests and Crawler functions
  #
  # returns
  #   int of remaining queries - may be zero
  def check_limit_or_pause(task_name = '', allow_pauses = true)
    remaining = @api.rate_limit[:remaining].to_i
    return remaining if remaining > A_MINIMUM_RATE_LIMIT

    log.warn("hit Github rate limit - will wait and retry to continue #{task_name} later")
    n_tries = 0
    while true do
      n_tries += 1
      if n_tries >= A_MAX_RETRY
        logger.error "fetch_all_repo_tags: no more re-tries left for #{owner}/#{repo}"
        break
      end

      remaining = @api.rate_limit[:remaining].to_i
      if remaining < A_MINIMUM_RATE_LIMIT and allow_pauses == true
        logger.info "fetch_all_repo_tags: will wait a bit"
        sleep  A_RETRY_TIMEOUT
        next #try again
      end
    end

    remaining
  end

  def get_login_from_settings
    confs = Settings.instance
    if !confs.github_client_id.to_s.empty?
      {
        client_id: confs.github_client_id.to_s,
        client_secret: confs.github_client_secret.to_s
      }
    elsif !confs.github_pass.to_s.empty?
      {
        login: confs.github_user.to_s,
        password: confs.github_pass.to_s
      }
    else
      log.warn "No authorization data"
      nil
    end
  end


end

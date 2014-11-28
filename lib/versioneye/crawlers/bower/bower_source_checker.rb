class BowerSourceChecker < Bower 

  
  def self.crawl token 
    crawl_existing_sources token 
  end 

  
  # checks does url of source exists or not
  def self.crawl_existing_sources(token)
    task_name = A_TASK_CHECK_EXISTENCE

    crawler_task_executor(task_name, token) do |task, token|
      result = check_repo_existence(task, token)
    end
  end


  # TODO refactor. This method is to big.
  def self.check_repo_existence(task, token)
    success  = false
    repo_url = "https://github.com/#{task[:repo_fullname]}"
    p "check_repo_existence for #{repo_url}"
    response = http_head(repo_url)
    return false if response.nil? or response.is_a?(Boolean)

    response_code = response.code.to_i
    if response_code == 200
      read_task = to_read_task(task, task[:url])
      read_task.update_attributes({
        registry_name: task[:registry_name], #registered name on bower.io, not same as github repo and projectfile
        weight: 10
      })
      success = true
    elsif response_code == 301 or response_code == 308
      logger.info "#{task[:task]} | #{task[:repo_fullname]} has moved to #{response['location']}"
      # mark current task as failed and dont crawl it
      repo_info = url_to_repo_info(response['location'])
      task.update_attributes({
        re_crawl: false,
        url_exists: false
      })
      # create new task with new url and try again with new url
      redirected_task = to_existence_task(repo_info)
      redirected_task.update_attributes({
        registry_name: task[:registry_name], #registered name on bower.io, not same as github repo and projectfile
        weight: 20,
        task_failed: false,
        re_crawl: true,
        url_exists: true
      })
      success = true
    elsif response_code == 304
      logger.info "No changes for `#{task[:repo_fullname]}` since last crawling `#{read_task[:crawled_at]}`. Going to skip."
      task.update_attributes({url_exists: true, re_crawl: false})
      success = true
    elsif response_code == 404
      logger.error "check_repo_existence| 404 for #{task[:repo_fullname]} on `#{task[:url]}`"
    elsif response_code >= 500
      # when service down
      logger.error "check_repo_existence | Sadly Github is down; cant access #{task[:url]}"
      task.update_attributes({
        fails: task[:fails] + 1,
        re_crawl: true,
        task_failed: true,
      })
    end
    success
  end


  def self.to_read_task(task, url)
    read_task = CrawlerTask.find_or_create_by(
      task: A_TASK_READ_PROJECT,
      repo_fullname: task[:repo_fullname]
    )

    read_task.update_attributes({
      runs: read_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      registry_name: task[:registry_name],
      weight: 1 + task[:weight].to_i,
      url_exists: true,
      re_crawl: true,
      url: url
    })

    read_task
  end


  def self.http_head(url, modified_since = nil)
    response = nil
    headers = nil
    if modified_since
      headers = {"If-Modified-Since" => modified_since.rfc822}
    end
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
      response = http.request_head(uri.path, headers)
    end
    response
  rescue => e
    logger.error "Cant check headers of url: `#{url}`. #{e.message}"
    logger.error e.backtrace.join("\n")
  end


end
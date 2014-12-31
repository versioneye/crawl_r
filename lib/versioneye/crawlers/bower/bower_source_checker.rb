class BowerSourceChecker < Bower 

  
  def self.check_repo_existence(task, token)
    repo_url = "https://github.com/#{task[:repo_fullname]}"
    response = http_head(repo_url)
    return false if response.nil? or response.is_a?(Boolean)

    response_code = response.code.to_i
    if response_code == 200
      to_read_task(task, task[:url])
      return true
    elsif response_code == 301 or response_code == 308
      logger.info "#{task[:task]} | #{task[:repo_fullname]} has moved to #{response['location']}"
      repo_info = url_to_repo_info(response['location'])
      registry_name = task[:registry_name]
      task = to_existence_task(repo_info) # Create new task with new url and try again with new url
      task.registry_name = registry_name
      return check_repo_existence(task, token)
    elsif response_code == 304
      logger.info "No changes for `#{task[:repo_fullname]}` since last crawling `#{read_task[:crawled_at]}`. Going to skip."
      task.update_attributes({url_exists: true, re_crawl: false})
      return true
    elsif response_code == 404
      logger.error "check_repo_existence| 404 for #{task[:repo_fullname]} on `#{task[:url]}`"
      return false 
    elsif response_code >= 500
      logger.error "check_repo_existence | Sadly Github is down; cant access #{task[:url]}"
      return false 
    end
    false 
  end


  def self.to_read_task(task, url)
    task.task = A_TASK_READ_PROJECT
    task.url_exists = true 
    task.url = url 
    task 
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
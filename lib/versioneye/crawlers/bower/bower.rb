class Bower < Versioneye::Crawl

  A_MINIMUM_RATE_LIMIT = 50
  A_MAX_RETRY = 12 # 12x10 ~> after that worker'll starve to death
  A_SLEEP_TIME = 20
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT    = "bower_crawler/read_project"
  A_TASK_READ_VERSIONS   = "bower_crawler/read_versions"
  A_TASK_TAG_PROJECT     = "bower_crawler/tag_project"

  
  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower.log')
  end

  
  @@rate_limits = nil

  
  def self.rate_limits(val = nil)
    @@rate_limits = val if val
    @@rate_limits
  end

  
  def self.github_rate_limit(token)
    OctokitApi.client(token).rate_limit
  end

  
  def self.ensure_ratelimit_existence token 
    10.times do |i|
      break if rate_limits

      val = github_rate_limit(token) #ask rate limit from API
      rate_limits(val)
      break if rate_limits
      
      sleep A_SLEEP_TIME
    end
  end

  
  def self.check_request_limit(token)
    ensure_ratelimit_existence token 

    if rate_limits.nil?
      logger.error "Get no rate_limits from Github API - smt very bad is going on."
      sleep A_SLEEP_TIME
      return
    end

    rate_limits[:remaining] -= 1 
    remaining = rate_limits[:remaining].to_s 
    if remaining <= A_MINIMUM_RATE_LIMIT
      @@rate_limits = nil 
      ensure_ratelimit_existence token 
    end

    remaining = rate_limits[:remaining]
    time_left = (rate_limits[:resets_in] - Time.now.to_i) / 60 #in minutes
    time_left += 1 #add additional minute for rounding errors and warming up
    if remaining.to_i < A_MINIMUM_RATE_LIMIT.to_i 
      logger.info "Remaining requests #{remaining}"
      logger.info "Going to stop crawling for next #{time_left} minutes"
      sleep time_left.minutes
      logger.info "Waking up and going to continue crawling."
      @@rate_limits = nil 
      ensure_ratelimit_existence token 
    end

    remaining = rate_limits[:remaining]
    logger.info "#-- Remaining requests: #{remaining}"

    rate_limits
  end


  # Just for debugging to clear old noise
  def self.clean_all
    # Remove all data added by crawler - only for devs.
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Newest.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Dependency.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
    CrawlerTask.delete_all
  end


  # Using: task_executor(task_name) {|task_name| crawl_money}
  def self.crawler_task_executor(task_name, token)
    logger.info "#-- #{task_name} is starting ... "
    start_time = Time.now
    success = 0; failed = 0
    while true do
      check_request_limit(token)
      task = get_task_for(task_name)
      next if task.nil?

      if task[:poison_pill] == true
        task.remove
        logger.info "#-- #{task_name} got poison pill. Going to die ..."
        break
      end

      # Worker content
      if block_given?
        result = yield(task, token)
      else
        logger.info "Task executor got no execution block."
        break
      end

      # Return boolean in your block when want to update these metrics
      if result
        success += 1
        waited = 0
        update_task task, { crawled_at: DateTime.now, re_crawl: false, task_failed: false }
      else
        failed += 1
        update_task task, { task_failed: true, fails: task[:fails] + 1, re_crawl: false }
      end

      logger.info "#{task_name}| success: #{success} , failed: #{failed}"
    end

    unfinished = CrawlerTask.by_task(task_name).crawlable.count
    runtime    = Time.now - start_time
    logger.info "#-- #{task_name} is done in #{runtime} seconds. success: #{success}, failed: #{failed}, unfinished: #{unfinished}"
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end


  def self.update_task task, attributes 
    task.save 
    task.update_attributes( attributes )
  rescue => e 
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end


  def self.get_task_for(task_name)
    task = nil
    10.times do |i|
      task = CrawlerTask.by_task(task_name).crawlable.desc(:weight).shift
      break if task

      logger.info "No tasks for #{task_name} - going to wait #{A_SLEEP_TIME} seconds before re-trying again"
      sleep A_SLEEP_TIME
    end

    # if task.nil?
    #   task = to_poison_pill(task_name)
    # end
    task
  end


  def self.to_poison_pill(task_name)
    task = CrawlerTask.find_or_create_by({task: task_name, poison_pill: true})
    task.update_attributes({
      re_crawl: true,
      url_exists: true,
      weight: -10  # will be the last when getting sorted list
    })
    task
  end


  def self.to_existence_task(repo_info)
    task = CrawlerTask.find_or_create_by(
      task: A_TASK_CHECK_EXISTENCE,
      repo_fullname: repo_info[:full_name]
    )

    task.update_attributes({
      repo_owner: repo_info[:owner],
      repo_name: repo_info[:repo],
      registry_name: repo_info[:registry_name],
      url: repo_info[:url],
      runs: task[:runs] + 1,
      re_crawl: true
    })

    task
  end


  def self.url_to_repo_info(repo_url)
    return nil if (repo_url =~ /github.com\//i).nil?

    parts = repo_url.split("/")
    owner = parts[parts.length - 2]
    repo  = parts[parts.length - 1]
    if repo =~ /\.git$/i
      repo = repo.gsub(/\.git$/i, '')
    end
    full_name = "#{owner}/#{repo}"

    {
      owner: owner,
      repo: repo,
      full_name: full_name,
      url: repo_url
    }
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.to_pkg_info(owner, repo, project_url, project_info)
    pkg_name = project_info[:name].to_s.strip
    pkg_name = repo if pkg_name.empty?

    pkg_info = {
      name: pkg_name,
      group_id: owner,
      artifact_id: repo,
      full_name: "#{owner}/#{repo}",
      version: project_info[:version],
      licenses: [{name: "unknown", url: nil}], # default values, try to read real values later.
      description: project_info[:description],
      dependencies: project_info[:dependencies],
      dev_dependencies: project_info[:devDependencies],
      homepage: project_info[:homepage],
      url: project_url,
      private_repo: false,
    }

    if project_info.has_key?(:license)
      read_license pkg_info, project_info
    elsif project_info.has_key?(:licenses)
      read_licenses pkg_info, project_info
    end

    pkg_info
  end


  def self.read_license(info, project_info)
    license_info = project_info[:license]
    if license_info.is_a?(String)
      info[:licenses] = [{name: license_info, url: nil}]
    elsif license_info.is_a?(Array)
      info[:licenses] = []
      license_info.each do |lic|
        if lic.is_a?(String)
          info[:licenses] << {name: lic, url: nil}
        elsif lic.is_a?(Hash)
          info[:licenses] << {name: lic[:type], url: lic[:url]}
        end
      end
    end
  end

  def self.read_licenses(info, project_info)
    # support for npm.js licenses
    info[:licenses] = []
    if project_info[:licenses].is_a?(Array)
      project_info[:licenses].to_a.each do |lic|
        if lic.is_a?(String)
          info[:licenses] << {name: lic, url: nil}
        else lic.is_a?(Hash)
          info[:licenses] << {name: lic[:type], url: lic[:url]}
        end
      end
    elsif project_info[:licenses].is_a?(Hash)
      lic = project_info[:licenses]
      info[:licenses] << {name: lic[:type], url: lic[:url]}
    end
  end


  def self.make_prod_key(task_info)
    "#{task_info[:repo_owner]}/#{task_info[:registry_name]}".strip.downcase
  end


  def self.to_dependencies(prod, pkg_info, key, scope = nil)
    return nil if prod.nil? || !pkg_info.has_key?(key) || pkg_info[key].nil? || pkg_info[key].empty?

    deps = []
    if not pkg_info[key].is_a?(Hash)
      logger.error "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[key]}`"
      return nil
    end

    prod_version = fetch_version_for_dep(prod, pkg_info) # TODO refactor it, give as param.
    pkg_info[key].each_pair do |prod_name, version|
      next if prod_name.to_s.strip.empty?
      dep = to_dependency(prod, prod_version, prod_name, version, scope)
      deps << dep if dep
    end
    deps
  end

  def self.fetch_version_for_dep prod, pkg_info
    prod_version = pkg_info[:version]
    if prod_version.to_s.empty?
      prod_version = prod.sorted_versions.first.to_s
    end
    prod_version
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def self.to_dependency(prod, prod_version, dep_name, dep_version, scope = Dependency::A_SCOPE_REQUIRE)
    dep_prod = Product.fetch_bower(dep_name)
    dep_prod_key = nil
    dep_prod_key = dep_prod.prod_key if dep_prod
    dependency = Dependency.find_or_create_by(
      prod_type: Project::A_TYPE_BOWER,
      language: prod[:language],
      prod_key: prod[:prod_key].to_s,
      prod_version: prod_version,
      dep_prod_key: dep_prod_key,
      name: dep_name
    )
    dependency.update_attributes!({
      dep_prod_key: dep_prod_key,
      name: dep_name,
      version: dep_version, # TODO: It can be that the version is in the bower.json is a git tag / path
      scope: scope
    })
    dependency.update_known
    dependency
  rescue => e
    logger.error "Error: Cant save dependency `#{dep_name}` with version `#{dep_version}` for #{prod[:prod_key]}. -- #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


end
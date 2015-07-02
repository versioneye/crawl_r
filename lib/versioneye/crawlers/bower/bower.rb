class Bower < Versioneye::Crawl

  A_MINIMUM_RATE_LIMIT = 50
  A_MAX_RETRY = 12 # 12x10 ~> after that worker'll starve to death
  A_SLEEP_TIME = 20
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT    = "bower_crawler/read_project"
  A_TASK_READ_VERSIONS   = "bower_crawler/read_versions"
  A_TASK_TAG_PROJECT     = "bower_crawler/tag_project"

  
  def self.logger
    ActiveSupport::Logger.new('log/bower.log')
  end

  def logger
    Bower.logger
  end

  
  def self.check_request_limit(token)
    rate_limits = OctokitApi.client(token).rate_limit
    remaining   = rate_limits[:remaining].to_i 
    if remaining.to_i < A_MINIMUM_RATE_LIMIT.to_i 
      logger.info "Remaining requests #{remaining}"

      logger.info "Going to stop crawling for next 2 minutes"
      sleep 120 
      
      logger.info "Waking up and going to continue crawling."
      check_request_limit(token)
    end

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


  def self.to_existence_task(repo_info)
    CrawlerTask.new({
      task: A_TASK_CHECK_EXISTENCE, 
      repo_fullname: repo_info[:full_name], 
      repo_owner: repo_info[:owner],
      repo_name: repo_info[:repo],
      registry_name: repo_info[:registry_name],
      url: repo_info[:url],
      re_crawl: true
      })
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
      licenses: [{name: nil, url: nil}], # default values, try to read real values later.
      description: project_info[:description],
      dependencies: project_info[:dependencies],
      dev_dependencies: project_info[:devDependencies],
      homepage: project_info[:homepage],
      url: project_url
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


  def self.create_dependencies(prod, pkg_info, key, scope = nil)
    return nil if prod.nil? || !pkg_info.has_key?(key) || pkg_info[key].nil? || pkg_info[key].empty?

    deps = []
    if not pkg_info[key].is_a?(Hash)
      logger.error "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[key]}`"
      return nil
    end

    prod_version = fetch_version_for_dep(prod, pkg_info) # TODO refactor it, give as param.
    pkg_info[key].each_pair do |prod_name, version|
      next if prod_name.to_s.strip.empty?
      dep = create_dependency(prod, prod_version, prod_name, version, scope)
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

  def self.create_dependency(prod, prod_version, dep_name, dep_version, scope = Dependency::A_SCOPE_REQUIRE)
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


  def self.find_or_create_licenses( product, pkg_info, repo_name, sha, token )
    license_list = find_or_create_licenses_from_bowerjson product, pkg_info
    return nil if !license_list.empty? 

    find_or_create_licenses_from_license_files( product, pkg_info, repo_name, sha, token )
  rescue => e
    logger.error "Error in find_or_create_licenses -- #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.find_or_create_licenses_from_bowerjson product, pkg_info
    license_list = [] 
    version_number = pkg_info[:version]
    pkg_info[:licenses].each do |license_info|
      license_name = license_info[:name]
      license_url  = license_info[:url]
      next if license_name.to_s.empty? || license_name.to_s.eql?("unknown")
      
      lic = License.find_or_create( product.language, product.prod_key, version_number, license_name, license_url )
      license_list << lic
    end
    license_list
  end


  def self.find_or_create_licenses_from_license_files product, pkg_info, repo_name, sha, token
    filenames = LicenseCrawler::LICENSE_FILES
    files = files_from_gh_branch( filenames, repo_name, token, sha )
    return nil if files.nil? || files.empty? 

    files.each do |file_info| 
      content = fetch_file_content(repo_name, file_info[:url], token)
      result  = LicenseCrawler.recognize_license content, file_info[:url], product, pkg_info[:version]
      return true if !result.to_s.empty?
    end
  end


  def self.files_from_gh_branch(filenames, repo_name, token, branch_sha, branch = "master", try_n = 2)
    branch_tree = nil

    try_n.times do
      branch_tree = Github.repo_branch_tree(repo_name, token, branch_sha)
      break unless branch_tree.nil?
      log.error "Going to read tree of branch `#{branch}` for #{repo_name} again after little pause."
      sleep 1 # it's required to prevent bombing Github's api after our request got rejected
    end

    if branch_tree.nil? or !branch_tree.has_key?('tree')
      msg = "Can't read tree for repo `#{repo_name}` on branch `#{branch}`."
      log.error msg
      return nil 
    end

    files = branch_tree['tree'].keep_if {|file| filenames.include?(file['path'].to_s) != nil}

    files.each do |file|
      file.deep_symbolize_keys!
    end

    files
  end


  def self.fetch_file_content(repo_name, project_url, token)
    logger.debug "Reading tag_project file for #{repo_name}: #{project_url}"
    file_data = Github.fetch_file(project_url, token)
    if file_data.nil? || file_data.empty? || file_data[:content].nil? || file_data[:content].empty? 
      logger.error "cant read content of project file for #{repo_name}: #{project_url}"
      return ''
    end

    Base64.decode64(file_data[:content])
  rescue => e 
    logger.error "Error in fetch_file_content -- #{e.message}"
    logger.error e.backtrace.join("\n")
    ''
  end


  def self.skip_version?( version )
    if version.match(/(-build)+.*(sha\.)+/xi) || 
       version.match(/(-beta)+.*(nightly-)+/xi) || 
       version.match(/.+(-master-)\S{7}/xi) || 
       version.eql?("2010.07.06dev") || version.eql?("v2010.07.06dev")
      logger.error "-- Skip build tags! Specially for AngularJS!"
      return true 
    end
    false 
  end


end

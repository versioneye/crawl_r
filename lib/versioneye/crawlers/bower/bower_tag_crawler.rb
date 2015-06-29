class BowerTagCrawler < Bower 

  
  def self.crawl_tag_deep task, token 
    tag_name    = task[:tag_name]
    cleaned_tag = CrawlerUtils.remove_version_prefix( tag_name.to_s )
    prod        = Product.fetch_bower(task[:registry_name])

    dep_count = Dependency.where(:language => prod.language, :prod_type => prod.prod_type, 
      :prod_key => prod.prod_key, :prod_version => cleaned_tag).count 
    if dep_count > 0 
      logger.debug "tag #{tag_name} has already dependencies"
      return false 
    end
    
    commit_info = task[:data].deep_symbolize_keys
    repo_name   = task[:repo_fullname]

    logger.debug "#-- going to read project deps for #{repo_name} with `#{tag_name}`"
    commit_tree  = fetch_commit_tree(commit_info[:url], token)
    if commit_tree.nil?
      logger.debug "commit_tree is nil"
      return false
    end

    project_info = fetch_project_info_by_sha(repo_name, commit_tree[:sha], token, tag_name)
    if project_info.nil?
      logger.debug "project_info is nil"
      return false
    end

    project_file = fetch_project_file(repo_name, project_info[:url], token)
    if project_file.nil? 
      logger.debug "project_file is nil"
      return false
    end

    file_content = parse_json(project_file)
    if file_content.nil? or file_content.is_a?(TrueClass)
      logger.debug "file_content is nil"
      return false
    end

    unless file_content.has_key?(:version)
      logger.warn "No version found in project file on tag #{tag_name} of #{repo_name}. Going to use tag."
      file_content[:version] = cleaned_tag
    end

    pkg_info = to_pkg_info(task[:owner], task[:repo], project_info[:url], file_content)

    to_dependencies(prod, pkg_info, :dependencies,     Dependency::A_SCOPE_REQUIRE)
    to_dependencies(prod, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

    find_or_create_licenses(prod, pkg_info)   

    true 
  end


  # Reads information of commit data, which includes link to commit tree
  def self.fetch_commit_tree(commit_url, token)
    check_request_limit(token)
    data = Github.get_json(commit_url, token)
    if data.nil?
      logger.error "fetch_commit_tree | cant read commit information on #{commit_url}"
    end
    data
  rescue => e 
    logger.error e.message 
    logger.error e.backtrace.join("\n")
    nil 
  end


  def self.fetch_project_info_by_sha(repo_name, sha, token, tag = nil)
    check_request_limit(token)
    project_files = Github.project_files_from_branch(repo_name, token, sha)
    if project_files.nil?
      logger.error "Didnt get any supported project file for #{repo_name} on the tag sha: `#{sha}`"
      return
    end

    bower_files = project_files.keep_if do |file|
      ProjectService.type_by_filename(file[:path]) == Project::A_TYPE_BOWER
    end

    logger.info "-- Found #{bower_files.count} bower files for #{repo_name} #{tag}"
    bower_files.first
  end


  def self.fetch_project_file(repo_name, project_url, token)
    logger.debug "Reading tag_project file for #{repo_name}: #{project_url}"
    file_data = Github.fetch_file(project_url, token)
    if file_data.nil?
      logger.error "cant read content of project file for #{repo_name}: #{project_url}"
      return
    end

    Base64.decode64(file_data[:content])
  end


  def self.parse_json(doc)
    JSON.parse doc, symbolize_names: true
  rescue => e
    logger.error "cant parse doc: #{doc} \n #{e.message}"
    nil 
  end


end 
class BowerTagCrawler < Bower 

  
  def self.crawl_tag_deep task, token 
    tag_name    = task[:tag_name]
    cleaned_tag = CrawlerUtils.remove_version_prefix( tag_name.to_s )
    product     = Product.fetch_bower(task[:registry_name])
    
    commit_info = task[:data].deep_symbolize_keys
    sha         = commit_info[:sha]
    repo_name   = task[:repo_fullname]

    bower_info = fetch_bowerjson_info_by_sha(repo_name, sha, token, tag_name)
    if bower_info.nil? || bower_info.empty?
      logger.debug "bower_info is nil"
      return false
    end

    bowerjson_content = fetch_file_content(repo_name, bower_info[:url], token)
    if bowerjson_content.nil? || bowerjson_content.empty? 
      logger.debug "bowerjson_content is nil"
      return false
    end

    bower_json = parse_json( bowerjson_content )
    if bower_json.nil? or bower_json.is_a?(TrueClass)
      logger.debug "bower_json is nil"
      return false
    end

    bower_json[:version] = cleaned_tag

    pkg_info = to_pkg_info(task[:owner], task[:repo], bower_info[:url], bower_json)

    create_dependencies(product, pkg_info, :dependencies,     Dependency::A_SCOPE_REQUIRE)
    create_dependencies(product, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

    find_or_create_licenses( product, pkg_info, repo_name, sha, token )

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


  def self.fetch_bowerjson_info_by_sha(repo_name, sha, token, tag = nil)
    check_request_limit(token)
    project_files = Github.project_files_from_branch(repo_name, token, sha)
    if project_files.nil? || project_files.empty? 
      logger.error "Didnt get any supported project file for #{repo_name} on the tag sha: `#{sha}`"
      return
    end

    bower_files = project_files.keep_if do |file|
      ProjectService.type_by_filename(file[:path]) == Project::A_TYPE_BOWER
    end

    logger.info "-- Found #{bower_files.count} bower files for #{repo_name} #{tag}"

    bower_files.each do |pf| 
      if pf[:path].to_s.eql?('bower.json')
        return pf 
      end
    end

    bower_files.first
  end


  def self.parse_json(doc)
    JSON.parse doc, symbolize_names: true
  rescue => e
    logger.error "cant parse doc: #{doc} \n #{e.message}"
    nil 
  end


end 
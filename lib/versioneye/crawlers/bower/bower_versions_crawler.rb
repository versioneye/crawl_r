class BowerVersionsCrawler < Bower 

  
  def self.crawl_versions task, token 
    product  = Product.fetch_bower task[:registry_name]
    if product.nil?
      prod_key = make_prod_key(task)
      logger.error "#{task_name} | Cant find product for #{task[:repo_fullname]} with prod_key #{prod_key}"
      return false 
    end

    tags = Github.repo_tags_all(task[:repo_fullname], token)
    if tags && !tags.empty?
      result = process_tags task, product, tags, token   
    else
      result = handle_no_tags task, product
    end
    false 
  end


  def self.process_tags task, product, tags, token 
    tags_count = tags.to_a.count
    logger.info "#{task[:repo_fullname]} has #{tags_count} tags."
    if product.versions && product.versions.count == tags_count
      logger.info "-- skip #{task[:repo_fullname]} because tags count (#{tags_count}) is equal to versions.count."
      return true 
    end

    tags.each do |tag|
      result = parse_repo_tag( task[:repo_fullname], product, tag, token )
      next if result == false 
      
      tag_task = to_tag_project_task(task, tag) 
      BowerTagCrawler.crawl_tag_deep tag_task, token
    end

    latest_version = product.sorted_versions.first
    if latest_version
      product[:version] = latest_version[:version]
      product.save
      update_product_dependencies(product, latest_version[:version])
    end
    true
  end


  def self.handle_no_tags task, product 
    logger.warn "`#{task[:repo_fullname]}` has no versions - going to skip."
    if product.version.to_s.empty?
      product.remove
    end
    true
  end


  def self.to_tag_project_task(task, tag)    
    CrawlerTask.new(
      task: A_TASK_TAG_PROJECT,
      repo_fullname: task[:repo_fullname],
      tag_name: tag[:name], 
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      registry_name: task[:registry_name],
      data: tag[:commit],
      url: tag[:commit][:url],
      url_exists: true
    )
  end


  def self.parse_repo_tag(repo_fullname, product, tag, token)
    if product.nil? or tag.nil?
      logger.error "-- parse_repo_tag(repo_fullname, product, tag, token) - Product or tag cant be nil"
      return false 
    end

    tag = tag.deep_symbolize_keys
    tag_name = CrawlerUtils.remove_version_prefix( tag[:name].to_s )
    if tag_name.nil?
      logger.error "-- Skipped tag `#{tag_name}` "
      return false 
    end

    if tag_name.match(/(-build)+.*(sha\.)+/xi) || 
       tag_name.match(/(-beta)+.*(nightly-)+/xi) || 
       tag_name.match(/.+(-master-)\S{7}/xi)
      logger.error "-- Skip build tags! Specially for AngularJS!"
      return false 
    end

    if product.version_by_number( tag_name )
      logger.info "-- #{product.prod_key} : #{tag_name} exists already"
      return false 
    end

    add_new_version(product, tag_name, tag, token)
    CrawlerUtils.create_newest product, tag_name, logger
    CrawlerUtils.create_notifications product, tag_name, logger

    logger.info " -- Added version `#{product.prod_key}` : #{tag_name} "
    create_version_archive(product, tag_name, tag[:zipball_url]) if tag.has_key?(:zipball_url)

    true 
  end


  def self.add_new_version( product, tag_name, tag, token )
    new_version                 = Version.new version: tag_name
    new_version.released_string = release_date_string( tag, token )
    new_version.released_at     = released_date( new_version.released_string )
    product.versions << new_version
    product.reindex = true
    product.save
  end


  def self.create_version_archive(prod, version, url, name = nil)
    if name.nil?
      name = "#{prod[:name]}_#{version}.zip"
    end
    archive = Versionarchive.new({:language => prod[:language], :prod_key => prod[:prod_key],
      :version_id => version, :name => name, :link => url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end


  # Add latest version for dependencies missing prod_version
  def self.update_product_dependencies(product, version_label)
    logger.info "update_product_dependencies for #{product.prod_key} version: #{version_label}"
    deps_without_version = Dependency.where(
      language: product.language,
      prod_type: Project::A_TYPE_BOWER, 
      prod_key: product[:prod_key], 
      prod_version: nil)
    deps_without_version.each do |dep|
      dep[:prod_version] = product[:version]
      dep.save
    end
  end


  def self.release_date_string(tag, token)
    released_string = nil
    check_request_limit(token) #every func that calls Github api should check ratelimit first;
    commit_info = Github.get_json(tag[:commit][:url], token)
    if commit_info
      released_string = commit_info[:commit][:committer][:date].to_s
    else
      logger.error "No commit info for tag `#{tag}`"
    end
    released_string
  end


  def self.released_date( released_string )
    return nil if released_string.to_s.empty?
    released_string.to_datetime
  rescue => e
    logger.error e.backtrace.join("\n")
    nil
  end


end 
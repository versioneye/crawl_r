class BowerVersionsCrawler < Bower 

  
  def self.crawl token 
    crawl_versions(token)
  end 


  # Imports package versions
  def self.crawl_versions(token)
    task_name = A_TASK_READ_VERSIONS
    result = false
    crawler_task_executor(task_name, token) do |task, token|
      prod_key = make_prod_key(task)
      product  = Product.fetch_bower task[:registry_name]
      if product.nil?
        logger.error "#{task_name} | Cant find product for #{task[:repo_fullname]} with prod_key #{prod_key}"
        next
      end

      tags = Github.repo_tags_all(task[:repo_fullname], token)
      if tags && !tags.empty?
        result = process_tags task, product, tags, token   
      else
        result = handle_no_tags task, product
      end
      result
    end
  end


  def self.process_tags task, product, tags, token 
    tags_count = tags.to_a.count
    logger.info "#{task[:repo_fullname]} has #{tags_count} tags."
    if product.versions && product.versions.count == tags_count
      logger.info "-- skip #{task[:repo_fullname]} because tags count (#{tags_count}) is equal to versions.count."
    end

    tags.each do |tag|
      parse_repo_tag( task[:repo_fullname], product, tag, token )
      to_tag_project_task(task, tag)
      sleep 1/100.0 # Just force little pause asking commit info -> github may block
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
    tag_task = CrawlerTask.find_or_create_by(
      task: A_TASK_TAG_PROJECT,
      repo_fullname: task[:repo_fullname],
      tag_name: tag[:name]
    )

    tag_task.update_attributes({
      runs: tag_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      registry_name: task[:registry_name],
      tag_name: tag[:name],
      data: tag[:commit],
      url: tag[:commit][:url],
      url_exists: true,
      weight: 10,
      re_crawl: true
    })
  end 


  def self.parse_repo_tag(repo_fullname, product, tag, token)
    if product.nil? or tag.nil?
      logger.error "-- parse_repo_tag(repo_fullname, product, tag, token) - Product or tag cant be nil"
      return
    end

    tag = tag.deep_symbolize_keys
    tag_name = CrawlerUtils.remove_version_prefix( tag[:name].to_s )
    if tag_name.nil?
      logger.error "-- Skipped tag `#{tag_name}` "
      return
    end

    if product.version_by_number( tag_name )
      logger.info "-- #{product.prod_key} : #{tag_name} exists already"
      return
    end

    add_new_version(product, tag_name, tag, token)
    CrawlerUtils.create_newest product, tag_name, logger
    CrawlerUtils.create_notifications product, tag_name, logger

    logger.info " -- Added version `#{product.prod_key}` : #{tag_name} "
    create_version_archive(product, tag_name, tag[:zipball_url]) if tag.has_key?(:zipball_url)
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
    all_dependencies = Dependency.where(prod_key: product[:prod_key])
    deps_without_version = all_dependencies.keep_if {|dep| dep[:prod_key].nil? }
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
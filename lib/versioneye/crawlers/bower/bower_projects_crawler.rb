class BowerProjectsCrawler < Bower 

  
  def self.process_project task, token 
    check_request_limit(token)
    repo_response = Github.repo_info(task[:repo_fullname], token, true, task[:crawled_at])

    if repo_response.nil? or repo_response.is_a?(Boolean)
      logger.error "crawl_projects | Did not get repo_info for #{task[:repo_fullname]}"
      return false 
    end

    if repo_response.code == 304
      logger.debug "crawl_projects | no changes for #{task[:repo_fullname]}, since #{task[:crawled_at]}"
      return false 
    end

    if repo_response.body.to_s.empty?
      logger.error "Did not get any repo info for #{task[:repo_fullname]} - got: #{repo_response.code}"
      return false 
    end

    repo_info = repo_response.body
    if repo_info.nil? || repo_response.code != 200
      logger.error "crawl_projects | cant read information for #{task[:repo_fullname]}."
      return false
    end

    repo_info = JSON.parse(repo_response.body, symbolize_names: true)
    repo_info[:repo_fullname] = task[:repo_fullname]
    product = add_bower_package(task, repo_info,  token)
    if product.nil?
      logger.error "crawl_projects | cant add bower package for #{task[:repo_fullname]}."
      return false
    end

    task.update_attributes({crawled_at: DateTime.now})
    to_version_task(task, product[:prod_key]) # add new version task when everything went oK
    
    true
  end


  def self.add_bower_package(task, repo_info, token)
    logger.info "#-- reading #{task[:repo_fullname]} from url: #{task[:url]} branch: #{repo_info[:default_branch]}"
    pkg_file = self.read_project_file_from_github(task, token, repo_info[:default_branch])
    if pkg_file.nil?
      logger.error "add_bower_package | Didnt get any project file for #{task[:repo_fullname]}"
      return nil
    end

    pkg_file[:repo_fullname] = repo_info[:repo_fullname]
    pkg_file[:name] = task[:registry_name]  if task.has_attribute?(:registry_name) # if task has prod_key then use it - dont trust user's unvalidated bower.json
    pkg_file[:name] = repo_info[:name]      if pkg_file[:name].to_s.strip.empty?
    pkg_file[:name] = repo_info[:full_name] if pkg_file[:name].to_s.strip.empty?
    prod_key        = make_prod_key(task)
    product         = create_bower_package(prod_key, pkg_file, repo_info, token)
    if product.nil?
      logger.error "add_bower_package | cant create_or_find product for #{task[:repo_fullname]}"
      return nil
    end

    product.save
    product
  rescue => e
    logger.error "add_bower_package | cant save product for #{repo_info} - #{e.message}"
    if product && product.errors
      logger.error "#{product.errors.full_messages.to_sentence}"
    end
    logger.error e.backtrace.join("\n")
    nil
  end


  # Saves product and save sub/related docs
  def self.create_bower_package(prod_key, pkg_info, repo_info, token)
    prod = create_or_update_product(prod_key, pkg_info, token, repo_info[:language])

    Versionlink.create_project_link prod[:language], prod[:prod_key], "https://github.com/#{repo_info[:repo_fullname]}", "SCM"
    Versionlink.create_project_link prod[:language], prod[:prod_key], pkg_info[:homepage], "Homepage"

    to_dependencies(prod, pkg_info, :dependencies,     Dependency::A_SCOPE_REQUIRE)
    to_dependencies(prod, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

    pkg_info[:licenses].to_a.each { |lic| create_or_update_license( prod, lic ) }

    prod
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.create_or_update_product(prod_key, pkg_info, token, language = nil)
    language = Product::A_LANGUAGE_JAVASCRIPT if language.nil?
    prod     = Product.find_or_create_by( prod_key: prod_key, language: language )
    prod.update_attributes!(
      language:      language,
      prod_type:     Project::A_TYPE_BOWER,
      name:          pkg_info[:name].to_s,
      name_downcase: pkg_info[:name].to_s.downcase,
      description:   pkg_info[:description].to_s
    )
    set_version(prod, pkg_info, token)
    prod.save!
    prod
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.set_version prod, pkg_info, token
    tags = Github.repo_tags(pkg_info[:repo_fullname], token)
    version_exist_in_file = pkg_info.has_key?(:version) && !pkg_info[:version].to_s.strip.empty?
    no_tags_released = tags.nil? || tags.empty?
    if version_exist_in_file && no_tags_released
      prod.version = pkg_info[:version]
    end
    prod
  end


  def self.read_project_file_from_github(task, token, branch = 'master')
    owner    = task[:repo_owner]
    repo     = task[:repo_name]
    fullname = task[:repo_fullname]
    repo_url = task[:url]
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'module.json', 'package.json']
    supported_files.to_a.each do |filename|
      file_url     = "https://raw.githubusercontent.com/#{fullname}/#{branch}/#{filename}"
      project_file = read_project_file_from_url( file_url, token )
      if project_file.is_a?(Hash)
        logger.info "Found: #{filename} for #{task[:repo_fullname]}"
        pkg_info = to_pkg_info(owner, repo, repo_url, project_file)
        break
      end
    end

    if pkg_info.nil?
      logger.info "#{task[:repo_fullname]} has no supported project files. #{supported_files.to_a}"
    end

    pkg_info
  end


  def self.create_or_update_license(product, license_info)
    return nil if product.nil?
    return nil if license_info[:name].nil? || license_info[:name].empty? || license_info[:name].to_s.eql?("unknown")

    new_license = License.find_or_create_by(
      language: product[:language],
      prod_key: product[:prod_key],
      version:  product[:version],
      name:     license_info[:name]
    )

    new_license.update_attributes!({
      name: license_info[:name],
      url:  license_info[:url]
    })
    new_license
  end


  def self.read_project_file_from_url(file_url, token)
    response = HTTParty.get( file_url )
    return nil if response.nil? || response.code != 200

    content  = JSON.parse(response.body, symbolize_names: true)
    return nil if content.nil?

    content
  rescue => e
    logger.error "Error: cant parse JSON file for #{file_url}. #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.to_version_task(task, prod_key)
    task.prod_key = prod_key
    task 
  end


end 
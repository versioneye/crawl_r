class BowerStarter < Bower 

  
  def self.crawl(token, source_url = 'https://bower.herokuapp.com/packages', concurrent = false, skipKnownVersions = true )
    crawl_registered_list(token, source_url, concurrent, skipKnownVersions )
  end


  def self.crawl_registered_list(token, source_url, concurrent = false, skipKnownVersions = true)
    response = HTTParty.get( source_url )
    app_list = JSON.parse( response.body, symbolize_names: true )
    logger.info "#{app_list.count} packages found for #{source_url}"

    if app_list.nil? or app_list.empty?
      logger.error "Error: cant read list of registered bower packages from: `#{source_url}`"
      return nil
    end

    app_list.each_with_index do |app, i|
      logger.info "start - #{i} - #{app[:name]}"
      
      if app[:name].to_s.eql?('bower-everything') || app[:name].to_s.eql?('everything')
        logger.info "Skip bower-everything! Too many dependencies!"
        next 
      end
      
      if concurrent 
        BowerCrawlProducer.new("#{app[:name]}::#{app[:url]}")
      else 
        register_package app[:name], app[:url], token, skipKnownVersions 
      end
    end
  end


  def self.register_package name, url, token, skipKnownVersions = true
    repo_info = url_to_repo_info( url )
    return nil if repo_info.nil? || repo_info.empty?
  
    repo_info[:registry_name] = name
    task = to_existence_task(repo_info)
    resp = BowerSourceChecker.check_repo_existence task, token 
    return if resp == false 
    
    resp = BowerProjectsCrawler.process_project task, token, skipKnownVersions 
    return if resp == false 

    BowerVersionsCrawler.crawl_versions task, token, skipKnownVersions
  rescue => e 
    logger.error e.message 
    logger.error e.backtrace.join("\n")
    nil 
  end


end


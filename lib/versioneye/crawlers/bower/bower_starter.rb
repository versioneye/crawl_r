class BowerStarter < Bower 

  
  def self.crawl(source_url = 'https://bower.herokuapp.com/packages', concurrent = true)
    crawl_registered_list(source_url)
  end


  def self.crawl_registered_list(source_url)
    response = HTTParty.get( source_url )
    app_list = JSON.parse( response.body, symbolize_names: true )
    tasks    = 0

    if app_list.nil? or app_list.empty?
      logger.info "Error: cant read list of registered bower packages from: `#{source_url}`"
      return nil
    end

    app_list.each_with_index do |app, i|
      register_package app[:name], app[:url], tasks
    end
    
    # to_poison_pill(A_TASK_CHECK_EXISTENCE)
    logger.info "#-- Got #{tasks} registered libraries of Bower."
  end


  def self.register_package name, url, tasks = 0 
    repo_info = url_to_repo_info( url )
    
    if repo_info && !repo_info.empty?
      repo_info[:registry_name] = name
      task = to_existence_task(repo_info)
      task.update_attributes!({
        task_failed: false,
        re_crawl: true,
        url_exists: true, 
        weight: 20
      })
      tasks += 1
      return 
    end
    
    # save non-supported url for further analyse
    task = to_existence_task({
      name: "not_supported",
      owner: "bower",
      fullname: url,
      url: url, 
      re_crawl: false,
    })
    task.update_attributes!({task_failed: true, url_exists: false})
  end

end

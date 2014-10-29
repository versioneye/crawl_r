class NewBowerCrawler < Versioneye::Crawl


  A_BOWER_SOURCE = 'https://bower.herokuapp.com/packages'


  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower.log')
  end


  def self.crawl
    response = HTTParty.get( 'https://bower.herokuapp.com/packages' )
    app_list = JSON.parse( response.body, symbolize_names: true )
    p app_list.count
    app_list.each do |app|
      process_bower_package app
    end
    nil
  end


  def self.process_bower_package app
    reiz = User.find_by_username "reiz"
    token = reiz.github_token
    repo_info = url_to_repo_info app[:url]
    repo_response = Github.repo_info(repo_info[:full_name], token)
    branch = repo_response[:default_branch]

    repo_url  = "https://github.com/#{repo_info[:full_name]}"
    response  = HTTParty.get( repo_url )
    response_code = response.code.to_i
    if response_code != 200
      p " #{response_code} - does not exist - #{repo_url} - "
      return
    end

    repo_url  = "https://raw.githubusercontent.com/#{repo_info[:full_name]}/#{branch}/bower.json"
    response  = HTTParty.get( repo_url )
    response_code = response.code.to_i
    if response_code != 200
      p " #{response_code} - does not exist - #{repo_url} - "
      return
    end

    p " - exist - #{repo_url}"
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end


  private


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


end

class WpackagistCrawler < SatisCrawler

  def logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/wpackagist.log", 10).log
    end
    @@log
  end

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/wpackagist.log", 10).log
    end
    @@log
  end

  A_BASE_URL  = 'https://wpackagist.org'
  A_LINK_NAME = 'WordPress Packagist'


  def self.crawl packages = nil, early_exit = false
    provider_includes = fetch_provider_includes
    provider_includes.keys.each do |key|
      obj     = provider_includes[key]
      sha256  = obj['sha256']
      new_key = key.gsub("%hash%", sha256)
      process_provider new_key
    end
  end


  def self.fetch_provider_includes
    url = 'https://wpackagist.org/packages.json'
    response = HTTParty.get( url ).response
    body     = JSON.parse response.body
    body['provider-includes']
  rescue => e
    logger.error "ERROR in WpackagistCrawler.fetch_provider_includes() - #{e.message}"
    logger.error e.backtrace.join("\n")
  end


  def self.process_provider pkey
    url = "https://wpackagist.org/#{pkey}"
    logger.info "process_provider for #{url}"
    response = HTTParty.get( url ).response
    body     = JSON.parse response.body
    keys     = body['providers'].keys
    logger.info "Found #{keys.count} provider keys for #{url}"
    keys.each do |key|
      obj = body['providers'][key]
      sha = obj['sha256']
      process_packages key, sha, pkey
    end
  rescue => e
    logger.error "ERROR in WpackagistCrawler.process_provider(#{pkey}) - #{e.message}"
    logger.error e.backtrace.join("\n")
  end


  def self.process_packages key, sha, pkey = nil
    url = "https://wpackagist.org/p/#{key}$#{sha}.json"
    response = HTTParty.get( url ).response
    body     = JSON.parse response.body
    crawler  = WpackagistCrawler.new A_BASE_URL, A_LINK_NAME
    packages = body['packages']
    logger.info "Found #{packages.count} packages for #{url}"
    body['packages'].each do |package|
      crawler.crawle_package package
    end
  rescue => e
    logger.error "ERROR in WpackagistCrawler.process_packages(#{key}, #{sha}, #{pkey}) - #{e.message}"
    logger.error e.backtrace.join("\n")
  end


end

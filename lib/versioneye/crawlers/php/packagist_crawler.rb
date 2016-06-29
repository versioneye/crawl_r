class PackagistCrawler < Versioneye::Crawl


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/packagist.log", 10).log
    end
    @@log
  end


  def self.crawl serial = false, packages = nil
    start_time = Time.now
    self.logger.info(" *** start crawl (serial = #{serial}) at #{start_time} *** ")
    packages = PackagistCrawler.get_first_level_list if packages.nil?
    self.logger.info(" *** found #{packages.count} packages to crawl *** ")
    packages.each do |name|
      if serial == true
        PackagistCrawler.crawle_package( name )
      else
        PackagistCrawlProducer.new( name ) # Let the rabbit do the work!
      end
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def self.get_first_level_list
    self.logger.info(" *** get_first_level_list *** ")
    body = JSON.parse HTTParty.get('https://packagist.org/packages/list.json' ).response.body
    body['packageNames']
  end


  def self.crawle_package name
    self.logger.info "crawl #{name}"
    return nil if name.to_s.empty?

    resource     = "https://packagist.org/packages/#{name}.json"
    pack         = JSON.parse HTTParty.get( resource ).response.body
    package      = pack['package']
    package_name = package['name']
    versions     = package['versions']
    return nil if versions.nil? || versions.empty?

    product = PackagistCrawler.init_product package_name
    PackagistCrawler.update_product product, package
    PackagistCrawler.update_packagist_link product, package_name

    versions.each do |version|
      self.process_version version, product
    end
    ProductService.update_version_data( product )
    PhpeyeCrawler.crawle_package product
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.process_version version, product
    version_number = String.new(version[0])
    version_obj = version[1]

    version_number.gsub!(/^v/, '') if version_number.to_s.match(/^v[0-9]+\..*/)
    db_version = product.version_by_number version_number
    if db_version.nil?
      if !version_number.eql?('dev-master') && has_tag_variants?(product, version_number, version_obj) == false
        return nil
      end

      PackagistCrawler.create_new_version( product, version_number, version_obj )
    end

    if version_number.match(/\Adev\-/)
      Dependency.remove_dependencies Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_dependencies product, version_number, version_obj
      Versionarchive.remove_archives Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_archive product, version_number, version_obj
    end
  end


  def self.init_product name
    product = Product.find_by_lang_key( Product::A_LANGUAGE_PHP, name.downcase )
    return product if product

    self.logger.info " -- New PHP Package - #{name}"
    Product.new({:reindex => true})
  end


  def self.update_product product, package
    name                  = package['name']
    product.prod_key      = name.downcase
    product.name          = name
    product.name_downcase = name.downcase
    product.description   = package['description']
    product.prod_type     = Project::A_TYPE_COMPOSER
    product.language      = Product::A_LANGUAGE_PHP
    product.save
  end


  def self.update_packagist_link product, package_name
    packagist_page = "https://packagist.org/packages/#{package_name}"
    Versionlink.create_project_link( Product::A_LANGUAGE_PHP, product.prod_key, packagist_page, 'Packagist Page' )
  end


  def self.create_new_version product, version_number, version_obj
    version_db                 = Version.new({version: version_number})
    version_db.released_string = version_obj['time']
    version_db.released_at     = date_from version_obj['time']
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- PHP Package: #{product.prod_key} -- with new version: #{version_number}"

    CrawlerUtils.create_newest product, version_number, logger
    CrawlerUtils.create_notifications product, version_number, logger

    create_links product, version_number, version_obj

    ComposerUtils.create_license( product, version_number, version_obj )
    ComposerUtils.create_developers version_obj['authors'], product, version_number
    ComposerUtils.create_archive product, version_number, version_obj
    ComposerUtils.create_dependencies product, version_number, version_obj
    ComposerUtils.create_keywords product, version_obj
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.create_links product, version_number, version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['homepage'], "Homepage"

    source = version_obj['source']['url']
    source = source.gsub(".git", "") if source.match(/\.git$/)
    Versionlink.create_versionlink product.language, product.prod_key, version_number, source, "Source"
  rescue => e
    self.logger.error "ERROR in create_links Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.has_tag_variants? product, version_number, version_obj
    tag = has_tag? product, version_number, version_obj
    return true if tag == true

    if version_number.to_s.match(/^v/)
      version_number.gsub!(/^v/, '')
    else
      version_number = "v#{version_number}"
    end
    tag = has_tag? product, version_number, version_obj
    return true if tag == true

    if version_number.match(/\.0\.0$/)
      version_number.gsub!(/\.0\.0$/, "")
      tag = has_tag?(product, version_number, version_obj)
      return true if tag == true
    end

    if version_number.match(/\.0$/)
      version_number.gsub!(/\.0$/, "")
      tag = has_tag? product, version_number, version_obj
      return true if tag == true
    end

    return tag
  end


  def self.has_tag? product, version_number, version_obj
    source = version_obj['source']['url']
    source = source.gsub(".git", "") if source.match(/\.git$/)
    return true if !source.match(/github\.com/)

    raw_url = "#{source}/releases/tag/#{version_number}"

    resp = HttpService.fetch_response raw_url
    return false if resp.nil?
    return true  if resp.code.to_i == 200
    return false
  rescue => e
    self.logger.error e.message
    self.logger.error e.backtrace.join("\n")
    false
  end


  def self.is_branch? product, version_string
    links = product.http_version_links_combined
    return false if links.nil? || links.empty?

    github_link = nil
    links.each do |link|
      if link.link.match(/http.+github\.com\/\S*\/\S*[\/]*$/i)
        github_link = link
        break
      end
    end
    return false if github_link.nil?

    raw_url = "https://github.com/#{product.prod_key}"
    resp = HttpService.fetch_response raw_url
    if resp.code.to_i == 200
      raw_url = "https://github.com/#{product.prod_key}/releases/tag/#{version_string}"
    else
      uri = github_link.link.gsub(/http.+github\.com\//i, "")
      uri_sp = uri.split("/")
      raw_url = "https://github.com/#{uri_sp[0]}/#{uri_sp[1]}/releases/tag/#{version_string}"
    end

    resp = HttpService.fetch_response raw_url
    return false if resp.code.to_i == 200
    return false if resp.code.to_i == 301

    return true
  end


  def self.date_from released_string
    DateTime.parse(released_string)
  rescue => e
    logger.error e.message
    nil
  end

end

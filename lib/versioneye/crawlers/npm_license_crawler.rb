class NpmLicenseCrawler < NpmCrawler


  def self.crawl
    crawl = crawle_object
    packages = get_first_level_list
    packages.each do |name|
      crawle_package name, crawl
    end
    crawl.duration = Time.now - crawl.created_at
    crawl.save
    self.logger.info(" *** This crawle took #{crawl.duration} *** ")
  end


  def self.crawle_package name
    return nil if name.to_s.empty?

    resource     = "http://packagist.org/packages/#{name}.json"
    pack         = JSON.parse HTTParty.get( resource ).response.body
    package      = pack['package']
    package_name = package['name'].to_s.downcase
    versions     = package['versions']
    return nil if package_name.to_s.empty?
    return nil if versions.nil? || versions.empty?

    product = Product.find_by_lang_key( Product::A_LANGUAGE_PHP, package_name.downcase )
    return nil if product.nil?

    versions.each do |version|
      self.process_version version, product
    end
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.crawle_package name, crawl
    self.logger.info "crawl #{name}"
    prod_json = JSON.parse HTTParty.get("http://registry.npmjs.org/#{name}").response.body
    versions  = prod_json['versions']
    return nil if versions.nil? || versions.empty?

    prod_key  = prod_json['_id'].to_s.downcase

    product = init_product prod_key
    update_product product, prod_json

    versions.each do |version|
      version_number = CrawlerUtils.remove_version_prefix String.new(version[0])
      version_obj    = version[1]

      create_license( product, version_number, version_obj )
    end
  rescue => e
    self.logger.error "ERROR in crawle_package Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    store_error crawl, e.message, e.backtrace, name
  end


end

class NpmLicenseCrawler < NpmCrawler


  def self.crawl
    packages = get_first_level_list
    packages.each do |package|
      name = package['key'] if package.is_a? Hash 
      name = package if !package.is_a? Hash 
      next if name.match(/\A\@\w*\/\w*/)
      
      crawle_package name
    end
  end


  def self.crawle_package name
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
  end


end


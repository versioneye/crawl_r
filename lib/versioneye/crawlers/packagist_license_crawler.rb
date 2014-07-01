class PackagistLicenseCrawler < PackagistCrawler


  def self.crawl
    start_time = Time.now
    packages = self.get_first_level_list
    packages.each do |name|
      self.crawle_package name
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
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
    self.logger.error e.backtrace.join('\n')
  end


  def self.process_version version, product
    version_number = String.new(version[0])
    version_obj = version[1]
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end

    ComposerUtils.create_license( product, version_number, version_obj )
  end


end

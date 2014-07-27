class SatisCrawler < Versioneye::Crawl

  # Satis Crawler
  # Find more infos to Satis here:
  # https://getcomposer.org/doc/articles/handling-private-packages-with-satis.md

  def self.logger
    ActiveSupport::BufferedLogger.new('log/satis.log')
  end

  @@base_url = 'http://composer.tiki.org/'
  @@link_name = 'Tiki Page'


  def self.crawle_package package
    return nil if package.nil? || package.empty?

    versions = package.last
    return nil if versions.nil? || versions.empty?

    versions.each do |version_obj|
      version_object = version_obj.last
      self.process_version version_object
    end
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.process_version version_object
    name        = version_object['name']
    description = version_object['description']
    product     = find_or_create_product name, description

    version_number = version_object['version']
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end

    db_version = product.version_by_number version_number
    if db_version.nil?
      create_new_version( product, version_number, version_object )
      return nil
    end
    if version_number.match(/\Adev\-/)
      Dependency.remove_dependencies Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_dependencies product, version_number, version_object
      Versionarchive.remove_archives Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_archive     product, version_number, version_object
    end
  end


  def self.find_or_create_product name, description = nil
    return nil if name.to_s.empty?

    prod_key = name.downcase
    product  = Product.find_or_create_by( prod_key: prod_key, language: Product::A_LANGUAGE_PHP )
    product.reindex       = true
    product.name          = name
    product.name_downcase = name.downcase
    product.description   = description
    product.prod_type     = Project::A_TYPE_COMPOSER
    if !includes_repo? product, @@base_url
      repository = Repository.new({:src => @@base_url, :repotype => Project::A_TYPE_COMPOSER })
      product.repositories.push repository
    end
    product.save
    url = homepage_url( product )
    Versionlink.create_project_link( Product::A_LANGUAGE_PHP, product.prod_key, url, @@link_name )
    product
  end


  def self.create_new_version product, version_number, version_obj
    version_db                 = Version.new({version: version_number})
    if version_obj['time']
      version_db.released_string = version_obj['time']
      version_db.released_at     = DateTime.parse(version_obj['time'])
    end
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
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  private


    def self.includes_repo? product, src
      return false if product.repositories.nil? || product.repositories.empty?
      product.repositories.each do |repo|
        return true if repo.src.eql?( src )
      end
      false
    end


    def self.create_links product, version_number, version_obj
      Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['homepage'], "Homepage"
      return nil if version_obj['support'].to_s.empty?

      if version_obj['support']['issues']
        Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['support']['issues'], "Issues"
      end
      if version_obj['support']['source']
        Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['support']['source'], "Source"
      end
    rescue => e
      self.logger.error "ERROR in create_links Message: #{e.message}"
      self.logger.error e.backtrace.join("\n")
    end


    def self.homepage_url product
      @@base_url
    end


end

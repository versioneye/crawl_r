class NpmCrawler < Versioneye::Crawl


  A_NPM_REGISTRY_INDEX = 'https://skimdb.npmjs.com/registry/_all_docs'


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/npm.log", 10).log
    end
    @@log
  end


  def self.crawl serial = false, packages = nil
    packages = get_first_level_list if packages.nil?
    packages.each do |package|
      name = package['key'] if package.is_a? Hash
      name = package if !package.is_a? Hash
      next if name.match(/\A\@\w*\/\w*/)

      if serial == true
        crawle_package name
      else
        NpmCrawlProducer.new( name ) # Let the rabbit do the work!
      end
    end
  end


  def self.get_first_level_list
    packages = get_first_level_list_from_registry
    if packages.nil? || packages.empty? || packages.count < 50
      known_packages  = get_known_packages
      newest_packages = get_first_level_list_from_html
      packages        = (known_packages + newest_packages).uniq
    end
    packages
  end


  def self.get_first_level_list_from_registry
    self.logger.info 'Start fetching first level list'
    packages = JSON.parse HTTParty.get( A_NPM_REGISTRY_INDEX ).response.body
    self.logger.info ' -- fetched NPM registry index.'
    packages['rows']
  rescue => e
    self.logger.error "ERROR in get_first_level_list: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    nil
  end


  def self.get_first_level_list_from_html
    self.logger.info 'Start fetching first level list from HTML'
    packages = Array.new
    20.times.each do |page|
      packages.concat( fetch_names_from( page ) )
    end
    packages
  end


  def self.fetch_names_from page
    packages = Array.new
    doc = Nokogiri::HTML( open("https://npmjs.org/browse/updated/#{page}/") )
    doc.xpath("//div[@id=\"package\"]/div[@class=\"row\"]/p/a").each do |link|
      packages << link.content
    end
    packages
  rescue => e
    self.logger.error "ERROR in fetch_names_from page: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    Array.new
  end


  def self.get_known_packages
    self.logger.info 'NpmCrawler.get_known_packages'
    packages = Array.new
    products = Product.where(:language => Product::A_LANGUAGE_NODEJS)
    products.each do |product|
      packages << product.prod_key
    end
    packages
  end


  def self.crawle_package name
    self.logger.info "NpmCrawler.crawl #{name}"
    prod_json = JSON.parse HTTParty.get("http://registry.npmjs.org/#{name}").response.body
    versions  = prod_json['versions']
    return nil if versions.nil? || versions.empty?

    prod_key  = prod_json['_id'].to_s
    time      = prod_json['time']

    product = init_product prod_key
    update_product product, prod_json

    npm_page = "https://npmjs.org/package/#{prod_key}"
    Versionlink.create_project_link( Product::A_LANGUAGE_NODEJS, product.prod_key, npm_page, 'NPM Page' )

    versions.each do |version|
      version_number = CrawlerUtils.remove_version_prefix String.new(version[0])
      version_obj    = version[1]
      if version_obj.nil?
        logger.error "version_obj is nil for #{name}:#{version_number}"
        next
      end

      db_version     = product.version_by_number version_number
      next if db_version

      create_new_version product, version_number, version_obj, time
    end
    ProductService.update_version_data( product )
  rescue => e
    self.logger.error "ERROR in crawle_package Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.create_new_version product, version_number, version_obj, time
    version_db = Version.new({:version => version_number})
    parse_release_date( version_db, time )
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- New NPM Package: #{product.prod_key} : #{version_number}"

    CrawlerUtils.create_newest( product, version_number, logger )
    CrawlerUtils.create_notifications( product, version_number, logger )

    create_dependencies product, version_number, version_obj
    create_download     product, version_number, version_obj
    create_versionlinks product, version_number, version_obj
    create_license      product, version_number, version_obj
    create_author       product, version_number, version_obj['author']
    create_contributors product, version_number, version_obj['contributors']
    create_maintainers  product, version_number, version_obj['maintainers']
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.init_product prod_key
    product = Product.where( :language => Product::A_LANGUAGE_NODEJS, :prod_key => prod_key ).first
    return product if product

    Product.new({:prod_key => prod_key, :reindex => true})
  end


  def self.update_product product, package
    name                  = package['name']
    product.prod_key      = package['_id'].to_s
    product.prod_key_dc   = package['_id'].to_s.downcase
    product.name          = name
    product.name_downcase = name.downcase
    product.description   = package['description']
    product.tags          = package['keywords']
    product.prod_type     = Project::A_TYPE_NPM
    product.language      = Product::A_LANGUAGE_NODEJS
    product.save
  end


  def self.create_author product, version_number, author, contributor = false
    return nil if author.nil? || author.empty?

    author_name     = author['name'].to_s.gsub("https://github.com/", "")
    author_email    = author['email']
    author_homepage = author['homepage']
    author_role     = author['role']
    devs = Developer.find_by Product::A_LANGUAGE_NODEJS, product.prod_key, version_number, author_name
    return nil if devs && !devs.empty?

    developer = Developer.new({:language => Product::A_LANGUAGE_NODEJS,
      :prod_key => product.prod_key, :version => version_number,
      :name => author_name, :email => author_email,
      :homepage => author_homepage, :role => author_role,
      :contributor => contributor})
    developer.save
  end


  def self.create_contributors product, version_number, contributors
    return nil if contributors.nil? || contributors.empty?

    contributors.each do |contributor|
      create_author product, version_number, contributor, true
    end
  end


  def self.create_maintainers product, version_number, maintainers
    return nil if maintainers.nil? || maintainers.empty?

    maintainers.each do |author|
      create_author product, version_number, author
    end
  end


  def self.create_download product, version_number, version_obj
    dist = version_obj['dist']
    return nil if dist.nil? || dist.empty?
    dist_url  = dist['tarball']
    dist_name = dist_url.split("/").last
    archive = Versionarchive.new({:language => Product::A_LANGUAGE_NODEJS, :prod_key => product.prod_key,
      :version_id => version_number, :name => dist_name, :link => dist_url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end


  def self.create_license( product, version_number, version_obj )
    check_single_license product, version_number, version_obj
    check_licenses product, version_number, version_obj
    check_license_on_github( product, version_number )
  rescue => e
    self.logger.error "ERROR in create_license Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.check_license_on_github( product, version_number )
    product.version = version_number
    return if !product.licenses.empty?

    repo_names = github_repo_names product
    repo_names.each do |repo|
      logger.info "crawl license info from GitHub master branch for repo #{repo}"
      LicenseCrawler.process_github( repo, "master", product, version_number )
    end
  end


  def self.check_single_license( product, version_number, version_obj )
    license_value = version_obj['license']
    return nil if license_value.to_s.empty?

    if license_value.is_a? String
      create_single_license( product, version_number, license_value )
    elsif license_value.is_a? Hash
      license_type = license_value["type"]
      license_url  = license_value["url"]
      create_single_license( product, version_number, license_type, license_url )
    elsif license_value.is_a? Array
      create_licenses( product, version_number, license_value )
    end
  end


  def self.check_licenses( product, version_number, version_obj )
    licenses = version_obj['licenses']
    return nil if licenses.nil? || licenses.empty?

    if licenses.is_a?( String )
      create_single_license( product, version_number, licenses )
    elsif licenses.is_a?( Hash )
      license_name = licenses["type"]
      license_url  = licenses["url"]
      create_single_license( product, version_number, license_name, license_url )
    elsif licenses.is_a?( Array )
      create_licenses( product, version_number, licenses )
    end
  end


  def self.create_licenses( product, version_number, licenses )
    licenses.each do |licence|
      if licence.is_a?(String)
        create_single_license( product, version_number, licence )
      else
        license_name = licence["type"]
        license_url  = licence["url"]
        create_single_license( product, version_number, license_name, license_url )
      end
    end
  end


  def self.create_single_license( product, version_number, license_name, license_url = nil )
    license = License.find_or_create( product.language, product.prod_key, version_number, license_name, license_url )
    self.logger.info " -- find_or_create license - #{license.to_s}"
  end


  def self.create_dependencies product, version_number, version_obj
    dependencies = version_obj['dependencies']
    create_dependency dependencies, product, version_number, Dependency::A_SCOPE_COMPILE

    devDependencies = version_obj['devDependencies']
    create_dependency devDependencies, product, version_number, Dependency::A_SCOPE_DEVELOPMENT

    bundledDependencies = version_obj['bundledDependencies']
    create_dependency bundledDependencies, product, version_number, Dependency::A_SCOPE_BUNDLED

    optionalDependencies = version_obj['optionalDependencies']
    create_dependency optionalDependencies, product, version_number, Dependency::A_SCOPE_OPTIONAL
  end


  def self.create_versionlinks product, version_number, version_obj
    bugs_link = bugs_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, bugs_link, 'Bugs'
    repo_link = repository_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, repo_link, 'Repository'
    homepage_link = homepage_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, homepage_link, 'Homepage'
  end


  def self.create_dependency dependencies, product, version_number, scope
    return nil if dependencies.nil? || dependencies.empty?
    dependencies.each do |dep|
      require_name = dep[0]
      require_version = dep[1]
      if require_version.strip.eql?("self.version")
        require_version = version_number
      end
      dep_prod_key = require_name
      dep = Dependency.find_by( Product::A_LANGUAGE_NODEJS, product.prod_key, version_number, require_name, require_version, dep_prod_key )
      next if dep

      dependency = Dependency.new({:name => require_name, :version => require_version,
        :dep_prod_key => dep_prod_key, :prod_key => product.prod_key,
        :prod_version => version_number, :scope => scope, :prod_type => Project::A_TYPE_NPM,
        :language => Product::A_LANGUAGE_NODEJS })
      dependency.save
      dependency.update_known
      self.logger.info " ---- Create new dependency: #{dependency}"
    end
  end


  def self.bugs_for version_obj
    version_obj['bugs']['web']
  rescue => e
    p e
    nil
  end


  def self.repository_for version_obj
    version_obj['repository']['url']
  rescue => e
    p e
    nil
  end


  def self.homepage_for version_obj
    hp = version_obj['homepage']
    if hp.is_a? Array
      return hp.first
    end
    hp
  rescue => e
    logger.error "Error in homepage_for #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.parse_release_date version_db, time
    version_db.released_string = time[ version_db.to_s ]
    version_db.released_at     = DateTime.parse( version_db.released_string )
  rescue => e
    logger.error "Error in parse_release_date #{e.message}"
    logger.error e.backtrace.join("\n")
  end


  private


    def self.github_repo_names product
      matcher = "github.com\/([\w\.\-]+\/[\w\.\-]+)"
      names = []
      product.http_version_links_combined.each do |link|
        matches = link.link.match( /github.com\/([\w\.\-]+\/[\w\.\-]+)/ )
        names << matches[1] if matches && matches[1]
      end
      names
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      []
    end


end

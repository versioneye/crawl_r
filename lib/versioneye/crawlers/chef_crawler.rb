class ChefCrawler < Versioneye::Crawl

# https://supermarket.chef.io/api/v1/cookbooks
# https://supermarket.chef.io/api/v1/cookbooks?start=10
# https://supermarket.chef.io/api/v1/cookbooks/bash-cve-2014-6271
# https://supermarket.chef.io/api/v1/cookbooks/bash-cve-2014-6271/versions/0.1.1

  A_CHEF_REGISTRY_INDEX = 'https://supermarket.chef.io/api/v1/cookbooks'

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/chef.log", 10).log
    end
    @@log
  end


  def self.crawl
    start = 0
    while 1 == 1
      url = "#{A_CHEF_REGISTRY_INDEX}?start=#{start}"
      resp = JSON.parse HTTParty.get( url ).response.body
      break if resp['items'].empty?

      resp['items'].each do |item|
        crawl_package item['cookbook_name']
      end
      start += 10
      logger.info "API start point: #{start}"
    end
  end


  def self.crawl_package name
    logger.info "crawl: #{name}"
    url = "#{A_CHEF_REGISTRY_INDEX}/#{name}"
    package = JSON.parse HTTParty.get( url ).response.body
    product = find_and_update_product_by name, package

    Versionlink.create_project_link product.language, product.prod_key, package['external_url'], 'URL'
    Versionlink.create_project_link product.language, product.prod_key, package['source_url'], 'Source'
    Versionlink.create_project_link product.language, product.prod_key, package['issues_url'], 'Issues'

    if !package['maintainer'].to_s.empty?
      Developer.find_or_create_by(
        :language => product.language,
        :prod_key => product.prod_key,
        :developer => package['maintainer'],
        :name => package['maintainer'])
    end

    package['versions'].each do |version_link|
      handle_version product, version_link
    end

    product.save
  rescue => e
    self.logger.error "ERROR in crawl_package: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.handle_version product, version_link
    package = JSON.parse HTTParty.get( version_link ).response.body
    return if product.version_by_number(package['version'])

    product.add_version package['version']
    product.version = package['version'] if product.version.to_s.empty? || product.version.eql?('0.0.0+NA')
    product.save

    CrawlerUtils.create_newest( product, package['version'], self.logger )
    CrawlerUtils.create_notifications( product, package['version'], self.logger )

    License.find_or_create product.language, product.prod_key, package['version'], package['license']

    link = "https://supermarket.chef.io/cookbooks/#{product.name}"
    Versionlink.create_project_link product.language, product.prod_key, link, 'Cookbook'

    Versionarchive.find_or_create_by(
      :language => product.language,
      :prod_key => product.prod_key,
      :version_id => package['version'],
      :link => package['file'],
      :name => 'download' )

    return if package['dependencies'].to_s.empty?

    package['dependencies'].keys.each do |key|
      dependency = Dependency.find_or_create_by(
        :prod_type => Project::A_TYPE_CHEF,
        :language => product.language,
        :prod_key => product.prod_key,
        :prod_version => package['version'],
        :dep_prod_key => key.downcase,
        :version => package['dependencies'][key],
        :name => key )
      dependency.save
      dependency.update_known
    end
  rescue => e
    self.logger.error "ERROR in handle_version: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  private


    def self.find_and_update_product_by name, package
      product = Product.find_or_create_by(:language => Product::A_LANGUAGE_CHEF, :prod_key => name.downcase )
      product.prod_type = Project::A_TYPE_CHEF
      product.name = name
      product.name_downcase = name.downcase
      product.description = package['description']
      product.downloads   = package['metrics']['downloads']['total']
      product.add_tag( package['category'] )
      product
    end

end
